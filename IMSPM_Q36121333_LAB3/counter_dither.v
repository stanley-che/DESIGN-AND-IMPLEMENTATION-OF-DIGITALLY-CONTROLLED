module counter_dither(clk,rst,d_n_input,duty);
    input clk,rst;
    input [6:0]d_n_input;
    output reg duty;
    reg [6:0]count;
    //counter
    always@(posedge clk or posedge rst)begin
        if(rst)begin
            count<=0;
        end else if(count==7'b1111111) begin
            count<=0;
        end else begin
            count<=count+7'b1;         
        end
    end
    
    //comparator
    always@ (posedge clk or posedge rst)begin
        if(rst)begin
            duty<=0;
        end else begin
            if(count==0)duty<=1;
            else if(count>=d_n_input)
              duty<=0;
        end
          
    end
endmodule
