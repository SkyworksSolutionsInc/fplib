// ================================================================================
// fplib - Example linear interp module which does not use fplib
// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------
// https://github.com/SkyworksSolutionsInc/fplib
// Copyright (c) 2024 Skyworks Inc.
// SPDX-License-Identifier: Apache-2.0
// ================================================================================


// xrun -f ../rtl/fplib.f ./interp_no_fplib.sv -top top_interp_no_fplib -xmlibdirname ./build -access +rwc -input "@database -open -shm ./build/waves.shm -default" -input "@probe -create -all -depth all" -input "@run;" -input "@exit;"

// performs m * x + b, where y, m, x, and b are arbitary fixed ponumbers
module interp_no_fplib #(
    parameter IW_M = 0, parameter QW_M = 0, // int/frac width of m
    parameter IW_X = 0, parameter QW_X = 0, // int/frac width of x
    parameter IW_B = 0, parameter QW_B = 0, // int/frac width of b
    parameter IW_Y = 0, parameter QW_Y = 0  // int/frac width of y
)(
    input  logic signed [IW_M + QW_M - 1:0] m,
    input  logic signed [IW_X + QW_X - 1:0] x,
    input  logic signed [IW_B + QW_B - 1:0] b,
    output logic signed [IW_Y + QW_Y - 1:0] y
);

    // determine FP format of prod = m * x and perform the mult
    localparam IW_PROD = IW_M + IW_X;
    localparam QW_PROD = QW_M + QW_X;
    wire signed [IW_PROD + QW_PROD - 1:0] prod = m * x;

    // determine FP format of sum = prod + b
    localparam IW_SUM = `fp_max(IW_PROD, IW_B) + 1;
    localparam QW_SUM = `fp_max(QW_PROD, QW_B);
    localparam WL_SUM = IW_SUM + QW_SUM;

    // align binary point of prod and b and perform sum = prod + b
    logic signed [WL_SUM - 1:0] b_aligned;
    logic signed [WL_SUM - 1:0] prod_aligned;

    if (QW_B >= QW_PROD) begin
        assign b_aligned = WL_SUM'(b);
        assign prod_aligned = WL_SUM'(prod) <<< (QW_B - QW_PROD);
    end else begin
        assign b_aligned = WL_SUM'(b) <<< (QW_PROD - QW_B);
        assign prod_aligned = WL_SUM'(prod);
    end
    wire signed [WL_SUM - 1:0] sum = prod_aligned + b_aligned;

    // match frac width of sum with y by truncating LSBs or adding zero LSBs
    logic signed [IW_SUM + QW_Y - 1:0] tmp;
    if (QW_SUM >= QW_Y) assign tmp = $signed(sum[(WL_SUM - 1)-:(IW_SUM + QW_Y)]);
    else assign tmp = $signed({sum, (QW_Y - QW_SUM)'('b0)});

    // then match the integer bits by discarding MSBs or sign extending
    if (IW_SUM >= IW_Y) assign y = $signed(tmp[(IW_Y + QW_Y - 1):0]);
    else assign y = (IW_Y + QW_Y)'(tmp);

endmodule


module top_interp_no_fplib;

    parameter IW_M = 4;  parameter QW_M = 12; // m = 4.12
    parameter IW_X = 6;  parameter QW_X = 10; // x = 6.10
    parameter IW_B = 8;  parameter QW_B = 10; // b = 8.10
    parameter IW_Y = 8;  parameter QW_Y = 14; // y = 8.14

    logic signed [IW_M + QW_M - 1:0] m;
    logic signed [IW_X + QW_X - 1:0] x;
    logic signed [IW_B + QW_B - 1:0] b;
    logic signed [IW_Y + QW_Y - 1:0] y;

    // Instantiate the linear_interp module
    interp_no_fplib #(
        .IW_M(IW_M), .QW_M(QW_M),
        .IW_X(IW_X), .QW_X(QW_X),
        .IW_B(IW_B), .QW_B(QW_B),
        .IW_Y(IW_Y), .QW_Y(QW_Y)
    ) u_interp (.m(m), .x(x), .b(b), .y(y));

    initial begin
        m = 1.5 * 2.0**QW_M;
        x = 4.0 * 2.0**QW_X;
        b = 3.125 * 2.0**QW_B;
        #10;
        $display("y (int) = %d", y);
        $display("y (float) = %f", real'(y) * 2.0**-QW_Y);
        $finish();
    end

endmodule
