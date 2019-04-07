module SEARCH_CORE(
    input [1:0] stop,
    input logic clk,
    input logic reset,
    input [23:0] key_low,
    input [23:0] key_high,
    output [23:0] secret_key,
    output found
);


parameter INITIALIZE            =   8'b0000_0000;      
parameter FILL_S                =   8'b0000_0001;  
parameter READ_SI               =   8'b0000_0010;   
parameter WAIT_SI               =   8'b0000_0011;   
parameter CALCJ                 =   8'b0000_0100;   
parameter READSJ                =   8'b0000_0101;   
parameter WAIT_SJ               =   8'b0000_0110;   
parameter SWAP_SJ               =   8'b0000_0111;   
parameter SWAP_SI               =   8'b0000_1000;   
parameter B_READ_SI             =   8'b0000_1001;   
parameter B_WAIT_SI             =   8'b0000_1010;   
parameter CALC_READ_J           =   8'b0000_1011; 
parameter WAIT_READ_J           =   8'b0000_1100;   
parameter B_SWAP_SJ             =   8'b0000_1101;  
parameter B_SWAP_SI             =   8'b0000_1110;   
parameter READF                 =   8'b0000_1111;     
parameter READ_E                =   8'b0001_0000;   
parameter WAIT_F                =   8'b0001_0001;    
parameter STORE                 =   8'b0001_0010;  
parameter LOOP                  =   8'b0001_0011;    
parameter BUFFER                =   8'b0001_0100;
parameter CRACKED               =   8'b0001_0101;
parameter FAILED                =   8'b0001_0110;
parameter NEXT_KEY              =   8'b0001_0111;


logic [7:0] s_data, data_d;
logic [7:0] s_addr, d_addr, e_addr;
logic s_wren, wren_d;
logic [7:0] s_q, e_q, d_q;
logic [7:0] read_i, read_j, f_read;
logic [7:0] state;
byte secret_key_byte[3];
logic [7:0] i, j;
logic [4:0] k;

initial found = 1'b0;

// Initialize memories
s_memory S(
        .address(s_addr),		
		.clock(clk),		
		.data(s_data),		
		.wren(s_wren),		
		.q(s_q)		
	);
 d_memory D(
	.address(d_addr),
	.clock(clk),
	.data(data_d),
	.wren(wren_d),
	.q(d_q)
	);	
 e_memory E(
	.address({e_addr}),
	.clock(clk),
	.q(e_q));

