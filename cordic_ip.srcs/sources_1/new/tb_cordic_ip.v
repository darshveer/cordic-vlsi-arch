`timescale 1ns / 1ps

module tb_cordic_ip;

    reg clk;
    reg [18:0] angle_in;
    reg signed [15:0] x_in, y_in;

    wire signed [15:0] x_out, y_out;

    real cos_out, sin_out;

    top_cordic_ip DUT (
        .clk(clk),
        .angle_in(angle_in),
        .x_in(x_in),
        .y_in(y_in),
        .x_out(x_out),
        .y_out(y_out),
        .residual_angle()
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        x_in = 16'sd16384;  // unit vector
        y_in = 0;

        #50;

        $display("Deg | Cos(IP)  | Sin(IP)  | Error");

        test(0);
        test(30);
        test(45);
        test(60);
        test(90);

        #100 $finish;
    end

    task test(input integer deg);
        real rad;
        real scale;
    begin
        scale = 1.16443;

        angle_in = deg * 1024;

        repeat (40) @(posedge clk);
        #1;

        cos_out = (x_out / 16384.0) / scale;
        sin_out = (y_out / 16384.0) / scale;

        $display("%3d | %9.5f | %9.5f | %9.6f",
                 deg, cos_out, sin_out,
                 (cos_out*cos_out + sin_out*sin_out - 1.0));
    end
    endtask

endmodule