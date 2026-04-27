`timescale 1ns / 1ps

module cordic_preprocess (
    input  wire [18:0] theta_in,
    output reg  [15:0] theta_p,
    output reg         s,
    output reg         ns,
    output reg         nc
);
    localparam D_45  = 19'd46080;
    localparam D_90  = 19'd92160;
    localparam D_135 = 19'd138240;
    localparam D_180 = 19'd184320;
    localparam D_225 = 19'd230400;
    localparam D_270 = 19'd276480;
    localparam D_315 = 19'd322560;
    localparam D_360 = 19'd368640;

    always @(*) begin
        theta_p = 16'd0;
        s  = 1'b0;
        ns = 1'b0;
        nc = 1'b0;

        if      (theta_in <= D_45)  begin theta_p = theta_in[15:0];              s=0; ns=0; nc=0; end
        else if (theta_in <= D_90)  begin theta_p = D_90[15:0]  - theta_in[15:0]; s=1; ns=0; nc=0; end
        else if (theta_in <= D_135) begin theta_p = theta_in[15:0] - D_90[15:0];  s=1; ns=0; nc=1; end
        else if (theta_in <= D_180) begin theta_p = D_180[15:0] - theta_in[15:0]; s=0; ns=0; nc=1; end
        else if (theta_in <= D_225) begin theta_p = theta_in[15:0] - D_180[15:0]; s=0; ns=1; nc=1; end
        else if (theta_in <= D_270) begin theta_p = D_270[15:0] - theta_in[15:0]; s=1; ns=1; nc=1; end
        else if (theta_in <= D_315) begin theta_p = theta_in[15:0] - D_270[15:0]; s=1; ns=1; nc=0; end
        else if (theta_in <= D_360) begin theta_p = D_360[15:0] - theta_in[15:0]; s=0; ns=1; nc=0; end
    end
endmodule