always_ff@(posedge clk or negedge reset) 
begin
    if(!reset) state <= INITIALIZE;     //If reset, go back to intitialize
    else if(stop == 2'b10) state <= BUFFER; //else if stop, go to loop state at end
	else 
    begin
        case(state)
            INITIALIZE: // Initialize values to zero
                begin             
                    {i, j, s_data, s_addr} <= {8'b0,8'b0,8'b0,8'b0}; 
                    secret_key <= key_low;  
                    found <= 1'b0;        
                    state <= FILL_S;   
                end
            FILL_S:     // Fill S memory with i at address i
                begin             
                    s_wren <= 1'b1;
                    s_addr <= i;          
                    s_data <= i;         
                    if(s_data < 8'd255) 
                        begin  
                            i <= i+1'b1;                      
                            state <= FILL_S; 
                        end
                    else 
                        begin
                            s_wren <= 1'b0;          
                            state <= READ_SI;               
                            i <= 0;                            
                        end
                end
            READ_SI: //Set address to i
                begin 
                    s_addr <= i;            
                    s_wren <= 1'b0;	 	
                    state <= WAIT_SI;		
				end
            WAIT_SI:  // Wait 1 clock cycle for data  
                begin
                    state <= CALCJ;
                end
            CALCJ:  // Read output from memory, and apply formula to calc j
                begin            
                    read_i = s_q;    
					j <= (j + read_i + secret_key_byte[i%3]);
                    state <= READSJ;     
                end
            READSJ: // Set read enable to zero and address to j
                begin
                    s_wren <= 0;   
                    s_addr <= j;           
                    state <= WAIT_SJ;        
                end
            WAIT_SJ: state <= SWAP_SJ; //Wait 1 clock cycle for data
            SWAP_SJ: // Store output data in read_j, then send read_i to j, swapping the values
                begin            
                    read_j <= s_q;   
                    s_data <= read_i;   
                    s_addr <= j;           
                    s_wren <= 1'b1;   
                    state <= SWAP_SI;      
                end
            SWAP_SI: // Send read_j to i, swapping values
                begin	
                    s_data <= read_j;   
                    s_addr = i;           
                    s_wren <= 1'b1;   

                    if(i < 8'd255)  // check if i = 255, else incrememnt and repeat loop
                        begin      
                            i <= i+1'b1;        
                            state <= READ_SI;   
                        end
                    else // If i =255, reset i,j,k and move to task2b
                        begin
                            state <= B_READ_SI;     
                            i <= 8'd0;
                            j <= 8'd0;
                            k <= 8'd0;
                        end
                end 
            B_READ_SI: // Increment i, and set address to i
                begin
                    i = i + 1'b1;              
                    s_wren <= 1'b0;   
                    wren_d <= 1'b0;           
                    s_addr <= i;           
                    state <= B_WAIT_SI;     
                end

            B_WAIT_SI: state <= CALC_READ_J;//wait one clock cycle to read
            CALC_READ_J: //store read val into read_i, calculate j, and set address to j 
                begin
                    read_i = s_q;    
                    j = j+read_i;           
                    s_addr <= j;           
                    s_wren = 1'b0;    
                    state <= WAIT_READ_J;     
                end
            WAIT_READ_J: state <= B_SWAP_SJ;    // Wait one clock cycle to read
            B_SWAP_SJ:  // Store output from mem into read_j, set address to j and data to write as read_i
                begin         
                    read_j = s_q;        
                    s_addr <= j;              
                    s_data <= read_i;      
                    s_wren <= 1'b1;       // Enable wren to write
                    state <= B_SWAP_SI;         
                end
            B_SWAP_SI: // set address to i, data to read_j, effectively swapping s[i] and s[j]
                begin 
                    s_addr <= i;              
                    s_data <= read_j;      
                    s_wren = 1'b1;        
                    state <= READF;             
                end
            READF: // Turn off read enable bit, calculate next address to read from as read_i + read_j
                begin
                    s_wren <= 1'b0;      
                    s_addr <= read_i+read_j;
                    state <= READ_E;           
                end
            READ_E: // Set read address for E memory as k
                begin
                    e_addr <= k;          
                    state <= WAIT_F;          
                end
            WAIT_F: // Read from S memory after waiting a cycle and store into f_read
                begin
                    f_read=s_q;        
                    state<= STORE;
                end
            STORE:  // Calculate data to send to D memory using XOR between f_read and output of E memory
                begin
                    data_d <= (f_read ^ e_q);     
                    d_addr <= k;               
                    wren_d <= 1'b1;        // Enable write bit for D Memory
                    state <= LOOP;		        
                end
            LOOP: 
                begin
                    if((data_d >= 8'd97) && (data_d <= 8'd122) || (data_d == 8'd32)) // Check if value is lowercase or space
                        begin 
                            if (k < 5'd31) // If so, check if k = 31
                                begin          
                                    k <= k + 1'b1;           // Else, incremment k and repeat   
                                    state <= B_READ_SI;
                                end 
                            else  state <= CRACKED; // If k=31, then the key has been found
                        end
                    else state <= NEXT_KEY; //If not lowercase or space, incremment key and try again
                end
            NEXT_KEY: // Increment key
                begin
                    secret_key <= secret_key + 24'b1;
                    if(secret_key > key_high) state <= FAILED; // If key has reached max value, then message has no key 
                    else // Else, after incrementing key, restart fsm
                        begin
                            {i, j, s_data, s_addr, wren_d, s_wren} <= {8'b0,8'b0,8'b0,8'b0,1'b0,1'b0};  
                            state <= FILL_S;
                        end
                end
            FAILED: // No key found, leave found as 1'b0
                begin
                    state <= BUFFER;
                end
            CRACKED:    // Key found, set found to 1'b1
                begin
                    state <= BUFFER;
                    found <= 1'b1;
                end      
            BUFFER: // Infinite loop where fsm stays so we can view memory contents
                begin    
                    wren_d <= 1'b0;
                    s_wren <= 1'b0;
                    i <= 8'b0;
                    j <= 8'b0;
                    k <= 8'b0;
                    state <= BUFFER;
                end
            default: state <= INITIALIZE;
            endcase
    end
end 

// Combinational block to keep secret_key_byte updated
always_comb
begin
    secret_key_byte[0] <= secret_key[23:16];
    secret_key_byte[1] <= secret_key[15:8];
    secret_key_byte[2] <= secret_key[7:0];      
end

endmodule