module ksa(
    input CLOCK_50,          
    input [3:0] KEY,               
    input [9:0] SW,                 
    output [9:0] LEDR, 
    output [6:0] HEX0,
    output [6:0] HEX1,
    output [6:0] HEX2,
    output [6:0] HEX3,
    output [6:0] HEX4,
    output [6:0] HEX5
);

logic [23:0] secret_key;
logic [23:0] s1_secret_key, s2_secret_key, s3_secret_key, s4_secret_key;
logic reset;
logic s1_found, s2_found, s3_found, s4_found;
logic s1_fail, s2_fail, s3_fail, s4_fail;
logic [1:0] stop = 2'b00;

assign clk = CLOCK_50;
assign reset = KEY[3];

// Depending on switch postitions, choose which secret key values to display
// Once key is found, it has priority and is the only thing displayed on hex
always_comb         
begin
    casex({reset,s1_found,s2_found,s3_found,s4_found,SW[3:0]})
    9'b100000000: begin secret_key = s1_secret_key; LEDR = 10'h2AA; stop = 2'b00; end
    9'b100000001: begin secret_key = s2_secret_key; LEDR = 10'h2AA; stop = 2'b00; end
    9'b100000011: begin secret_key = s3_secret_key; LEDR = 10'h2AA; stop = 2'b00; end
    9'b100000111: begin secret_key = s4_secret_key; LEDR = 10'h2AA; stop = 2'b00; end
    9'b11000xxxx: begin secret_key = s1_secret_key; LEDR = 10'h3FF; stop = 2'b10; end
    9'b10100xxxx: begin secret_key = s2_secret_key; LEDR = 10'h3FF; stop = 2'b10; end
    9'b10010xxxx: begin secret_key = s3_secret_key; LEDR = 10'h3FF; stop = 2'b10; end
    9'b10001xxxx: begin secret_key = s4_secret_key; LEDR = 10'h3FF; stop = 2'b10; end
    9'b0xxxxxxxx: begin secret_key = 24'b0;         LEDR = 10'h0;   stop = 2'b00; end
    default:      begin secret_key = 24'b0;         LEDR = 10'h300; stop = 2'b00; end
    endcase
end

SevenSegmentDisplayDecoder DISPLAY0(.nIn(secret_key[3:0]),      .ssOut(HEX0));
SevenSegmentDisplayDecoder DISPLAY1(.nIn(secret_key[7:4]),      .ssOut(HEX1));
SevenSegmentDisplayDecoder DISPLAY2(.nIn(secret_key[11:8]),     .ssOut(HEX2));
SevenSegmentDisplayDecoder DISPLAY3(.nIn(secret_key[15:12]),    .ssOut(HEX3));
SevenSegmentDisplayDecoder DISPLAY4(.nIn(secret_key[19:16]),    .ssOut(HEX4));
SevenSegmentDisplayDecoder DISPLAY5(.nIn(secret_key[23:20]),    .ssOut(HEX5));
//Instantiate all four cores
SEARCH_CORE S1(
    .clk(clk),
    .secret_key(s1_secret_key),
    .found(s1_found),
    .stop(stop),
    .key_low(24'h0),
    .key_high(24'hFFFFF),
    .reset(reset)
    );

SEARCH_CORE S2(
    .clk(clk),
    .secret_key(s2_secret_key),
    .found(s2_found),
    .stop(stop),
    .key_low(24'h100000),
    .key_high(24'h1FFFFF),
    .reset(reset)
    );

SEARCH_CORE S3(
    .clk(clk),
    .secret_key(s3_secret_key),
    .found(s3_found),
    .stop(stop),
    .key_low(24'h200000),
    .key_high(24'h2FFFFF),
    .reset(reset)
    );

SEARCH_CORE S4(
    .clk(clk),
    .secret_key(s4_secret_key),
    .found(s4_found),
    .stop(stop),
    .key_low(24'h300000),
    .key_high(24'h3FFFFF),
    .reset(reset)
    );




endmodule


