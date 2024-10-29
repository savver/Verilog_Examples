module Longer_3x
(
	input 	CLK,
	input 	CUR,
	output	OUT
);

reg [2:0] 	shift;

always @(posedge CLK) 
begin
	shift[2:0] <= { shift[1:0], CUR }; 
end

assign OUT = |shift[2:0];

endmodule 