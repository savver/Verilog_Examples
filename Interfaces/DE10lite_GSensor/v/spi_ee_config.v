module spi_ee_config (			
								iRSTN,															
								iSPI_CLK,								
								iSPI_CLK_OUT,								
								iG_INT2,
								oDATA_L,
								oDATA_H,
								SPI_SDIO,
								oSPI_CSN,
								oSPI_CLK);

//подключаем файл констант - адреса регистров в акселе			
`include "spi_param.h"
	
//=======================================================
//  PORT declarations
//=======================================================
//	Host Side							
input					      iRSTN;
input					      iSPI_CLK, iSPI_CLK_OUT;
input					      iG_INT2;
output reg [SO_DataL:0] oDATA_L;
output reg [SO_DataL:0] oDATA_H;
//	SPI Side           
inout					      SPI_SDIO;
output					   oSPI_CSN;
output					   oSPI_CLK;       
                               
//=======================================================
//  REG/WIRE declarations
//=======================================================
reg	[3:0] 	      ini_index;  //индекс из 'таблицы настроечных регистров'
reg	[SI_DataL-2:0] write_data; //[15-2:0] => [13:0], { 6'REG_ADDR, 8'REG_DATA }
reg	[SI_DataL:0]	p2s_data;   //[15:0] - все 16 бит SPI транзакции
                                 //{ 1'RW, 1'MB, 6'REG_ADDR, 8'REG_DATA }
reg                  spi_go;
wire                 spi_end;

wire	[SO_DataL:0]	s2p_data; 
reg   [SO_DataL:0]	low_byte_data;

reg		       		spi_state;

reg                  high_byte; // indicate to read the high or low byte
reg                  read_back; // indicate to read back data 
reg                  clear_status, read_ready;

//сдвиговый регистр, по сути задержка clear_status на 4 такта
reg   [3:0]          clear_status_d;

reg                  high_byte_d, read_back_d;

reg	[IDLE_MSB:0]   read_idle_count; // reducing the reading rate, [14:0]

//=======================================================
//  Sub-module
//=======================================================
spi_controller 	u_spi_controller 
(		
	.iRSTN			(iRSTN),
	.iSPI_CLK		(iSPI_CLK),
	.iSPI_CLK_OUT	(iSPI_CLK_OUT), //2MHz phase shift 
	.iP2S_DATA		(p2s_data),     //передаваемая транзакция { 1'RW, 1'MB, 6'REG_ADDR, 8'REG_DATA }
	.iSPI_GO			(spi_go),       //сигнал, что надо запустить SPI транзакцию
	.oSPI_END		(spi_end),	    //индикатор, что SPI транзакция завершена	
	.oS2P_DATA		(s2p_data),			
	.SPI_SDIO		(SPI_SDIO),
	.oSPI_CSN		(oSPI_CSN),							
	.oSPI_CLK		(oSPI_CLK)
);
							
//=======================================================
//  Structural coding
//=======================================================

//данные, которые шлем по 3-wire SPI, { 6'REG_ADDR, 8'REG_DATA }
// case у нас 0..9 + default => 11 регистров, как и в INI_NUMBER
// Initial Setting Table
always @ (ini_index)
	case (ini_index)
    0      : write_data = {THRESH_ACT,   8'h20};
    1      : write_data = {THRESH_INACT, 8'h03};
    2      : write_data = {TIME_INACT,   8'h01};
    3      : write_data = {ACT_INACT_CTL,8'h7f};
    4      : write_data = {THRESH_FF,    8'h09};
    5      : write_data = {TIME_FF,      8'h46};
    6      : write_data = {BW_RATE,      8'h09}; // output data rate : 50 Hz
    7      : write_data = {INT_ENABLE,	  8'h10};	
    8      : write_data = {INT_MAP,		  8'h10};
    9      : write_data = {DATA_FORMAT,  8'h40};
	 default: write_data = {POWER_CONTROL,8'h08};
	endcase

//асинхронный сброс
always@(posedge iSPI_CLK or negedge iRSTN)
	if(!iRSTN)
	begin
		ini_index	 <= 4'b0; //индекс в 'таблице настроечных регистров'
		spi_go		 <= 1'b0;
		spi_state	 <= IDLE;
		read_idle_count <= 0; // read mode only
		high_byte    <= 1'b0;  // read mode only
		read_back    <= 1'b0;  // read mode only
      clear_status <= 1'b0;
	end
	// по очереди перебираем регистры из таблицы настроеч регистров, и собираем SPI транзакцию 
	// для отправки. Собираем { 1'RW, 1'MB, 6'REG_ADDR, 8'REG_DATA } в p2s_data и запускаем
	// SPI_FSM. После окончания транзакции (spi_end) увеличиваем индекс в таблице регистров
	// initial setting (write mode)
	else if(ini_index < INI_NUMBER) 
		case(spi_state)
			IDLE : begin
					p2s_data    <= {WRITE_MODE, write_data}; 
					spi_go		<= 1'b1;
					spi_state	<= TRANSFER;
			end
			TRANSFER : begin
					if (spi_end)
					begin
		            ini_index	<= ini_index + 4'b1;
						spi_go		<= 1'b0;
						spi_state	<= IDLE;							
					end
			end
		endcase
  //high_byte - это такой бинар мигающий флаг, мы читаем или X_HB или X_LB
  //т.е. каждую новую транзакцию мы выбираем H или L читать
  //read_ready - запускает чтение X_LB, а потом будет !high_byte, 
  //и следующим после X_LB будет чтение X_HB
  //если нет прерываний, то рано или поздно read_idle_count[IDLE_MSB] возникнет
  //он запустит чтение регистра INT_SOURCE
  //защелкиваем read_back - если запустили чтение X_LB или X_HB
  //защелкиваем clear_status - если запустили чтение INT_SOURCE
  // read data and clear interrupt (read mode)
  else 
		case(spi_state)
			IDLE : begin
				  read_idle_count <= read_idle_count + 1;
				
				  if (high_byte) // multiple-byte read
				  begin
					  p2s_data[15:8] <= {READ_MODE, X_HB};						
					  read_back      <= 1'b1;
					end
					
				  else if (read_ready)
				  begin
					  p2s_data[15:8] <= {READ_MODE, X_LB};						
					  read_back      <= 1'b1;
					end
					
				  else if (!clear_status_d[3]&&iG_INT2 || read_idle_count[IDLE_MSB])
				  begin
					  p2s_data[15:8] <= {READ_MODE, INT_SOURCE};
					  clear_status   <= 1'b1;
              end
				 //---------------------------------------
				 //если есть хотя бы одно из условий для новой SPI транзакции
				 if (high_byte || read_ready || read_idle_count[IDLE_MSB] || !clear_status_d[3]&&iG_INT2)
					begin
						spi_go		<= 1'b1;
						spi_state	<= TRANSFER;
					end
				 //---------------------------------------
				 if (read_back_d) // update the read back data
					begin
						if (high_byte_d)
						begin
						  oDATA_H <= s2p_data;	
						  oDATA_L <= low_byte_data;			  		
						end
						else
							low_byte_data <= s2p_data;
					end
		      end
				
			//======================================
			TRANSFER : begin
					if (spi_end)
					begin
						spi_go		<= 1'b0;
						spi_state	<= IDLE;
						
						//это конец SPI транзакции, у нас чтение одного из 3х регистров
						//если было бы чтение X_LB, X_HB, то был бы защелкнут read_back
						//а если он не защелкнут, значит было чтение INT_SOURCE
						if (read_back)
						begin
						  read_back     <= 1'b0;
					     high_byte     <= !high_byte;  // X_LB, X_HB, X_LB...
					     read_ready    <= 1'b0;					
					   end
						//если установлен 6й бит в регистре INT_SOURCE, значит
						//произошло событие SINGLE_TAP. Если оно произошло, надо считать
						//значение ускорения, для этого ставим флаг read_ready, который
						//запустит чтение X_LB, после чего по флагу high_byte запустится
						//чтение X_HB
					   else
					   begin
                    clear_status    <= 1'b0;
                    read_ready      <= s2p_data[6];					  	
					     read_idle_count <= 0;
                  end
				  end
			end
		endcase
 
always@(posedge iSPI_CLK or negedge iRSTN)
	if(!iRSTN)
	begin
		high_byte_d <= 1'b0;
		read_back_d <= 1'b0;
		clear_status_d <= 4'b0;
	end
	else
	begin
		high_byte_d <= high_byte;
		read_back_d <= read_back;
		//задержка clear_status на N тактов
		clear_status_d <= {clear_status_d[2:0], clear_status};
	end

endmodule					