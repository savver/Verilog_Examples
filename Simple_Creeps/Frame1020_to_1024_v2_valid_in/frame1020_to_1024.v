module Frame1020_to_1024
//#(
//  //parameter BYTES_IN_FRAME = 1020
//    parameter BYTES_IN_FRAME = 32 //только для симуляции
//)
(
	input CLK,
	input nRST,
	input IN,
	input VALID_IN,
	
	output reg OUT,
	output     VALID_OUT
);

localparam BYTES_IN_FRAME = 32; //только для симуляции

//период счета
localparam  BITS_IN_OUT_FRAME = 8*(BYTES_IN_FRAME + 4);
 
//https://www.chipverify.com/verilog/verilog-math-functions 
//$clog2 is supported by Verilog, but only Verilog-2005 (IEEE Std 1364-2005).
reg [$clog2(BITS_IN_OUT_FRAME) - 1:0]   counter;
reg [32:0]	shift_reg;


//VALID_OUT появится на 1 такт позже, чем VALID_IN,
//за счет этого к моменту выставления VALID_OUT, в OUT
//как раз будет старший бит старшего байта маркера
// 
//и вообще VALID_OUT должен держаться на 32 бита дольше, чем 
//VALID_IN, т.к. мы в начале маркер передавали, поэтому внизу
//удлиняем до 32 тактов
//
always @(posedge CLK)
begin
	if(nRST == 1'b0)
		begin
			shift_reg[32:0] 	<= 0;
			counter 				<= 0;
		end
		
	else if (VALID_IN || VALID_OUT)
		begin
			if(counter < BITS_IN_OUT_FRAME)	
				counter <= counter + 1'b1;
			else 						
				counter <= 0;
			
			if(counter == 0)
				shift_reg[32:0] <= { 8'hAA, 8'h55, 8'h01, 8'h00, IN }; // 1010_1010 0101_0101
			else 
				shift_reg[32:0] <= { shift_reg[31:0], IN };
				
			//VALID_OUT <= VALID_IN;
		end 
	
	OUT <= shift_reg[32];
end


Longer_Pulse #(33)   valid_in2out
(
	.CLK	(CLK),
	.IN	(VALID_IN),
	.OUT	(VALID_OUT)
);

endmodule 