module spi_controller (		
							iRSTN,
							iSPI_CLK,      //2MHz
							iSPI_CLK_OUT,  //2MHz phase shift
							iP2S_DATA,     //передаваемая транзакция { 1'RW, 1'MB, 6'REG_ADDR, 8'REG_DATA }
							iSPI_GO,       //сигнал, что надо запустить SPI транзакцию
							oSPI_END,		//индикатор, что SPI транзакция завершена				
							oS2P_DATA,							
							SPI_SDIO,
							oSPI_CSN,							
							oSPI_CLK);
	
`include "spi_param.h"	

//=======================================================
//  PORT declarations
//=======================================================
//	Host Side
input				           iRSTN;
input				           iSPI_CLK;
input				           iSPI_CLK_OUT;
input	      [SI_DataL:0]  iP2S_DATA;      //[15:0]
input	      			     iSPI_GO;
output	  			        oSPI_END;
output	reg [SO_DataL:0] oS2P_DATA;      //[7:0]
//	SPI Side              
inout				           SPI_SDIO;
output	   			     oSPI_CSN;
output				        oSPI_CLK;

//=======================================================
//  REG/WIRE declarations
//=======================================================
wire          read_mode, write_address;
reg           spi_count_en;
reg  	[3:0]	  spi_count;   //счетчик бит в транзакции,
                           //считает с 15 до 0, т.к. передача старшим битом вперед

//=======================================================
//  Structural coding
//=======================================================
assign read_mode = iP2S_DATA[SI_DataL];  //[15], бит RW

//передаем 16 бит, [15:0], { 1'RW, 1'MB, 6'REG_ADDR, 8'REG_DATA }
//даже если транзакция чтения, то все равно сначала надо первые 8 бит передать в чип
//т.е. биты [15:8], когда счетчик spi_count = 15,14..8, у него бит [3] всегда в '1'
assign write_address = spi_count[3];

//oSPI_END - индикатор, что все 16 бит переданы/приняты, и счетчик бит сейчас стал == 0
assign oSPI_END = ~|spi_count;       // '1' если все биты равны 0
                                     // spi_count устанавливается в 15 в начале транзакции
												 // и считает вниз до 0
assign oSPI_CSN = ~iSPI_GO;          

//если нет транзакции, то неактивный уровень линии CLK '1'
//выходной клок даем "задержанным" на фазовый сдвиг относительно сигнала тактирования
//синхр логики этого блока, чтобы данные успели выставиться на линии
assign oSPI_CLK = spi_count_en ? iSPI_CLK_OUT : 1'b1;

//если нет транзакции (en=0), то на линии HiZ
//если Write транзакция (read=0), то выставляем биты из iP2S_DATA[spi_count]
//если Read транзакция (read=1), но идет передача адресных + сервисных битов, 
//то выставляем биты из iP2S_DATA[spi_count]
assign SPI_SDIO = spi_count_en && (!read_mode || write_address) ? iP2S_DATA[spi_count] : 1'bz;

always @ (posedge iSPI_CLK or negedge iRSTN) 
	if (!iRSTN)
	begin
		spi_count_en <= 1'b0;
		spi_count <= 4'hf;          //счетчик бит
	end
	else 
	begin
		if (oSPI_END)              //как только счетчик бит == 0, транзакция завершена
			spi_count_en <= 1'b0;
		else if (iSPI_GO)          //сигнал запуска транзакции от головного модуля
			spi_count_en <= 1'b1;   //засчелкиваем и "удерживаем" EN
			
		 //как только spi_count_en = 1,начинается счет бит 15,14...0
		if (!spi_count_en)	
  		spi_count <= 4'hf;		
		else                               
			spi_count	<= spi_count - 4'b1; //считает с 15-ого бита до 0

	 //если транзакция чтения и биты RW, MB, 6'REG_ADDR передали, то теперь 
	 //принимаем биты 8'REG_DATA
    if (read_mode && !write_address)
		  oS2P_DATA <= {oS2P_DATA[SO_DataL-1:0], SPI_SDIO}; //сдвиговый регистр, новый бит
	end                                                    //вдвигается в младший разряд                                

endmodule 