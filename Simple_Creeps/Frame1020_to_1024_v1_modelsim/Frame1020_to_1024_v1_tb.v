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
	nRST = 0; #11; nRST = 1;
	
  //---------------------------
  in_data_cntr = 0; //выполняется после nRST выше
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
	$display ("[%d] CLK_pe: OUT=%d", in_data_cntr, OUT);
end

always @(negedge CLK)
begin
   $display ("[%d] CLK_ne: OUT=%d", in_data_cntr, OUT); //работает
	$display ("-------------------------");
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
# [          x] CLK_ne: OUT=x
# -------------------------
# [          x] CLK_pe: OUT=x
# [          x] CLK_ne: OUT=x
# -------------------------
# [          0] IN=1
# [          0] CLK_pe: OUT=x
# [          0] CLK_ne: OUT=0
# -------------------------
# [          1] IN=1
# [          1] CLK_pe: OUT=0
# [          1] CLK_ne: OUT=1
# -------------------------
# [          2] IN=1
# [          2] CLK_pe: OUT=1
# [          2] CLK_ne: OUT=0
# -------------------------
# [          3] IN=1
# [          3] CLK_pe: OUT=0
# [          3] CLK_ne: OUT=1
# -------------------------
*/