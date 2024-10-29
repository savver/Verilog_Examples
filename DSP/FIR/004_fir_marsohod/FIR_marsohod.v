module FIR_marsohod
(
	input 			tb_clk,
	input  [15:0] 	DATA_IN,
	output [15:0]  DATA_OUT
);

fir #( .TAPS(7) ) fir_lp_inst(
  .clk(tb_clk),
  .coefs( {
    -32'd510,  //0
    -32'd520,  //1
    -32'd520,  //2
     32'd575,  //3
     32'd625,  //4
    -32'd520,  //5
    -32'd510   //6
    } ),
  .in(DATA_IN),
  .out(DATA_OUT)
);

endmodule 