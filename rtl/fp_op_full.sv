// ======================================================================================
// fplib - fixed point add / sub / mult (full precision)
// --------------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------------
// https://github.com/SkyworksSolutionsInc/fplib
// Copyright (c) 2024 Skyworks Inc.
// SPDX-License-Identifier: Apache-2.0
// ======================================================================================

`include "fp_macros.svh"

// Addition of ufp signals with full precision.
// Output must have the correct iw/qw for a full width operation:
// out.iw = max(in1.iw, in2.iw) + 1 and out.qw = max(in1.qw, in2.qw)
module ufp_add_full
(
    ufp.in      in1, in2,   // input ufp signal
    ufp.out     out         // output ufp signal (= in1 + in2)
);

    localparam iw_aligned = `fp_max(`fp_iw(in1),`fp_iw(in2));
    localparam qw_aligned = `fp_max(`fp_qw(in1),`fp_qw(in2));

    if ((`fp_iw(out) != iw_aligned + 1) || (`fp_qw(out) != qw_aligned))
        $error({"%m: Incorrect output word length for a full-width add!",
                "Make sure out.iw = max(in1.iw, in2.iw) + 1 and out.qw = max(in1.qw, in2.qw)!"});

    // resize in1 and in2 to have the same word length with an aligned binary point

    ufp #(iw_aligned, qw_aligned) in1_aligned(), in2_aligned();
    ufp_resize #(.clip(0)) u_resize_in1 (in1, in1_aligned);
    ufp_resize #(.clip(0)) u_resize_in2 (in2, in2_aligned);

    assign out.val = (in1_aligned.val) + (in2_aligned.val);

endmodule

// Addition of sfp signals with full precision.
// Output must have the correct iw/qw for a full width operation:
// out.iw = max(in1.iw, in2.iw) + 1 and out.qw = max(in1.qw, in2.qw)
module sfp_add_full
(
    sfp.in      in1, in2,   // input sfp signal
    sfp.out     out         // output sfp signal (= in1 + in2)
);

    localparam iw_aligned = `fp_max(`fp_iw(in1),`fp_iw(in2));
    localparam qw_aligned = `fp_max(`fp_qw(in1),`fp_qw(in2));

    if ((`fp_iw(out) != iw_aligned + 1) || (`fp_qw(out) != qw_aligned))
        $error({"%m: Incorrect output word length for a full-width add!",
                "Make sure out.iw = max(in1.iw, in2.iw) + 1 and out.qw = max(in1.qw, in2.qw)!"});

    // resize in1 and in2 to have the same word length with an aligned binary point

    sfp #(iw_aligned, qw_aligned) in1_aligned(), in2_aligned();
    sfp_resize #(.clip(0)) u_resize_in1 (in1, in1_aligned);
    sfp_resize #(.clip(0)) u_resize_in2 (in2, in2_aligned);

    assign out.val = (in1_aligned.val) + (in2_aligned.val);

endmodule

// Subtraction of ufp signals with full precision.
// Output must have the correct iw/qw for a full width operation:
// out.iw = max(in1.iw, in2.iw) + 1 and out.qw = max(in1.qw, in2.qw)
module ufp_sub_full
(
    ufp.in      in1, in2,   // input ufp signal
    sfp.out     out         // output sfp signal (= in1 - in2)
);

    localparam iw_aligned = `fp_max(`fp_iw(in1),`fp_iw(in2));
    localparam qw_aligned = `fp_max(`fp_qw(in1),`fp_qw(in2));

    if ((`fp_iw(out) != iw_aligned + 1) || (`fp_qw(out) != qw_aligned))
        $error({"%m: Incorrect output word length for a full-width subtract!",
                "Make sure out.iw = max(in1.iw, in2.iw) + 1 and out.qw = max(in1.qw, in2.qw)!"});

    // resize in1 and in2 to have the same word length with an aligned binary point

    ufp #(iw_aligned, qw_aligned) in1_aligned(), in2_aligned();
    ufp_resize #(.clip(0)) u_resize_in1 (in1, in1_aligned);
    ufp_resize #(.clip(0)) u_resize_in2 (in2, in2_aligned);

    assign out.val = (in1_aligned.val) - (in2_aligned.val);

endmodule

// Subtraction of sfp signals with full precision.
// Output must have the correct iw/qw for a full width operation:
// out.iw = max(in1.iw, in2.iw) + 1 and out.qw = max(in1.qw, in2.qw)
module sfp_sub_full
(
    sfp.in      in1, in2,   // input sfp signal
    sfp.out     out         // output sfp signal (= in1 - in2)
);

    localparam iw_aligned = `fp_max(`fp_iw(in1),`fp_iw(in2));
    localparam qw_aligned = `fp_max(`fp_qw(in1),`fp_qw(in2));

    if ((`fp_iw(out) != iw_aligned + 1) || (`fp_qw(out) != qw_aligned))
        $error({"%m: Incorrect output word length for a full-width subtract!",
                "Make sure out.iw = max(in1.iw, in2.iw) + 1 and out.qw = max(in1.qw, in2.qw)!"});

    // resize in1 and in2 to have the same word length with an aligned binary point

    sfp #(iw_aligned, qw_aligned) in1_aligned(), in2_aligned();
    sfp_resize #(.clip(0)) u_resize_in1 (in1, in1_aligned);
    sfp_resize #(.clip(0)) u_resize_in2 (in2, in2_aligned);

    assign out.val = (in1_aligned.val) - (in2_aligned.val);

endmodule

// Multiplication of ufp signals with full precision.
// Output must have the correct iw/qw for a full width operation:
// out.iw = in1.iw + in2.iw and out.qw = in1.qw + in2.qw
module ufp_mult_full
(
    ufp.in      in1, in2,   // input ufp signal
    ufp.out     out         // output ufp signal (= in1 * in2)
);

    if ((`fp_iw(in1) + `fp_iw(in2) != `fp_iw(out)) || (`fp_qw(in1) + `fp_qw(in2) != `fp_qw(out)))
        $error({"%m: Incorrect output word length for a full-width mult!",
               "Make sure out.iw = in1.iw + in2.iw and out.qw = in1.qw + in2.qw"});

    assign out.val = (in1.val) * (in2.val);

endmodule

// Multiplication of sfp signals with full precision.
// Output must have the correct iw/qw for a full width operation:
// out.iw = in1.iw + in2.iw and out.qw = in1.qw + in2.qw
module sfp_mult_full
(
    sfp.in      in1, in2,   // input sfp signal
    sfp.out     out         // output sfp signal (= in1 * in2)
);

    if ((`fp_iw(in1) + `fp_iw(in2) != `fp_iw(out)) || (`fp_qw(in1) + `fp_qw(in2) != `fp_qw(out)))
        $error({"%m: Incorrect output word length for a full-width mult!",
               "Make sure out.iw = in1.iw + in2.iw and out.qw = in1.qw + in2.qw"});

    assign out.val = (in1.val) * (in2.val);

endmodule