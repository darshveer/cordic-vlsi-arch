`timescale 1ns / 1ps

module Stage1 #(
    parameter WIDTH = 16
)(
    input  wire                  clk,
    input  wire signed [WIDTH-1:0] x_in,
    input  wire signed [WIDTH-1:0] y_in,
    input  wire        [15:0]    angle_in,   // unsigned from preprocess [0,45deg]

    output reg  signed [WIDTH-1:0] x_out,
    output reg  signed [WIDTH-1:0] y_out,
    output reg  signed [15:0]    angle_out
);

    // threshold = 16 degrees (16 * 1024 = 16384)
    wire sigma1 = (angle_in >= 16'd16384);

    // CA1 = 1 - 2^-3 = 0.875
    wire signed [WIDTH-1:0] x_ca = x_in - (x_in >>> 3);
    wire signed [WIDTH-1:0] y_ca = y_in - (y_in >>> 3);

    // SA1 (16-bit accuracy) = 2^-1 - 2^-6 - 2^-12
    wire signed [WIDTH-1:0] x_sa = (x_in >>> 1) - (x_in >>> 6) - (x_in >>> 12);
    wire signed [WIDTH-1:0] y_sa = (y_in >>> 1) - (y_in >>> 6) - (y_in >>> 12);

    // Stage1 is ALWAYS counter-clockwise (uni-directional)
    wire signed [WIDTH-1:0] x_rot = x_ca - y_sa;
    wire signed [WIDTH-1:0] y_rot = y_ca + x_sa;

    // delta1 = 28.9677 deg * 1024 = 29,663
    always @(posedge clk) begin
        x_out     <= sigma1 ? x_rot : x_in;
        y_out     <= sigma1 ? y_rot : y_in;
        angle_out <= sigma1 ? ($signed({1'b0, angle_in}) - 16'sd29663)
                            : $signed({1'b0, angle_in});
    end
endmodule