// ================================================================================
// fplib - Example linear interp module which uses fplib
// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------
// https://github.com/SkyworksSolutionsInc/fplib
// Copyright (c) 2024 Skyworks Inc.
// SPDX-License-Identifier: Apache-2.0
// ================================================================================


// xrun -f ../rtl/fplib.f ./interp_fplib.sv -top top_interp_fplib -xmlibdirname ./build -vlogcontrolrelax NOTDOT -access +rwc -input "@database -open -shm ./build/waves.shm -default" -input "@probe -create -all -depth all" -input "@run;" -input "@exit;"

// performs m * x + b, where y, m, x, and b are arbitary FP numbers
module interp_fplib (
    sfp.in    m, x, b,    // input sfp signals
    sfp.out   y           // output sfp signal
);
    // define prod with the right format to hold m * x
    sfp #(`mult_iw(m, x), `mult_qw(m, x)) prod();

    // perform m * x = prod
    sfp_mult_full mult (m, x, prod);

    // perform prod + b and resize to fit the format of y
    sfp_add add (prod, b, y);

endmodule

module top_interp_fplib;

    parameter IW_M = 4;  parameter QW_M = 12; // m = 4.12
    parameter IW_X = 6;  parameter QW_X = 10; // x = 6.10
    parameter IW_B = 8;  parameter QW_B = 10; // b = 8.10
    parameter IW_Y = 8;  parameter QW_Y = 14; // y = 8.14

    // Input and output signals
    sfp #(IW_M, QW_M) m();
    sfp #(IW_X, QW_X) x();
    sfp #(IW_B, QW_B) b();
    sfp #(IW_Y, QW_Y) y();

    // Instantiate the linear_interp module
    interp_fplib u_interp (.m(m), .x(x), .b(b), .y(y));

    real_to_sfp u_set_m (1.5, m);
    real_to_sfp u_set_x (4.0, x);
    real_to_sfp u_set_b (3.125, b);

    initial begin
        #10;
        $display("y (int) = %d", y.val);
        $display("y (float) = %f", y.fval);
        $finish();
    end

endmodule


