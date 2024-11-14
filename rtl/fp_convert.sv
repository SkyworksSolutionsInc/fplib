// ======================================================================================
// fplib - fixed point conversion modules
// --------------------------------------------------------------------------------------
//                                                                                                                                     --
// --------------------------------------------------------------------------------------
// https://github.com/SkyworksSolutionsInc/fplib
// Copyright (c) 2024 Skyworks Inc.
// SPDX-License-Identifier: Apache-2.0
// ======================================================================================

`include "fp_macros.svh"

// Convert a real parameter (constant) to a sfp signal by rounding.
// This module is typically synthesizable, but Cadence Genus might
// require this tcl command: "set_db hdl_enable_real_support true".
// Reals that are outside the range of the ufp would throw an $error().
module creal_to_sfp # (
    parameter real float = 0.0  // input real constant
)
(
    sfp.out  fp                 // output sfp signal
);
    localparam int out_wl = `fp_wl(fp);
    localparam longint ival = longint'(float * (2.0 ** `fp_qw(fp))); // rounds to nearest integer
    localparam longint top = 2 ** (out_wl - 1) - 1;
    localparam longint bot = -(2 ** (out_wl - 1));

    if ((ival <= top) && (ival >= bot))
        assign fp.val = out_wl'(ival);
    else
        $error("%m: real number %f does not fit in the fixed point format of the output!", float);

endmodule

// Convert a real parameter (constant) to a ufp signal by rounding.
// This module is typically synthesizable, but Cadence Genus might
// require this tcl command: "set_db hdl_enable_real_support true".
// Reals that are outside the range of the ufp would throw an $error().
module creal_to_ufp # (
    parameter real float = 0.0  // input real constant
)
(
    ufp.out  fp                 // output ufp signal
);
    localparam int out_wl = `fp_wl(fp);
    localparam longint ival = longint'(float * (2.0 ** `fp_qw(fp))); // rounds to nearest integer
    localparam longint top = 2 ** out_wl - 1;
    localparam longint bot = 'd0;

    if ((ival <= top) && (ival >= bot))
        assign fp.val = unsigned'(out_wl'(ival));
    else
        $error("%m: real number %f does not fit in the fixed point format of the output!", float);

endmodule


// Convert a real input to an sfp signal by rounding.
// Reals that are outside the range of the sfp would throw an $error().
// This module is NOT synthesizable!
module real_to_sfp
(
    input real   float,             // input real
    sfp.out      fp                 // output sfp signal
);
    localparam int out_wl = `fp_wl(fp);
    localparam longint top = 2 ** (out_wl - 1) - 1;
    localparam longint bot = -(2 ** (out_wl - 1));

    longint ival;

    always_comb begin
        ival = longint'(float * (2.0 ** `fp_qw(fp))); // rounds to nearest integer
        if ((ival <= top) && (ival >= bot))
            fp.val = out_wl'(ival);
        else begin
            $info("%d, %d, %d", ival, bot, top);
            $error("%m: real number %f does not fit in the %d.%d format of the output!", float, `fp_iw(fp), `fp_qw(fp));
        end
    end

endmodule


// Convert a real input to a ufp signal by rounding.
// Reals that are outside the range of the ufp would throw an $error().
// This module is NOT synthesizable!
module real_to_ufp
(
    input real   float,             // input real
    ufp.out      fp                 // output ufp signal
);
    localparam int out_wl = `fp_wl(fp);
    localparam longint top = 2 ** out_wl - 1;
    localparam longint bot = 'd0;

    longint ival;

    always_comb begin
        ival = longint'(float * (2.0 ** `fp_qw(fp))); // rounds to nearest integer
        if ((ival <= top) && (ival >= bot))
            fp.val = unsigned'(out_wl'(ival));
        else
            $error("%m: real number %f does not fit in the %d.%d format of the output!", float, `fp_iw(fp), `fp_qw(fp));
    end

endmodule


