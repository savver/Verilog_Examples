module Frame1020_to_1024
//#(
//  //parameter BYTES_IN_FRAME = 1020
//    parameter BYTES_IN_FRAME = 32 //только для симуляции
//)
(
	input CLK,
	input nRST,
	input IN,
	output reg OUT
);

localparam BYTES_IN_FRAME = 32; //только для симуляции

//период счета
localparam  BITS_IN_OUT_FRAME = 8*(BYTES_IN_FRAME + 4);
 
//https://www.chipverify.com/verilog/verilog-math-functions 
//$clog2 is supported by Verilog, but only Verilog-2005 (IEEE Std 1364-2005).
reg [$clog2(BITS_IN_OUT_FRAME) - 1:0]   counter;
reg [32:0]	shift_reg;
reg 			pre_OUT;


always @(posedge CLK)
begin
	if(nRST == 1'b0)
		begin
			shift_reg[32:0] 	<= 0;
			counter 				<= 0;
		end
		
	else
		begin
			if(counter < BITS_IN_OUT_FRAME)	
				counter <= counter + 1'b1;
			else 						
				counter <= 0;
			
			if(counter == 0)
				shift_reg[32:0] <= { 8'hAA, 8'h55, 8'h01, 8'h00, IN }; // 1010_1010 0101_0101
			else 
				shift_reg[32:0] <= { shift_reg[31:0], IN };
		end 
	
	//pre_OUT <= shift_reg[32];
	//OUT <= pre_OUT;
	
	OUT <= shift_reg[32];
end

endmodule 