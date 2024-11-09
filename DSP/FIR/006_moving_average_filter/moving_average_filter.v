// https://programmersought.com/article/44506033139/
//
module moving_average_filter
#(
	parameter AVE_DATA_NUM = 5'd8,
	parameter AVE_DATA_BIT = 5'd3
)
(
	input i_rst_n,
	input i_clk,
	input [31:0]din,
	output [31:0]dout
);

reg [31:0] data_reg [AVE_DATA_NUM-1:0];

reg [7:0]temp_i;

always @ (posedge i_clk or negedge i_rst_n)
	if(!i_rst_n)
		for (temp_i=0; temp_i<AVE_DATA_NUM; temp_i=temp_i+1)
			data_reg[temp_i] <= 'd0;
	else
	begin
		data_reg[0] <= din;
		for (temp_i=0; temp_i<AVE_DATA_NUM-1; temp_i=temp_i+1)
			data_reg[temp_i+1] <= data_reg[temp_i];
	end

reg [31:0] sum;

always @ (posedge i_clk or negedge i_rst_n)
if (!i_rst_n)
	sum <= 'd0;
else
	sum <= sum + din - data_reg[AVE_DATA_NUM-1]; //Change the oldest data to the latest input data

assign dout = sum >> AVE_DATA_BIT;  //Shift 3 to the right is equivalent to ÷8

endmodule 