// Convert a ufp to an sfp by padding a 0 at the MSP as the sign bit.
// Output must have the same qw and one more iw than the input
module ufp_to_sfp_full
(
    ufp.in    in,        // input ufp signal
    sfp.out   out        // output sfp signal
);

    if ((`fp_iw(out) != `fp_iw(in) + 1) || (`fp_qw(out) != `fp_qw(in)))
        $error({"%m: Incorrect output word length for a full (exact) unsigned to signed conversion!",
                " Make sure out.iw = in.iw + 1 and out.qw = in.qw!"});

    assign out.val = $signed({1'b0, in.val});

endmodule

// Convert a sfp to a ufp:
// if clip = 1, clips negative numbers then drop the sign sign bit.
// if clip = 0, simply drops the sign bit.
// Output must have the same qw and one less iw than the input.
module sfp_to_ufp_full # (
    clip     = 0         // (if reducing iw) 0 = wrap, 1 = clip
)
(
    sfp.in    in,        // input sfp signal
    ufp.out   out,       // output ufp signal
    output    clipping   // clipping indicator (active-high)
);

    if ((`fp_iw(out) != `fp_iw(in) - 1) || (`fp_qw(out) != `fp_qw(in)))
        $error({"%m: Incorrect output word length for a full (exact) signed to unsigned conversion!",
                " Make sure out.iw = in.iw - 1 and out.qw = in.qw!"});

    if (clip)
        assign out.val = (in.val < 'sd0) ? 'd0 : in.val[`fp_wl(in) - 2:0];
    else
        assign out.val = in.val[`fp_wl(in) - 2:0];

    assign clipping = clip ? (in.val < 'sd0) : 1'b0;

endmodule

// Convert a ufp to a resized sfp (with a clipping indicator)
module ufp_to_sfp_ind # (
    clip      = 1        // (if reducing iw) 0 = wrap, 1 = clip
)
(
    ufp.in    in,        // input ufp signal
    sfp.out   out,       // output sfp signal
    output    clipping   // clipping indicator (active-high)
);
    sfp #(`fp_iw(in) + 1, `fp_qw(in)) tmp();
    ufp_to_sfp_full u_ufp_to_sfp_full (in, tmp);

    sfp_resize_ind #(.clip(clip)) u_resize (.in(tmp), .out(out), .clipping(clipping));

endmodule

// Convert a sfp to a resized ufp (with a clipping indicator)
module sfp_to_ufp_ind # (
    clip      = 1        // (if reducing iw) 0 = wrap, 1 = clip
)
(
    sfp.in    in,        // input sfp signal
    ufp.out   out,       // output ufp signal
    output    clipping   // clipping indicator (active-high)
);
    wire clip1, clip2;

    sfp #(`fp_iw(out) + 1, `fp_qw(out)) tmp();
    sfp_resize_ind #(.clip(clip)) u_resize (.in(in), .out(tmp), .clipping(clip1));

    sfp_to_ufp_full #(.clip(clip)) u_sfp_to_ufp_full (tmp, out, clip2);

    assign clipping = clip1 || clip2;

endmodule

// Convert a ufp to a resized sfp (without a clipping indicator)
module ufp_to_sfp # (
    clip     = 0         // (if reducing iw) 0 = wrap, 1 = clip
)
(
    ufp.in    in,        // input ufp signal
    sfp.out   out        // output sfp signal
);

    ufp_to_sfp_ind #(.clip(clip)) u_ufp_to_sfp_ind (.in(in), .out(out), .clipping());

endmodule

// Convert a sfp to a resized ufp (without a clipping indicator)
module sfp_to_ufp # (
    clip      = 0        // (if reducing iw) 0 = wrap, 1 = clip
)
(
    sfp.in    in,        // input sfp signal
    ufp.out   out        // output ufp signal
);

    sfp_to_ufp_ind #(.clip(clip)) u_sfp_to_ufp_ind (.in(in), .out(out), .clipping());

endmodule


