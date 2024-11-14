// ================================================================================
// fplib - macro definitions                                                                                                                                           --
// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------
// https://github.com/SkyworksSolutionsInc/fplib
// Copyright (c) 2024 Skyworks Inc.
// SPDX-License-Identifier: Apache-2.0
// ================================================================================

`ifndef FP_MACROS
`define FP_MACROS

    `define fp_max(a,b)       (((a) > (b)) ? (a) : (b))

    // Access iw, qw, and wl parameters of a ufp / sfp :
    // Simulators cannot generally access interface parameters directly.
    // However, $bits() gets special treatment and its output can be used in
    // other constant expressions, so we encode parameters as the width of dummy
    // signals inside the interface and call $bits() to get to the values indirectly
    // For Xcelium, it might be required to pass the flag "-vlogcontrolrelax NOTDOT"
    // This is likely to work on other simulators as well, but YMMV
    // For Verilator, see https://github.com/verilator/verilator/issues/1593
    `define fp_qw(fp) ($bits(fp.dummy_qw)-1)
    `define fp_wl(fp) ($bits(fp.dummy_wl)-1)
    `define fp_iw(fp) (`fp_wl(fp)-`fp_qw(fp)) // doing this instead of ($bits(fp.dummy_iw)-1) to allow negative iw

    // calculate the # of bits needed to hold the full results of an add/sub/mult
    `define add_iw(fp1, fp2) (`fp_max(`fp_iw(fp1), `fp_iw(fp2)) + 1)
    `define add_qw(fp1, fp2) (`fp_max(`fp_qw(fp1), `fp_qw(fp2)))
    `define sub_iw(fp1, fp2) `add_iw(fp1, fp2)
    `define sub_qw(fp1, fp2) `add_qw(fp1, fp2)
    `define mult_iw(fp1, fp2) (`fp_iw(fp1) + `fp_iw(fp2))
    `define mult_qw(fp1, fp2) (`fp_qw(fp1) + `fp_qw(fp2))

    // 'real' representing an IEEE float NaN
    `define float_nan ($bitstoreal(64'hffffffffffffffff))

    // convert a fp.val to a 'real' (any X/Z bits result in a float NaN)
    `define fp_to_float(x, qw) ( $isunknown(x) ? `float_nan : real'(x) * (2.0 ** -real'(qw)) )

`endif
