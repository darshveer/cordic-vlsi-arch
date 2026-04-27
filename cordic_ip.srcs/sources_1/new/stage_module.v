`timescale 1ns / 1ps

module stage_module #(
    parameter signed [15:0] TL       = 16'sd0,
    parameter signed [15:0] TH       = 16'sd0,
    parameter signed [15:0] DELTA_HI = 16'sd0,
    parameter signed [15:0] DELTA_LO = 16'sd0,
    parameter integer        ITER     = 1
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
    wire sigma_hi = (abs_angle >= TH);
    wire sigma_lo = (abs_angle >= TL) && (abs_angle < TH);

    // --- Sine approximation ---
    // For ITER=1 (stage2): SA2=2^-2-2^-9, SA3=2^-3
    // For ITER>=2:         SA(2i)=2^-2i,  SA(2i+1)=2^-(2i+1)
    wire signed [15:0] y_sin_hi, y_sin_lo, x_sin_hi, x_sin_lo;

    generate
        if (ITER == 1) begin
            // SA2 (16-bit accuracy) = 2^-2 - 2^-9
            assign y_sin_hi = (y >>> 2) - (y >>> 9);
            assign x_sin_hi = (x >>> 2) - (x >>> 9);
            // SA3 = 2^-3
            assign y_sin_lo = y >>> 3;
            assign x_sin_lo = x >>> 3;
        end else begin
            assign y_sin_hi = y >>> (2*ITER);
            assign x_sin_hi = x >>> (2*ITER);
            assign y_sin_lo = y >>> (2*ITER + 1);
            assign x_sin_lo = x >>> (2*ITER + 1);
        end
    endgenerate

    wire signed [15:0] y_sin = sigma_hi ? y_sin_hi : sigma_lo ? y_sin_lo : 16'sd0;
    wire signed [15:0] x_sin = sigma_hi ? x_sin_hi : sigma_lo ? x_sin_lo : 16'sd0;

    // --- Cosine correction: CA = 1 - 2^-(4i+1) or 1 - 2^-(4i+3) ---
    wire signed [15:0] x_cos_corr_hi = x >>> (4*ITER + 1);
    wire signed [15:0] x_cos_corr_lo = x >>> (4*ITER + 3);
    wire signed [15:0] y_cos_corr_hi = y >>> (4*ITER + 1);
    wire signed [15:0] y_cos_corr_lo = y >>> (4*ITER + 3);

    wire signed [15:0] x_cos_corr = sigma_hi ? x_cos_corr_hi : sigma_lo ? x_cos_corr_lo : 16'sd0;
    wire signed [15:0] y_cos_corr = sigma_hi ? y_cos_corr_hi : sigma_lo ? y_cos_corr_lo : 16'sd0;

    wire signed [15:0] x_cos = x - x_cos_corr;
    wire signed [15:0] y_cos = y - y_cos_corr;

    // --- Rotation ---
    wire signed [15:0] x_next = sign ? (x_cos + y_sin) : (x_cos - y_sin);
    wire signed [15:0] y_next = sign ? (y_cos - x_sin) : (y_cos + x_sin);

    // --- Angle update ---
    wire signed [15:0] delta = sigma_hi ? DELTA_HI : sigma_lo ? DELTA_LO : 16'sd0;
    wire signed [15:0] angle_next = sign ? (angle + delta) : (angle - delta);

    // --- Pipeline register ---
    always @(posedge clk) begin
        x_out     <= x_next;
        y_out     <= y_next;
        angle_out <= angle_next;
    end
endmodule