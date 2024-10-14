// ======================================================================================
// fplib - integer clipping modules
// --------------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------------
// https://github.com/SkyworksSolutionsInc/fplib
// Copyright (c) 2024 Skyworks Inc.
// SPDX-License-Identifier: Apache-2.0
// ======================================================================================

// Reduce word length of the signed integer input, clipping values
// higher/lower than the output word length can fit.
module clip_signed # (
    parameter                   inw  = 0,   // input word length
    parameter                   outw = 0    // output word length
)
(
    input signed [inw-1:0]      in,         // input
    output signed [outw-1:0]    out,        // clipped output
    output                      clipping    // clipping indicator (active-high)
);

    // selects the bits that are to be checked for clipping (without the sign bit)
    wire [inw-2:outw-1] msbs = in[inw-2:outw-1];

    // the sign bit
    wire signbit = in[inw-1];

    // check if there was a positive or a negative clip
    wire positiveclip =  (|(msbs)) && !signbit;
    wire negativeclip = !(&(msbs)) && signbit;

    // full scale positive and negative value
    wire [outw-1:0] maxval = {1'b0, (outw-1)'('1)};  // 0111111...
    wire [outw-1:0] minval = {1'b1, (outw-1)'('0)};  // 1000000...

    // clipped value
    assign out = positiveclip ? maxval :
                 negativeclip ? minval : in[outw-1:0];

    // clipping indicator
    assign clipping = positiveclip || negativeclip;

endmodule

// Reduce word length of the unsigned integer input, clipping values
// higher/lower than the output word length can fit.
module clip_unsigned # (
    parameter                   inw  = 0,   // input word length
    parameter                   outw = 0    // output word length
)
(
    input [inw-1:0]      		in,         // input
    output [outw-1:0]    		out,        // clipped output
    output                      clipping    // clipping indicator (active-high)
);

    // selects the bits that are to be checked for clipping
    wire [inw-2:outw-1] msbs = in[inw-1:outw];

    // check if there was a positive clip
    assign clipping = |(msbs);

    // full scale positive value
    wire [outw-1:0] maxval = outw'('1);

    // clipped value
    assign out = clipping ? maxval : in[outw-1:0];

endmodule
