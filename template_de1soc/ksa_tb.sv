module ksa_tb();

    logic               CLOCK_50;
    logic    [9:0]      LEDR;
    logic    [3:0]      KEY;
    logic    [9:0]      SW;
    logic    [6:0]      HEX0;
    logic    [6:0]      HEX1;
    logic    [6:0]      HEX2;
    logic    [6:0]      HEX3;
    logic    [6:0]      HEX4;
    logic    [6:0]      HEX5;

ksa DUT1(
    .CLOCK_50(CLOCK_50),          
    .KEY(KEY),               
    .SW(SW),                 
    .LEDR(LEDR), 
    .HEX0(HEX0),
    .HEX1(HEX1),
    .HEX2(HEX2),
    .HEX3(HEX3),
    .HEX4(HEX4),
    .HEX5(HEX5)
);


    initial begin 
	CLOCK_50 = 0; #1;
    	forever begin
      	CLOCK_50 = 1; #1;
      	CLOCK_50 = 0; #1;
    	end
    end

   

    initial begin
 	#50;
    end
endmodule
