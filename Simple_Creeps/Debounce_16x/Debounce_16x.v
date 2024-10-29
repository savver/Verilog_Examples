module Debounce_16x 
(
	input clk,
	input in,
	output out
);

reg [15:0] shift;
reg r_out;

assign out = r_out;

always @(posedge clk)
	begin
		shift [15:0] <= {shift[14:0], in};
		if (&shift[15:0])
			r_out <= 1;
		else if (~|shift[15:0])
			r_out <= 0;	
	end
	

endmodule
