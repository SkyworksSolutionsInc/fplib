// ======================================================================================
// fplib - fixed point add/sub/mult followed by resizing
// --------------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------------
// https://github.com/SkyworksSolutionsInc/fplib
// Copyright (c) 2024 Skyworks Inc.
// SPDX-License-Identifier: Apache-2.0
// ======================================================================================

`include "fp_macros.svh"

// Addition of ufp signals followed by resizing (equivalant to ufp_add_full + ufp_resize_ind)
module ufp_add_ind # (
    parameter   clip = 1    // (if reducing iw) 0 = wrap, 1 = clip
)
(
    ufp.in      in1, in2,   // input ufp signal
    ufp.out     out,        // output ufp signal (= in1 + in2)
    output      clipping    // clipping indicator (active-high)
);

    ufp #(`add_iw(in1, in2), `add_qw(in1, in2)) sum();
    ufp_add_full u_add (in1, in2, sum);
    ufp_resize_ind # (.clip(clip)) u_resize (sum, out, clipping);

endmodule

// Addition of sfp signals followed by resizing (equivalant to sfp_add_full + sfp_resize_ind)
module sfp_add_ind # (
    parameter   clip = 1    // (if reducing iw) 0 = wrap, 1 = clip
)
(
    sfp.in      in1, in2,   // input sfp signal
    sfp.out     out,        // output sfp signal (= in1 + in2)
    output      clipping    // clipping indicator (active-high)
);
    sfp #(`add_iw(in1, in2), `add_qw(in1, in2)) sum();
    sfp_add_full u_add (in1, in2, sum);
    sfp_resize_ind # (.clip(clip)) u_resize (sum, out, clipping);

endmodule

// Subtraction of ufp signals followed by resizing (equivalant to ufp_sub_full + sfp_resize_ind)
module ufp_sub_ind # (
    parameter   clip = 1    // (if reducing iw) 0 = wrap, 1 = clip
)
(
    ufp.in      in1, in2,   // input ufp signal
    sfp.out     out,        // output sfp signal (= in1 - in2)
    output      clipping    // clipping indicator (active-high)
);
    sfp #(`add_iw(in1, in2), `add_qw(in1, in2)) sub();
    ufp_sub_full u_sub (in1, in2, sub);
    sfp_resize_ind # (.clip(clip)) u_resize (sub, out, clipping);

endmodule

// Subtraction of sfp signals followed by resizing (equivalant to sfp_sub_full + sfp_resize_ind)
module sfp_sub_ind # (
    parameter   clip = 1    // (if reducing iw) 0 = wrap, 1 = clip
)
(
    sfp.in      in1, in2,   // input sfp signal
    sfp.out     out,        // output sfp signal (= in1 - in2)
    output      clipping    // clipping indicator (active-high)
);
    sfp #(`add_iw(in1, in2), `add_qw(in1, in2)) sub();
    sfp_sub_full u_sub (in1, in2, sub);
    sfp_resize_ind # (.clip(clip)) u_resize (sub, out, clipping);

endmodule

// Multiplication of ufp signals followed by resizing (equivalant to ufp_mult_full + ufp_resize_ind)
module ufp_mult_ind # (
    parameter   clip = 1    // (if reducing iw) 0 = wrap, 1 = clip
)
(
    ufp.in      in1, in2,   // input ufp signal
    ufp.out     out,        // output ufp signal (= in1 * in2)
    output      clipping    // clipping indicator (active-high)
);
    ufp #(`mult_iw(in1, in2), `mult_qw(in1, in2)) prod();
    ufp_mult_full u_mult (in1, in2, prod);
    ufp_resize_ind # (.clip(clip)) u_resize (prod, out, clipping);

endmodule

// Multiplication of sfp signals followed by resizing (equivalant to sfp_mult_full + sfp_resize_ind)
module sfp_mult_ind # (
    parameter   clip = 1    // (if reducing iw) 0 = wrap, 1 = clip
)
(
    sfp.in      in1, in2,   // input sfp signal
    sfp.out     out,        // output sfp signal (= in1 * in2)
    output      clipping    // clipping indicator (active-high)
);
    sfp #(`mult_iw(in1, in2), `mult_qw(in1, in2)) prod();
    sfp_mult_full u_mult (in1, in2, prod);
    sfp_resize_ind # (.clip(clip)) u_resize (prod, out, clipping);

endmodule


// Addition of ufp signals followed by resizing (equivalant to ufp_add_full + ufp_resize)
module ufp_add # (
    parameter   clip = 0    // (if reducing iw) 0 = wrap, 1 = clip
)
(
    ufp.in      in1, in2,   // input ufp signal
    ufp.out     out         // output ufp signal (= in1 + in2)
);
    ufp_add_ind #(.clip(clip)) u_add_ind (.in1(in1), .in2(in2), .out(out), .clipping());

endmodule

// Addition of sfp signals followed by resizing (equivalant to sfp_add_full + sfp_resize)
module sfp_add # (
    parameter   clip = 0    // (if reducing iw) 0 = wrap, 1 = clip
)
(
    sfp.in      in1, in2,   // input sfp signal
    sfp.out     out         // output sfp signal (= in1 + in2)
);
    sfp_add_ind #(.clip(clip)) u_add_ind (.in1(in1), .in2(in2), .out(out), .clipping());

endmodule

// Subtraction of ufp signals followed by resizing (equivalant to ufp_sub_full + sfp_resize)
module ufp_sub # (
    parameter   clip = 0    // (if reducing iw) 0 = wrap, 1 = clip
)
(
    ufp.in      in1, in2,   // input ufp signal
    sfp.out     out         // output sfp signal (= in1 - in2)
);
    ufp_sub_ind #(.clip(clip)) u_sub_ind (.in1(in1), .in2(in2), .out(out), .clipping());

endmodule

// Subtraction of sfp signals followed by resizing (equivalant to sfp_sub_full + sfp_resize)
module sfp_sub # (
    parameter   clip = 0    // (if reducing iw) 0 = wrap, 1 = clip
)
(
    sfp.in      in1, in2,   // input sfp signal
    sfp.out     out         // output sfp signal (= in1 - in2)
);
    sfp_sub_ind #(.clip(clip)) u_sub_ind (.in1(in1), .in2(in2), .out(out), .clipping());

endmodule

// Multiplication of ufp signals followed by resizing (equivalant to ufp_mult_full + ufp_resize)
module ufp_mult # (
    parameter   clip = 0    // (if reducing iw) 0 = wrap, 1 = clip
)
(
    ufp.in      in1, in2,   // input ufp signal
    ufp.out     out         // output ufp signal (= in1 * in2)
);
    ufp_mult_ind #(.clip(clip)) u_mult_ind (.in1(in1), .in2(in2), .out(out), .clipping());

endmodule

// Multiplication of sfp signals followed by resizing (equivalant to sfp_mult_full + sfp_resize)
module sfp_mult # (
    parameter   clip = 0    // (if reducing iw) 0 = wrap, 1 = clip
)
(
    sfp.in      in1, in2,   // input sfp signal
    sfp.out     out         // output sfp signal (= in1 * in2)
);
    sfp_mult_ind #(.clip(clip)) u_mult_ind (.in1(in1), .in2(in2), .out(out), .clipping());

endmodule
