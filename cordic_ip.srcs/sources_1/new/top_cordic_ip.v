`timescale 1ns / 1ps

module top_cordic_ip (
    input  wire        clk,
    input  wire [18:0] angle_in,   // degrees * 1024
    input  wire signed [15:0] x_in,
    input  wire signed [15:0] y_in,

    output wire signed [15:0] x_out,
    output wire signed [15:0] y_out,
    output wire signed [15:0] residual_angle
);

    // -----------------------------
    // Convert degrees → radians (IP format)
    // radians_scaled = deg * π/180 * 8192
    // ≈ deg * 143 (precomputed constant scaling)
    // -----------------------------
    wire [15:0] phase_ip;
    assign phase_ip = (angle_in * 32'd143) >> 10;

    // -----------------------------
    // Pack Cartesian input
    // -----------------------------
    wire [31:0] cartesian_in;
    assign cartesian_in = {y_in, x_in};

    // -----------------------------
    // AXI control signals
    // -----------------------------
    reg tvalid = 0;

    always @(posedge clk) begin
        tvalid <= 1;  // always valid for continuous pipeline
    end

    // -----------------------------
    // IP Outputs
    // -----------------------------
    wire [31:0] dout;
    wire dout_valid;

    // -----------------------------
    // Instantiate Vivado IP
    // -----------------------------
    cordic_0 IP (
        .aclk(clk),

        .s_axis_phase_tvalid(tvalid),
        .s_axis_phase_tdata(phase_ip),

        .s_axis_cartesian_tvalid(tvalid),
        .s_axis_cartesian_tdata(cartesian_in),

        .m_axis_dout_tvalid(dout_valid),
        .m_axis_dout_tdata(dout)
    );

    // -----------------------------
    // Output unpack
    // -----------------------------
    assign y_out = dout[31:16];
    assign x_out = dout[15:0];
    
    // IP does not give residual angle
    assign residual_angle = 16'd0;

endmodule