// ================================================================================
// fplib - fixed point 'signal' (SV interface) definitions
// --------------------------------------------------------------------------------
//
// --------------------------------------------------------------------------------
// https://github.com/SkyworksSolutionsInc/fplib
// Copyright (c) 2024 Skyworks Inc.
// SPDX-License-Identifier: Apache-2.0
// ================================================================================

`include "fp_macros.svh"

// ufp 'signal' : unsigned fixed point scaler
interface ufp #(
    parameter int signed iw = 1,          // number of integer bits (sign bit included)
    parameter int unsigned qw = 1,        // number of fractional bits
    localparam int unsigned wl = iw + qw  // total number of bits
) ();
    logic [wl-1:0] val; // holds the fixed point scaler

    // SV limitation workaround:
    // create dummy signals for macros in fp_macros.svh to indirectly access qw/wl
    // and checked signedness (ufp vs sfp) during elaboration using $bits(dummy_*)
    // assigned value is only useful in waveform viewer for seeing the word lengths
    wire [qw:0] dummy_qw = (qw+1)'(qw);
    wire [wl:0] dummy_wl = (wl+1)'(wl);
    wire [1:0] dummy_signed = 2'b0;
    localparam is_signed = 0;

    `ifdef SYNTHESIS
        modport out       (output val, input dummy_qw, input dummy_wl, input dummy_signed);
        modport in        (input  val, input dummy_qw, input dummy_wl, input dummy_signed);
    `else
        real fval;
        assign fval = `fp_to_float(val, qw); // holds the read-only float representation
        modport out      (output val, input fval, input dummy_qw, input dummy_wl, input dummy_signed);
        modport in       (input  val, input fval, input dummy_qw, input dummy_wl, input dummy_signed);
    `endif
endinterface

// sfp 'signal': signed fixed point scaler
interface sfp #(
    parameter int signed iw = 1,          // number of integer bits (sign bit included)
    parameter int unsigned qw = 1,        // number of fractional bits
    localparam int unsigned wl = iw + qw  // total number of bits
) ();

    logic signed [wl-1:0] val; // holds the fixed point scaler

    wire [qw:0] dummy_qw = (qw+1)'(qw);
    wire [wl:0] dummy_wl = (wl+1)'(wl);
    wire dummy_signed = 1'b1;
    localparam is_signed = 1;

    `ifdef SYNTHESIS
        modport out       (output val, input dummy_qw, input dummy_wl, input dummy_signed);
        modport in        (input  val, input dummy_qw, input dummy_wl, input dummy_signed);
    `else
        real fval;
        assign fval = `fp_to_float(val, qw); // holds the read-only float representation
        modport out      (output val, input fval, input dummy_qw, input dummy_wl, input dummy_signed);
        modport in       (input  val, input fval, input dummy_qw, input dummy_wl, input dummy_signed);
    `endif

endinterface

// ufp_arr 'signal': unsigned fixed point 1D unpacked array
interface ufp_arr #(
    parameter int signed iw = 1,          // number of integer bits (sign bit included)
    parameter int unsigned qw = 1,        // number of fractional bits
    parameter int unsigned size = 1,      // array size
    localparam int unsigned wl = iw + qw  // total number of bits
) ();

    logic [wl-1:0] val [size]; // holds the fixed point array

    wire [qw:0] dummy_qw = (qw+1)'(qw);
    wire [wl:0] dummy_wl = (wl+1)'(wl);
    wire [1:0] dummy_signed = 2'b0;
    localparam is_signed = 0;

    `ifdef SYNTHESIS
        modport out       (output val, input dummy_qw, input dummy_wl, input dummy_signed);
        modport in        (input  val, input dummy_qw, input dummy_wl, input dummy_signed);
    `else
        real fval [size];
        always_comb for (int i = 0; i < size; i = i + 1)
            fval[i] = `fp_to_float(val[i], qw);
        modport out      (output val, input fval, input dummy_qw, input dummy_wl, input dummy_signed);
        modport in       (input  val, input fval, input dummy_qw, input dummy_wl, input dummy_signed);
    `endif
endinterface

// sfp_arr 'signal': signed fixed point 1D unpacked array
interface sfp_arr #(
    parameter int signed iw = 1,          // number of integer bits (sign bit included)
    parameter int unsigned qw = 1,        // number of fractional bits
    parameter int unsigned size = 1,      // array size
    localparam int unsigned wl = iw + qw  // total number of bits
) ();

    logic signed [wl-1:0] val [size]; // holds the fixed point array

    wire [qw:0] dummy_qw = (qw+1)'(qw);
    wire [wl:0] dummy_wl = (wl+1)'(wl);
    wire dummy_signed = 1'b1;
    localparam is_signed = 1;

    `ifdef SYNTHESIS
        modport out       (output val, input dummy_qw, input dummy_wl, input dummy_signed);
        modport in        (input  val, input dummy_qw, input dummy_wl, input dummy_signed);
    `else
        real fval [size];
        always_comb for (int i = 0; i < size; i = i + 1)
            fval[i] = `fp_to_float(val[i], qw);
        modport out      (output val, input fval, input dummy_qw, input dummy_wl, input dummy_signed);
        modport in       (input  val, input fval, input dummy_qw, input dummy_wl, input dummy_signed);
    `endif
endinterface

// ufp_arr2 'signal': unsigned fixed point 2D unpacked array
interface ufp_arr2 #(
    parameter int signed iw = 1,          // number of integer bits (sign bit included)
    parameter int unsigned qw = 1,        // number of fractional bits
    parameter int unsigned size1 = 1,     // array size - 1st unpacked dimention
    parameter int unsigned size2 = 1,     // array size - 2nd unpacked dimention
    localparam int unsigned wl = iw + qw  // total number of bits
) ();

    logic [wl-1:0] val [size1][size2]; // holds the fixed point array

    wire [qw:0] dummy_qw = (qw+1)'(qw);
    wire [wl:0] dummy_wl = (wl+1)'(wl);
    wire [1:0] dummy_signed = 2'b0;
    localparam is_signed = 0;

    `ifdef SYNTHESIS
        modport out       (output val, input dummy_qw, input dummy_wl, input dummy_signed);
        modport in        (input  val, input dummy_qw, input dummy_wl, input dummy_signed);
    `else
        real fval [size1][size2];
        always_comb
            for (int i = 0; i < size1; i = i + 1)
                for (int j = 0; j < size2; j = j + 1)
                    fval[i][j] = `fp_to_float(val[i][j], qw);
        modport out      (output val, input fval, input dummy_qw, input dummy_wl, input dummy_signed);
        modport in       (input  val, input fval, input dummy_qw, input dummy_wl, input dummy_signed);
    `endif
endinterface

// sfp_arr2 'signal': signed fixed point 2D unpacked array
interface sfp_arr2 #(
    parameter int signed iw = 1,          // number of integer bits (sign bit included)
    parameter int unsigned qw = 1,        // number of fractional bits
    parameter int unsigned size1 = 1,     // array size - 1st unpacked dimention
    parameter int unsigned size2 = 1,     // array size - 2nd unpacked dimention
    localparam int unsigned wl = iw + qw  // total number of bits
) ();

    logic signed [wl-1:0] val [size1][size2]; // holds the fixed point array

    wire [qw:0] dummy_qw = (qw+1)'(qw);
    wire [wl:0] dummy_wl = (wl+1)'(wl);
    wire dummy_signed = 1'b1;
    localparam is_signed = 1;

    `ifdef SYNTHESIS
        modport out       (output val, input dummy_qw, input dummy_wl, input dummy_signed);
        modport in        (input  val, input dummy_qw, input dummy_wl, input dummy_signed);
    `else
        real fval [size1][size2];
        always_comb
            for (int i = 0; i < size1; i = i + 1)
                for (int j = 0; j < size2; j = j + 1)
                    fval[i][j] = `fp_to_float(val[i][j], qw);
        modport out      (output val, input fval, input dummy_qw, input dummy_wl, input dummy_signed);
        modport in       (input  val, input fval, input dummy_qw, input dummy_wl, input dummy_signed);
    `endif
endinterface
