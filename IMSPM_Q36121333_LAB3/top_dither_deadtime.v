`timescale 1ns/1ns
`include"dither.v"
`include"dither_deadtime_count.v"
module top_dither_deadtime(clk,rst,dither_in,duty_high,duty_low);
    input clk,rst;
    input wire[9:0]dither_in;
    output  duty_high,duty_low;
    wire [6:0] d_dith;
    reg  [6:0] clk2;
    reg clk_in;
    
    //divide frequency
    always@(posedge clk or posedge rst)begin
          if(rst)begin
              clk_in<=0;
              clk2<=7'b0;
          end else if(clk2 ==7'd63) begin
              clk_in<=~clk_in;
              clk2  <=7'd0;
          end else begin
              clk2  <=clk2+7'd1;
          end
    end
    dither u_dither(clk_in,rst,dither_in,d_dith);
    dither_time u_count(clk,rst,d_dith,duty_high,duty_low);
endmodule
