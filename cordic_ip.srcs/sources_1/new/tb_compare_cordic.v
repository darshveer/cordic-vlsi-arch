`timescale 1ns / 1ps

module tb_compare_cordic;

    reg clk;
    reg [18:0] angle_in;
    reg signed [15:0] x_in, y_in;

    wire signed [15:0] x_custom, y_custom;
    wire signed [15:0] x_ip, y_ip;

    real cos_c, sin_c, cos_ip, sin_ip;
    real scale_custom, scale_ip;

    // Custom CORDIC
    top_cordic CUSTOM (
        .clk(clk),
        .angle_in(angle_in),
        .x_in(x_in),
        .y_in(y_in),
        .x_out(x_custom),
        .y_out(y_custom),
        .residual_angle()
    );

    // IP CORDIC
    top_cordic_ip IP (
        .clk(clk),
        .angle_in(angle_in),
        .x_in(x_in),
        .y_in(y_in),
        .x_out(x_ip),
        .y_out(y_ip),
        .residual_angle()
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        // Prevent CORDIC gain overflow by leaving headroom
        x_in = 16'sd16384; 
        y_in = 0;
        
        // Custom CORDIC uses standard full gain
        scale_custom = 1; 
        // Vivado IP skips i=0 stage (1.64676 / sqrt(2))
        scale_ip     = 1.16443;     

        #100;

        // Expanded header to include Sine
        $display("Deg | Cos(Cust) | Cos(IP)   | Diff(Cos) | Sin(Cust) | Sin(IP)   | Diff(Sin)");

        test(0);
        test(30);
        test(45);
        test(60);
        test(90);

        #200 $finish;
    end

    task test(input integer deg);
    begin
        angle_in = deg * 1024;

        // Allow deep IP pipeline to fully settle
        repeat (40) @(posedge clk);
        #1;

        // Calculate Cosine (from x_out)
        cos_c  = (x_custom / 16384.0) / scale_custom;
        cos_ip = (x_ip / 16384.0) / scale_ip;

        // Calculate Sine (from y_out)
        sin_c  = (y_custom / 16384.0) / scale_custom;
        sin_ip = (y_ip / 16384.0) / scale_ip;

        // Expanded display statement
        $display("%3d | %9.5f | %9.5f | %9.6f | %9.5f | %9.5f | %9.6f",
                 deg, cos_c, cos_ip, (cos_c - cos_ip), sin_c, sin_ip, (sin_c - sin_ip));
    end
    endtask
    
endmodule