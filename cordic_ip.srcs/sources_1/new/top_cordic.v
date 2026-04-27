`timescale 1ns / 1ps

module top_cordic (
    input  wire        clk,
    input  wire [18:0] angle_in,
    input  wire signed [15:0] x_in,
    input  wire signed [15:0] y_in,

    output wire signed [15:0] x_out,
    output wire signed [15:0] y_out,
    output wire signed [15:0] residual_angle
);

    // ---- Pre-processing ----
    wire [15:0] theta_p;
    wire s_pre, ns_pre, nc_pre;

    cordic_preprocess PRE (
        .theta_in(angle_in),
        .theta_p(theta_p),
        .s(s_pre), .ns(ns_pre), .nc(nc_pre)
    );

    // ---- Pipeline the control signals (5 stages) ----
    reg [2:0] s_pipe  [0:4];
    reg [2:0] ns_pipe [0:4];
    reg [2:0] nc_pipe [0:4];

    // Pack into shift registers
    reg s_d[1:5], ns_d[1:5], nc_d[1:5];
    integer k;
    always @(posedge clk) begin
        s_d[1]  <= s_pre;  ns_d[1]  <= ns_pre;  nc_d[1]  <= nc_pre;
        s_d[2]  <= s_d[1]; ns_d[2]  <= ns_d[1]; nc_d[2]  <= nc_d[1];
        s_d[3]  <= s_d[2]; ns_d[3]  <= ns_d[2]; nc_d[3]  <= nc_d[2];
        s_d[4]  <= s_d[3]; ns_d[4]  <= ns_d[3]; nc_d[4]  <= nc_d[3];
        s_d[5]  <= s_d[4]; ns_d[5]  <= ns_d[4]; nc_d[5]  <= nc_d[4];
    end

    // ---- Stage 1 ----
    wire signed [15:0] x1, y1, a1;
    Stage1 #(.WIDTH(16)) S1 (
        .clk(clk),
        .x_in(x_in), .y_in(y_in), .angle_in(theta_p),
        .x_out(x1),  .y_out(y1),  .angle_out(a1)
    );

    // ---- Stage 2 (pair theta2, theta3) ----
    wire signed [15:0] x2, y2, a2;
    stage_module #(
        .TL(16'sd4096), .TH(16'sd10240),
        .DELTA_HI(16'sd14818), .DELTA_LO(16'sd7353), .ITER(1)
    ) S2 (
        .clk(clk),
        .angle(a1), .x(x1), .y(y1),
        .angle_out(a2), .x_out(x2), .y_out(y2)
    );

    // ---- Stage 3 (pair theta4, theta5) ----
    wire signed [15:0] x3, y3, a3;
    stage_module #(
        .TL(16'sd1024), .TH(16'sd2816),
        .DELTA_HI(16'sd3669), .DELTA_LO(16'sd1834), .ITER(2)
    ) S3 (
        .clk(clk),
        .angle(a2), .x(x2), .y(y2),
        .angle_out(a3), .x_out(x3), .y_out(y3)
    );

    // ---- Stage 4 (pair theta6, theta7) ----
    wire signed [15:0] x4, y4, a4;
    stage_module #(
        .TL(16'sd256), .TH(16'sd704),
        .DELTA_HI(16'sd917), .DELTA_LO(16'sd458), .ITER(3)
    ) S4 (
        .clk(clk),
        .angle(a3), .x(x3), .y(y3),
        .angle_out(a4), .x_out(x4), .y_out(y4)
    );

    // ---- Stage 5 (pair theta8, theta9) ----
    wire signed [15:0] x5, y5, a5;
    Stage5 S5 (
        .clk(clk),
        .angle(a4), .x(x4), .y(y4),
        .angle_out(a5), .x_out(x5), .y_out(y5)
    );

    assign residual_angle = a5;

    // ---- Post-processing (Eq. 31 of paper) ----
    // xt = s ? y5 : x5
    // yt = s ? x5 : y5
    // x_out = nc ? -xt : xt
    // y_out = ns ? -yt : yt
    wire signed [15:0] xt = s_d[5] ? y5 : x5;
    wire signed [15:0] yt = s_d[5] ? x5 : y5;
    assign x_out = nc_d[5] ? -xt : xt;
    assign y_out = ns_d[5] ? -yt : yt;

endmodule