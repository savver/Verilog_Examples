`timescale 1 ns/ 1 ps       //time_unit / time_precision
module Frame1020_to_1024_v1_tb;

// те сигналы, что будем передавать в вызываемый для теста модуль
reg CLK;
reg IN;
reg nRST;                                            
wire OUT;

//64 отсчетов в файле входных данных
reg [0:0] in_test_data[0:63];  //именно так указать, как "память" [0:0], иначе ругается моделсим

integer in_data_cntr;
integer i;

//выходной файл с данными
integer output_file_data;

Frame1020_to_1024   f1
(
	.CLK	(CLK),
	.IN	(IN),
	.OUT	(OUT),
	.nRST	(nRST)	
);

// Эмуляция тактовой частоты
always
begin
	#5 CLK = ~CLK;  //1 шаг = 1 ns, т.о. период 10 нс, 100 МГц
end

initial 
begin 
	output_file_data=$fopen("output_data.txt", "w");
 //$readmemb("input_test_data.txt",in_test_data);         //ищет файл в папке /simulation/modelsim
   $readmemb("../../input_test_data_2.txt",in_test_data); //ищет файл на одном уровне с исходниками
	
	//тест чтения из файла -> читает верно
	$display("in_data:");
	for (i=0; i < 4; i=i+1)
		$display("%d:%h",i,in_test_data[i]);

	CLK = 0;
	
	//reset схемы
	nRST = 0; #10; nRST = 1;
	
  //---------------------------
  in_data_cntr = 0;
  repeat(64) //скок в файле входных векторов
  begin
    #10;
    in_data_cntr = in_data_cntr + 1'd1;
  end
  //---------------------------
	
	#1000 $stop; //конец симуляции через 1 мкс
end 

always @(in_data_cntr)
begin
	IN = in_test_data[in_data_cntr];
	$display ("[%d] IN=%d", in_data_cntr, IN);
end

always @(posedge CLK)
begin
   $fwrite(output_file_data,"%b ",OUT);
end

always @(negedge CLK)
begin
   $display ("[%d] CLK_negedge: OUT=%d", in_data_cntr, OUT); //работает
end

endmodule
	
/*
-------------------------------------------
$finish 	exits the simulation and gives control back to the operating system.
$stop 	suspends the simulation and puts a simulator in an interactive mode.
-------------------------------------------
https://stackoverflow.com/questions/72181607/i-get-a-warning-about-readmemh-too-many-words-in-the-file 
-------------------------------------------
https://stackoverflow.com/questions/37135859/in-verilog-im-trying-to-use-readmemb-to-read-txt-file-but-it-only-loads-xxxx

*/

/*
# run -all
# in_data:
#           0:1
#           1:1
#           2:1
#           3:1
# [          x] CLK_negedge: OUT=x
# [          0] CLK_negedge: OUT=x
# [          0] IN=1
# [          1] CLK_negedge: OUT=0
# [          1] IN=1
# [          2] CLK_negedge: OUT=1
# [          2] IN=1
# [          3] CLK_negedge: OUT=0
# [          3] IN=1
# [          4] CLK_negedge: OUT=1
# [          4] IN=1
# [          5] CLK_negedge: OUT=0
# [          5] IN=1
# [          6] CLK_negedge: OUT=1
# [          6] IN=1
# [          7] CLK_negedge: OUT=0
# [          7] IN=0
# [          8] CLK_negedge: OUT=1
# [          8] IN=0
# [          9] CLK_negedge: OUT=0
# [          9] IN=0
# [         10] CLK_negedge: OUT=0
# [         10] IN=0
# [         11] CLK_negedge: OUT=1
# [         11] IN=0
# [         12] CLK_negedge: OUT=0
# [         12] IN=0
# [         13] CLK_negedge: OUT=1
# [         13] IN=1
# [         14] CLK_negedge: OUT=0
# [         14] IN=1
# [         15] CLK_negedge: OUT=1
# [         15] IN=0
# [         16] CLK_negedge: OUT=0
# [         16] IN=1
# [         17] CLK_negedge: OUT=1
# [         17] IN=0
# [         18] CLK_negedge: OUT=0
# [         18] IN=1
# [         19] CLK_negedge: OUT=0
# [         19] IN=0
# [         20] CLK_negedge: OUT=0
# [         20] IN=1
# [         21] CLK_negedge: OUT=0
# [         21] IN=1
# [         22] CLK_negedge: OUT=0
# [         22] IN=1
# [         23] CLK_negedge: OUT=0
# [         23] IN=0
# [         24] CLK_negedge: OUT=0
# [         24] IN=0
# [         25] CLK_negedge: OUT=1
# [         25] IN=0
# [         26] CLK_negedge: OUT=0
# [         26] IN=0
# [         27] CLK_negedge: OUT=0
# [         27] IN=0
# [         28] CLK_negedge: OUT=0
# [         28] IN=0
# [         29] CLK_negedge: OUT=0
# [         29] IN=1
# [         30] CLK_negedge: OUT=0
# [         30] IN=1
# [         31] CLK_negedge: OUT=0
# [         31] IN=0
# [         32] CLK_negedge: OUT=0
# [         32] IN=1
# [         33] CLK_negedge: OUT=0
# [         33] IN=0
# [         34] CLK_negedge: OUT=1
# [         34] IN=1
# [         35] CLK_negedge: OUT=1
# [         35] IN=0
# [         36] CLK_negedge: OUT=1
# [         36] IN=1
# [         37] CLK_negedge: OUT=1
# [         37] IN=1
# [         38] CLK_negedge: OUT=1
# [         38] IN=1
# [         39] CLK_negedge: OUT=1
# [         39] IN=0
# [         40] CLK_negedge: OUT=1
# [         40] IN=0
# [         41] CLK_negedge: OUT=0
# [         41] IN=0
# [         42] CLK_negedge: OUT=0
# [         42] IN=0
# [         43] CLK_negedge: OUT=0
# [         43] IN=0
# [         44] CLK_negedge: OUT=0
# [         44] IN=0
# [         45] CLK_negedge: OUT=0
# [         45] IN=1
# [         46] CLK_negedge: OUT=0
# [         46] IN=1
# [         47] CLK_negedge: OUT=1
# [         47] IN=0
# [         48] CLK_negedge: OUT=1
# [         48] IN=1
# [         49] CLK_negedge: OUT=0
# [         49] IN=0
# [         50] CLK_negedge: OUT=1
# [         50] IN=1
# [         51] CLK_negedge: OUT=0
# [         51] IN=0
# [         52] CLK_negedge: OUT=1
# [         52] IN=1
# [         53] CLK_negedge: OUT=0
# [         53] IN=1
# [         54] CLK_negedge: OUT=1
# [         54] IN=1
# [         55] CLK_negedge: OUT=1
# [         55] IN=0
# [         56] CLK_negedge: OUT=1
# [         56] IN=0
# [         57] CLK_negedge: OUT=0
# [         57] IN=0
# [         58] CLK_negedge: OUT=0
# [         58] IN=0
# [         59] CLK_negedge: OUT=0
# [         59] IN=1
# [         60] CLK_negedge: OUT=0
# [         60] IN=0
# [         61] CLK_negedge: OUT=0
# [         61] IN=1
# [         62] CLK_negedge: OUT=0
# [         62] IN=0
# [         63] CLK_negedge: OUT=1
# [         63] IN=1
# [         64] CLK_negedge: OUT=1
# [         64] IN=x
# [         64] CLK_negedge: OUT=0
# [         64] CLK_negedge: OUT=1
# [         64] CLK_negedge: OUT=0
# [         64] CLK_negedge: OUT=1
# [         64] CLK_negedge: OUT=0
*/