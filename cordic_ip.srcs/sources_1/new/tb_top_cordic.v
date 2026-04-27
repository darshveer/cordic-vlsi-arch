`timescale 1ns / 1ps

module tb_top_cordic;

    reg         clk;
    reg  [18:0] angle_in;
    reg  signed [15:0] x_in, y_in;

    wire signed [15:0] x_out, y_out, residual_angle;

    // 10 ns clock
    initial clk = 0;
    always #5 clk = ~clk;

    top_cordic DUT (
        .clk(clk),
        .angle_in(angle_in),
        .x_in(x_in),
        .y_in(y_in),
        .residual_angle(residual_angle),
        .x_out(x_out),
        .y_out(y_out)
    );

    real theta_deg, theta_rad;
    real cos_ref, sin_ref;
    real cos_hw, sin_hw;

    integer i;
    localparam SCALE = 4096;  // Q4.12 for x/y vectors

    initial begin
        $display("angle_deg | cos_hw   | cos_ref  | sin_hw   | sin_ref  | err_cos   | err_sin");

        x_in = SCALE;   // unit vector (cos=1, sin=0 initial)
        y_in = 0;

        // sweep 0 to 360 degrees in steps of 5 degrees
        for (i = 0; i <= 360; i = i + 5) begin
            // fixed-point: angle = degrees * 1024
            angle_in = i * 1024;

            // Wait 5 pipeline stages + a few extra cycles to flush
            repeat (8) @(posedge clk);
            #1; // small settle time after clock edge

            theta_deg = i;
            theta_rad = theta_deg * 3.14159265358979 / 180.0;

            cos_ref = $cos(theta_rad);
            sin_ref = $sin(theta_rad);

            cos_hw  = $itor($signed(x_out)) / SCALE;
            sin_hw  = $itor($signed(y_out)) / SCALE;

            $display("%9.1f | %8.5f | %8.5f | %8.5f | %8.5f | %9.6f | %9.6f",
                theta_deg, cos_hw, cos_ref, sin_hw, sin_ref,
                cos_hw - cos_ref, sin_hw - sin_ref);
        end

        $finish;
    end

endmodule