module hybrid_pwm(clk_count,rst, d_n_input, duty);
    input clk_count,rst;
    input wire [9:0]d_n_input;
    output reg duty;
    wire i0,i1,i2,i3,i4,i5,i6,i7,i8;
    reg temp=0;
    reg [6:0]count;
    reg delay;
    //counter module
    always@(posedge clk_count or posedge rst)begin
        if(rst)begin
            count<=0;
        end else if(count==7'b1111111) begin
            count<=0;
            temp <=0;
            delay<=0;
        end else begin
            count<=count+1;  
        end
    end
    //counter based comparator
    always@(posedge clk_count or posedge rst)begin
        if(rst)begin
            duty<=0;
        end else begin
            //start pull up
            if(count==0)begin
                duty<=1;  
            end 
            //check to delay block
            if(count==d_n_input[9:3])begin
                temp<=1;
            end
            //the final step for one cycle
            if(count ==7'd127)begin
                temp<=0;
            end
        end 
    end
    //buffer
    assign  i0=temp;
    buf#(2,2)(i1,i0);
    buf#(2,2)(i2,i1);
    buf#(2,2)(i3,i2);
    buf#(2,2)(i4,i3);
    buf#(2,2)(i5,i4);
    buf#(2,2)(i6,i5);
    buf#(2,2)(i7,i6);
    buf#(2,2)(i8,i7);
    always @(*)begin
        case(d_n_input[2:0])
           3'b000:  delay<=i0;
           3'b001:  delay<=i1;
           3'b010:  delay<=i2;
           3'b011:  delay<=i3;
           3'b100:  delay<=i4;
           3'b101:  delay<=i5;
           3'b110:  delay<=i6;
           3'b111:  delay<=i7;
           default: delay<=i0;
        endcase
    end
    //sr latch
    always@(*)begin
        if(count==0)begin
            temp<=0;
        end else if(delay==1) begin
            duty<=0;
        end  
    end
endmodule