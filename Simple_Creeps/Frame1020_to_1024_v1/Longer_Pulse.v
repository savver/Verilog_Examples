module Longer_Pulse
#(
    parameter LENGTH = 32
)
(
	input 	CLK,
	input 	IN,
	output	OUT
);

reg [LENGTH-1:0] 	shift;

always @(posedge CLK) 
begin
	shift[LENGTH-1:0] <= { shift[LENGTH-2:0], IN }; 
end

assign OUT = |shift[LENGTH-1:0];

endmodule 