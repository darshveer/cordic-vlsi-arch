`timescale 1ns / 1ps

module Stage5 #(
    parameter signed [15:0] TL       = 16'sd64,   // 0.0625 deg * 1024
    parameter signed [15:0] TH       = 16'sd176,  // 0.171875 deg * 1024  (was swapped!)
    parameter signed [15:0] DELTA_HI = 16'sd229,  // delta8 = 0.2238 deg * 1024
    parameter signed [15:0] DELTA_LO = 16'sd115   // delta9 = 0.1119 deg * 1024 (was 122!)
)(
    input  wire        clk,
    input  wire signed [15:0] angle,
    input  wire signed [15:0] x,
    input  wire signed [15:0] y,

    output reg  signed [15:0] angle_out,
    output reg  signed [15:0] x_out,
    output reg  signed [15:0] y_out
);

    wire signed [15:0] abs_angle = angle[15] ? -angle : angle;
    wire sign     = angle[15];
    wire sigma_hi = (abs_angle >= TH);                           // rotate by delta8
    wire sigma_lo = (abs_angle >= TL) && (abs_angle < TH);      // rotate by delta9

    // SA8 = 2^-8, SA9 = 2^-9 (cosine ≈ 1, no correction needed)
    wire signed [15:0] y_sin = sigma_hi ? (y >>> 8) : sigma_lo ? (y >>> 9) : 16'sd0;
    wire signed [15:0] x_sin = sigma_hi ? (x >>> 8) : sigma_lo ? (x >>> 9) : 16'sd0;

    wire signed [15:0] x_next = sign ? (x + y_sin) : (x - y_sin);
    wire signed [15:0] y_next = sign ? (y - x_sin) : (y + x_sin);

    wire signed [15:0] delta = sigma_hi ? DELTA_HI : sigma_lo ? DELTA_LO : 16'sd0;
    wire signed [15:0] angle_next = sign ? (angle + delta) : (angle - delta);

    always @(posedge clk) begin
        x_out     <= x_next;
        y_out     <= y_next;
        angle_out <= angle_next;
    end
endmodule