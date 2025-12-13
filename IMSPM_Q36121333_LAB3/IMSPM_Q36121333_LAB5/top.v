`timescale 1ns/1ns
module top(clk,rst,data_in,duty_high,duty_low,convst_bar);
    input clk,rst;
    input [7:0]data_in;
    output duty_high;
    output duty_low;
    output wire convst_bar;
    wire [5:0]d_n_input;
    wire [8:0]d_n;
    wire [3:0]err;
    wire [5:0]count;
    wire clk_dpwm,clk_comp;
    //module connection
    encoder encoder(
    .clk(clk),
    .rst(rst),
    .datain(data_in),
    .en(err)
    );
    clkdivider clkdivider(
        .clk(clk),
        .rst(rst),
        .count(count),
        .convst_bar(convst_bar),
        .clk_comp(clk_comp),
        .clk_dpwm(clk_dpwm)
    );
    dither dither(
        .clk_in(clk_dpwm),
        .rst(rst),
        .d_n_input(d_n),
        .d_dith(d_n_input)
    );
    
    dither_time dither_time(
        .clk(clk),
        .rst(rst),
        .d_n_input(d_n_input),
        .duty_high(duty_high),
        .duty_low(duty_low),
        .count(count)
    );
    stanley stanley(
        .clk(clk_comp),
        .rst(rst),
        .err_in(err),
        .d_comp(d_n)
    );
endmodule