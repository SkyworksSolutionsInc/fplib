// ======================================================================================
// fplib - fixed point resize modules
// --------------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------------
// https://github.com/SkyworksSolutionsInc/fplib
// Copyright (c) 2024 Skyworks Inc.
// SPDX-License-Identifier: Apache-2.0
// ======================================================================================

`include "fp_macros.svh"

// Change the # of int/frac bits of a ufp signal (with a clipping indicator)
// - Decreasing # frac bits: truncates LSBs (floor toward -inf)
// - Increasing # frac bits: pads zero LSBs
// - Decreasing # int  bits: clips or drops MSBs depending on 'clip' parameter
// - Increasing # int  bits: pads zero MSBs (ufp) or sign-extends (sfp)
module ufp_resize_ind # (
    clip      = 1         // (if reducing iw) 0 = wrap, 1 = clip
)
(
    ufp.in    in,         // input ufp signal
    ufp.out   out,        // input ufp signal
    output    clipping    // clipping indicator (active-high)
);

    localparam iniw  = `fp_iw(in);
    localparam inqw  = `fp_qw(in);
    localparam inw   = `fp_wl(in);
    localparam outiw = `fp_iw(out);
    localparam outqw = `fp_qw(out);
    localparam outw  = `fp_wl(out);

    localparam tmp1w  = iniw+outqw;
    localparam tmp2w  = outiw+inqw;

    if (tmp1w > 1) begin : gen_case1
        logic [tmp1w-1:0] tmp1;
        // first handle the franctional bits by truncating LSBs or padding zeros
        if (inqw>=outqw) assign tmp1 = $unsigned(in.val[inw-1-:tmp1w]);
        else assign tmp1 = $unsigned({in.val, (outqw-inqw)'('b0)});
        // then handle the integer bits by clipping / discarding MSBs (may causing wrapping!), or sign extending MSBs
        if (iniw>outiw) begin
            if (clip) begin
                clip_unsigned #(.inw(tmp1w), .outw(outw)) u_clip (.in(tmp1), .out(out.val), .clipping(clipping));
            end else begin
                assign out.val = $unsigned(tmp1[outw-1:0]);
                assign clipping = 1'b0;
            end
        end else begin
            assign out.val = outw'(tmp1);
            assign clipping = 1'b0;
        end
    end else begin : gen_case2
        logic [tmp2w-1:0] tmp2;
        // first handle the integer bits by clipping / discarding MSBs (may causing wrapping!), or sign extending MSBs
        if (iniw>outiw) begin
            if (clip) begin
                clip_unsigned #(.inw(inw), .outw(tmp2w)) u_clip (.in(in.val), .out(tmp2), .clipping(clipping));
            end else begin
                assign tmp2 = $unsigned(in.val[tmp2w-1:0]);
                assign clipping = 1'b0;
            end
        end else begin
            assign tmp2 = tmp2w'(in.val);
            assign clipping = 1'b0;
        end
        // then handle the franctional bits by truncating LSBs or padding zeros
        if (inqw>=outqw) assign out.val = $unsigned(tmp2[tmp2w-1-:outw]);
        else assign out.val = $unsigned({tmp2, (outqw-inqw)'('b0)});
    end

endmodule

// Change the # of int/frac bits of a sfp signal (with a clipping indicator)
// - Decreasing # frac bits: truncates LSBs (floor toward -inf)
// - Increasing # frac bits: pads zero LSBs
// - Decreasing # int  bits: clips or drops MSBs depending on 'clip' parameter
// - Increasing # int  bits: pads zero MSBs (ufp) or sign-extends (sfp)
module sfp_resize_ind # (
    clip      = 1         // (if reducing iw) 0 = wrap, 1 = clip
)
(
    sfp.in    in,         // input sfp signal
    sfp.out   out,        // output sfp signal
    output    clipping    // clipping indicator (active-high)
);

    localparam iniw  = `fp_iw(in);
    localparam inqw  = `fp_qw(in);
    localparam inw   = `fp_wl(in);
    localparam outiw = `fp_iw(out);
    localparam outqw = `fp_qw(out);
    localparam outw  = `fp_wl(out);

    localparam tmp1w  = iniw+outqw;
    localparam tmp2w  = outiw+inqw;

    if (tmp1w > 1) begin : gen_case1
        logic signed [tmp1w-1:0] tmp1;
        // first handle the franctional bits by truncating LSBs or padding zeros
        if (inqw>=outqw) assign tmp1 = $signed(in.val[inw-1-:tmp1w]);
        else assign tmp1 = $signed({in.val, (outqw-inqw)'('b0)});
        // then handle the integer bits by clipping / discarding MSBs (may causing wrapping!), or sign extending MSBs
        if (iniw>outiw) begin
            if (clip) begin
                clip_signed #(.inw(tmp1w), .outw(outw)) u_clip (.in(tmp1), .out(out.val), .clipping(clipping));
            end else begin
                assign out.val = $signed(tmp1[outw-1:0]);
                assign clipping = 1'b0;
            end
        end else begin
            assign out.val = outw'(tmp1);
            assign clipping = 1'b0;
        end
    end else begin : gen_case2
        logic signed [tmp2w-1:0] tmp2;
        // first handle the integer bits by clipping / discarding MSBs (may causing wrapping!), or sign extending MSBs
        if (iniw>outiw) begin
            if (clip) begin
                clip_signed #(.inw(inw), .outw(tmp2w)) u_clip (.in(in.val), .out(tmp2), .clipping(clipping));
            end else begin
                assign tmp2 = $signed(in.val[tmp2w-1:0]);
                assign clipping = 1'b0;
            end
        end else begin
            assign tmp2 = tmp2w'(in.val);
            assign clipping = 1'b0;
        end
        // then handle the franctional bits by truncating LSBs or padding zeros
        if (inqw>=outqw) assign out.val = $signed(tmp2[tmp2w-1-:outw]);
        else assign out.val = $signed({tmp2, (outqw-inqw)'('b0)});
    end

endmodule

// Change the # of int/frac bits of a ufp signal (without a clipping indicator)
// - Decreasing # frac bits: truncates LSBs (floor toward -inf)
// - Increasing # frac bits: pads zero LSBs
// - Decreasing # int  bits: clips or drops MSBs depending on 'clip' parameter
// - Increasing # int  bits: pads zero MSBs (ufp) or sign-extends (sfp)
module ufp_resize # (
    clip      = 0        // (if reducing iw) 0 = wrap, 1 = clip
)
(
    ufp.in    in,        // input ufp signal
    ufp.out   out        // output ufp signal
);

    ufp_resize_ind #(.clip(clip)) u_resize_ind (.in(in), .out(out), .clipping());

endmodule

// Change the # of int/frac bits of a sfp signal (without a clipping indicator)
// - Decreasing # frac bits: truncates LSBs (floor toward -inf)
// - Increasing # frac bits: pads zero LSBs
// - Decreasing # int  bits: clips or drops MSBs depending on 'clip' parameter
// - Increasing # int  bits: pads zero MSBs (ufp) or sign-extends (sfp)
module sfp_resize # (
    clip      = 0        // (if reducing iw) 0 = wrap, 1 = clip
)
(
    sfp.in    in,        // input sfp signal
    sfp.out   out        // output sfp signal
);

    sfp_resize_ind #(.clip(clip)) u_resize_ind (.in(in), .out(out), .clipping());

endmodule
