// ================================================================================
// fplib - test bench                                                                                                                                           --
// --------------------------------------------------------------------------------
// uses the random fp formats defined in test_fplib_pkg.sv and compares the outputs
// of rtl/fp_*.sv modules against the quantize_real() reference model
// --------------------------------------------------------------------------------
// https://github.com/SkyworksSolutionsInc/fplib
// Copyright (c) 2024 Skyworks Inc.
// SPDX-License-Identifier: Apache-2.0
// ================================================================================

`include "fp_macros.svh"

// xrun -f test_fplib.f -top test_fplib -xmlibdirname ./build -vlogcontrolrelax NOTDOT -svseed random -access +rwc -input "@database -open -shm ./build/waves.shm -default" -input "@probe -create -all -depth all" -input "@run;" -input "@exit;"

import test_fplib_pkg::*;

`define ASSERT(cond)  assert(cond) begin n_asserts++; end else begin n_asserts++; n_failures++; end;

module test_fplib;

    // print final test results
    int n_asserts = 0;
    int n_failures = 0;
    initial begin
        #10000;
        if (n_failures == 0) $display("\n***** RESULTS: PASSED (%0d TESTS) *****\n", n_asserts);
        else $display("\n***** RESULTS: FAILED (%0d/%0d TESTS) *****\n", n_failures, n_asserts);
        $finish;
    end

    // reference model
    function real quantize_real(
        input real value, input int iw, input int qw, input int is_signed, input int clip
    );
        logic signed [100:0] ival, max_val, min_val;
        real out;

        ival = $floor(value * 2.0**qw);

        if (is_signed) begin
            max_val = (1 << (iw + qw - 1)) - 1;
            min_val = -(1 << (iw + qw - 1));
        end else begin
            max_val = (1 << (iw + qw)) - 1;
            min_val = 0;
        end

        if (clip) begin
            if (ival > max_val) begin
                ival = max_val;
            end else if (ival < min_val) begin
                ival = min_val;
            end
        end else begin
            ival = ival % (1 << (iw + qw));
            if (ival < 0) begin // make % behave like "floored" division modulo
                ival = ival + (1 << (iw + qw));
            end
            if ((is_signed) && (ival > max_val)) begin
                ival = ival - max_val + min_val - 1;
            end
        end

        out = real'(ival) * 2.0**(-qw);
        return out;
    endfunction

    initial begin
        $display("\n\n");
        $display("------------------------------------------------------");
        $display("------------------ REAL CONVERSIONS ------------------");
        $display("------------------------------------------------------");
    end

    for (genvar i = 0; i < n_reals; i++) begin
        sfp #(iw_r[i], qw_r[i]) s_from_real();
        ufp #(iw_r[i], qw_r[i]) u_from_real();
        sfp #(iw_r[i], qw_r[i]) s_from_creal();
        ufp #(iw_r[i], qw_r[i]) u_from_creal();

        real sreal = $bitstoreal(sreals[i]);
        real_to_sfp set_s_from_real (sreal, s_from_real);

        real ureal = $bitstoreal(ureals[i]);
        real_to_ufp set_u_from_real (ureal, u_from_real);

        creal_to_sfp #($bitstoreal(sreals[i])) set_s_from_creal (s_from_creal);
        creal_to_ufp #($bitstoreal(ureals[i])) set_u_from_creal (u_from_creal);

        initial begin
            #(1 + i * 10);
            $display("\n");
            $display("-----------------------------------------");
            $display("----------- FP FORMAT SET %2d ------------", i);
            $display("-----------------------------------------");

            $display("FP format       : %0d bits in Q%0d.%0d", wl_r[i], iw_r[i], qw_r[i]);
            $display("sreal           : %.10e", sreal);
            $display("s_from_real     : %.10e", s_from_real.fval);
            $display("s_from_creal    : %.10e", s_from_creal.fval);
            $display("ureal           : %.10e", ureal);
            $display("u_from_real     : %.10e", u_from_real.fval);
            $display("u_from_creal    : %.10e", u_from_creal.fval);
            check_s_from_real : `ASSERT(sreal == s_from_real.fval);
            check_u_from_real : `ASSERT(ureal == u_from_real.fval);
            check_s_from_creal : `ASSERT(sreal == s_from_creal.fval);
            check_u_from_creal : `ASSERT(ureal == u_from_creal.fval);
        end
    end

    initial begin
        #(1000);
        $display("\n\n");
        $display("------------------------------------------------------");
        $display("------------------- FP CONVERSIONS -------------------");
        $display("------------------------------------------------------");
    end

    for (genvar i = 0; i < n_fp_sets; i++) begin
        sfp #(iw_in1[i], qw_in1[i]) s();

        wire sclip_resize;
        sfp #(iw_out[i], qw_out[i]) so_resizew(), so_resizec();
        sfp_resize sfp_resize_inst (s, so_resizew);
        sfp_resize_ind sfp_resize_ind_inst (.in(s), .out(so_resizec), .clipping(sclip_resize));

        ufp #(iw_in1[i], qw_in1[i]) u();

        wire uclip_resize;
        ufp #(iw_out[i], qw_out[i]) uo_resizew(), uo_resizec();
        ufp_resize ufp_resize_inst (u, uo_resizew);
        ufp_resize_ind ufp_resize_ind_inst (.in(u), .out(uo_resizec), .clipping(uclip_resize));

        wire clip_s2u;
        ufp #(iw_out[i], qw_out[i]) uo_s2u_w(), uo_s2u_c();
        sfp_to_ufp sfp_to_ufp_inst (s, uo_s2u_w);
        sfp_to_ufp_ind sfp_to_ufp_ind_inst (.in(s), .out(uo_s2u_c), .clipping(clip_s2u));

        wire clip_u2s;
        sfp #(iw_out[i], qw_out[i]) so_u2s_w(), so_u2s_c();
        ufp_to_sfp ufp_to_sfp_inst (u, so_u2s_w);
        ufp_to_sfp_ind ufp_to_sfp_ind_inst (.in(u), .out(so_u2s_c), .clipping(clip_u2s));

        logic signed [wl_in1[i]-1:0] s_rand;
        logic [wl_in1[i]-1:0] u_rand;
        real s_randf, u_randf;
        real sm_resizec, sm_resizew, um_resizec, um_resizew;
        real um_s2u_c, um_s2u_w, sm_u2s_w, sm_u2s_c;

        initial begin
            #(1001 + i * 10);
            $display("\n");
            $display("-----------------------------------------");
            $display("----------- FP FORMAT SET %2d ------------", i);
            $display("-----------------------------------------");

            $display("in           : %0d bits in Q%0d.%0d", `fp_wl(s), `fp_iw(s), `fp_qw(s));
            $display("out          : %0d bits in Q%0d.%0d",  iw_out[i] + qw_out[i], iw_out[i], qw_out[i]);

            for (int j = 0; j < n_rand_nums; j++) begin
                assert(std::randomize(s_rand));
                s.val = s_rand;
                assert(std::randomize(u_rand));
                u.val = u_rand;
                #1;

                s_randf = `fp_to_float(s_rand, qw_in1[i]);
                u_randf = `fp_to_float(u_rand, qw_in1[i]);
                sm_resizec = quantize_real(s_randf, iw_out[i], qw_out[i], 1, 1);
                sm_resizew = quantize_real(s_randf, iw_out[i], qw_out[i], 1, 0);
                um_resizec = quantize_real(u_randf, iw_out[i], qw_out[i], 0, 1);
                um_resizew = quantize_real(u_randf, iw_out[i], qw_out[i], 0, 0);
                um_s2u_c = quantize_real(s_randf, iw_out[i], qw_out[i], 0, 1);
                um_s2u_w = quantize_real(s_randf, iw_out[i], qw_out[i], 0, 0);
                sm_u2s_c = quantize_real(u_randf, iw_out[i], qw_out[i], 1, 1);
                sm_u2s_w = quantize_real(u_randf, iw_out[i], qw_out[i], 1, 0);

                $display("-----------------------------------------");
                $display("RAND NUMBER %2d", j);

                $display("INPUT  - SIGNED - MODEL    : (int) %0d, (float) %.10e", s_rand, s_randf);
                $display("INPUT  - SIGNED - SIM      : (int) %0d, (float) %.10e", s.val, s.fval);
                $display("RESIZE - SIGNED - MODEL    : (clip) %.10e, (wrap) %.10e", sm_resizec, sm_resizew);
                $display("RESIZE - SIGNED - SIM      : (clip) %.10e, (wrap) %.10e", so_resizec.fval, so_resizew.fval);

                $display("INPUT  - UNSIGNED - MODEL  : (int) %0d, (float) %.10e", u_rand, u_randf);
                $display("INPUT  - UNSIGNED - SIM    : (int) %0d, (float) %.10e", u.val, u.fval);
                $display("RESIZE - UNSIGNED - MODEL  : (clip) %.10e, (wrap) %.10e", um_resizec, um_resizew);
                $display("RESIZE - UNSIGNED - SIM    : (clip) %.10e, (wrap) %.10e", uo_resizec.fval, uo_resizew.fval);

                check_signed_resize_clip : `ASSERT(sm_resizec == so_resizec.fval);
                check_signed_resize_wrap : `ASSERT(sm_resizew == so_resizew.fval);
                check_unsigned_resize_clip : `ASSERT(um_resizec == uo_resizec.fval);
                check_unsigned_resize_wrap : `ASSERT(um_resizew == uo_resizew.fval);

                $display("SIGNED TO UNSIGNED - MODEL : (clip) %.10e, (wrap) %.10e", um_s2u_c, um_s2u_w);
                $display("SIGNED TO UNSIGNED - SIM   : (clip) %.10e, (wrap) %.10e", uo_s2u_c.fval, uo_s2u_w.fval);
                $display("UNSIGNED TO SIGNED - MODEL : (clip) %.10e, (wrap) %.10e", sm_u2s_c, sm_u2s_w);
                $display("UNSIGNED TO SIGNED - SIM   : (clip) %.10e, (wrap) %.10e", so_u2s_c.fval, so_u2s_w.fval);

                check_sfp_to_ufp_clip : `ASSERT(um_s2u_c == uo_s2u_c.fval);
                check_sfp_to_ufp_wrap : `ASSERT(um_s2u_w == uo_s2u_w.fval);
                check_ufp_to_sfp_clip : `ASSERT(sm_u2s_c == so_u2s_c.fval);
                check_ufp_to_sfp_wrap : `ASSERT(sm_u2s_w == so_u2s_w.fval);
            end

            #10;
        end

    end

    initial begin
        #(2000);
        $display("\n\n");
        $display("------------------------------------------------------");
        $display("---------------------- FP MATH -----------------------");
        $display("------------------------------------------------------");
    end

    for (genvar i = 0; i < n_fp_sets; i++) begin
        sfp #(iw_in1[i], qw_in1[i]) s1();
        sfp #(iw_in2[i], qw_in2[i]) s2();
        ufp #(iw_in1[i], qw_in1[i]) u1();
        ufp #(iw_in2[i], qw_in2[i]) u2();

        wire sclip_add;
        sfp #(`add_iw(s1, s2), `add_qw(s1, s2)) so_addf();
        sfp #(iw_out[i], qw_out[i]) so_addw(), so_addc();
        sfp_add_full so_addf_inst (.in1(s1), .in2(s2), .out(so_addf));
        sfp_add so_addw_inst (.in1(s1), .in2(s2), .out(so_addw));
        sfp_add_ind so_addc_inst (.in1(s1), .in2(s2), .out(so_addc), .clipping(sclip_add));

        wire sclip_sub;
        sfp #(`add_iw(s1, s2), `add_qw(s1, s2)) so_subf();
        sfp #(iw_out[i], qw_out[i]) so_subw(), so_subc();
        sfp_sub_full so_subf_inst (.in1(s1), .in2(s2), .out(so_subf));
        sfp_sub so_subw_inst (.in1(s1), .in2(s2), .out(so_subw));
        sfp_sub_ind so_subc_inst (.in1(s1), .in2(s2), .out(so_subc), .clipping(sclip_sub));

        wire sclip_mult;
        sfp #(`mult_iw(s1, s2), `mult_qw(s1, s2)) so_multf();
        sfp #(iw_out[i], qw_out[i]) so_multw(), so_multc();
        sfp_mult_full so_multf_inst (.in1(s1), .in2(s2), .out(so_multf));
        sfp_mult so_multw_inst (.in1(s1), .in2(s2), .out(so_multw));
        sfp_mult_ind so_multc_inst (.in1(s1), .in2(s2), .out(so_multc), .clipping(sclip_mult));

        wire uclip_add;
        ufp #(`add_iw(u1, u2), `add_qw(u1, u2)) uo_addf();
        ufp #(iw_out[i], qw_out[i]) uo_addw(), uo_addc();
        ufp_add_full uo_addf_inst (.in1(u1), .in2(u2), .out(uo_addf));
        ufp_add uo_addw_inst (.in1(u1), .in2(u2), .out(uo_addw));
        ufp_add_ind uo_addc_inst (.in1(u1), .in2(u2), .out(uo_addc), .clipping(uclip_add));

        wire uclip_sub;
        sfp #(`add_iw(u1, u2), `add_qw(u1, u2)) uo_subf();
        sfp #(iw_out[i], qw_out[i]) uo_subw(), uo_subc();
        ufp_sub_full uo_subf_inst (.in1(u1), .in2(u2), .out(uo_subf));
        ufp_sub uo_subw_inst (.in1(u1), .in2(u2), .out(uo_subw));
        ufp_sub_ind uo_subc_inst (.in1(u1), .in2(u2), .out(uo_subc), .clipping(uclip_sub));

        wire uclip_mult;
        ufp #(`mult_iw(u1, u2), `mult_qw(u1, u2)) uo_multf();
        ufp #(iw_out[i], qw_out[i]) uo_multw(), uo_multc();
        ufp_mult_full uo_multf_inst (.in1(u1), .in2(u2), .out(uo_multf));
        ufp_mult uo_multw_inst (.in1(u1), .in2(u2), .out(uo_multw));
        ufp_mult_ind uo_multc_inst (.in1(u1), .in2(u2), .out(uo_multc), .clipping(uclip_mult));

        logic signed [wl_in1[i]-1:0] s1_rand;
        logic signed [wl_in2[i]-1:0] s2_rand;
        logic [wl_in1[i]-1:0] u1_rand;
        logic [wl_in2[i]-1:0] u2_rand;
        real s1_randf, s2_randf, u1_randf, u2_randf;
        real sm_addf, sm_addc, sm_addw, sm_subf, sm_subc, sm_subw, sm_multf, sm_multc, sm_multw;
        real um_addf, um_addc, um_addw, um_subf, um_subc, um_subw, um_multf, um_multc, um_multw;

        initial begin
            #(2001 + i * 100);
            $display("\n");
            $display("-----------------------------------------");
            $display("----------- FP FORMAT SET %2d ------------", i);
            $display("-----------------------------------------");

            $display("in1           : %0d bits in Q%0d.%0d", `fp_wl(s1), `fp_iw(s1), `fp_qw(s1));
            $display("in2           : %0d bits in Q%0d.%0d", `fp_wl(s2), `fp_iw(s2), `fp_qw(s2));
            $display("out           : %0d bits in Q%0d.%0d", `fp_wl(so_addc), `fp_iw(so_addc), `fp_qw(so_addc));
            $display("full add/sub  : %0d bits in Q%0d.%0d", `fp_wl(so_addf), `fp_iw(so_addf), `fp_qw(so_addf));
            $display("full mult     : %0d bits in Q%0d.%0d", `fp_wl(so_multf), `fp_iw(so_multf), `fp_qw(so_multf));

            for (int j = 0; j < n_rand_nums; j++) begin
                $display("-----------------------------------------");
                $display("RAND NUMBER %2d", j);

                assert(std::randomize(s1_rand));
                s1.val = s1_rand;
                assert(std::randomize(s2_rand));
                s2.val = s2_rand;
                assert(std::randomize(u1_rand));
                u1.val = u1_rand;
                assert(std::randomize(u2_rand));
                u2.val = u2_rand;
                #1;

                s2_randf = `fp_to_float(s2_rand, qw_in2[i]);
                s1_randf = `fp_to_float(s1_rand, qw_in1[i]);
                sm_addf = s1_randf + s2_randf;
                sm_addc = quantize_real(sm_addf, iw_out[i], qw_out[i], 1, 1);
                sm_addw = quantize_real(sm_addf, iw_out[i], qw_out[i], 1, 0);
                sm_subf = s1_randf - s2_randf;
                sm_subc = quantize_real(sm_subf, iw_out[i], qw_out[i], 1, 1);
                sm_subw = quantize_real(sm_subf, iw_out[i], qw_out[i], 1, 0);
                sm_multf = s1_randf * s2_randf;
                sm_multc = quantize_real(sm_multf, iw_out[i], qw_out[i], 1, 1);
                sm_multw = quantize_real(sm_multf, iw_out[i], qw_out[i], 1, 0);

                u2_randf = `fp_to_float(u2_rand, qw_in2[i]);
                u1_randf = `fp_to_float(u1_rand, qw_in1[i]);
                um_addf = u1_randf + u2_randf;
                um_addc = quantize_real(um_addf, iw_out[i], qw_out[i], 0, 1);
                um_addw = quantize_real(um_addf, iw_out[i], qw_out[i], 0, 0);
                um_subf = u1_randf - u2_randf;
                um_subc = quantize_real(um_subf, iw_out[i], qw_out[i], 1, 1);
                um_subw = quantize_real(um_subf, iw_out[i], qw_out[i], 1, 0);
                um_multf = u1_randf * u2_randf;
                um_multc = quantize_real(um_multf, iw_out[i], qw_out[i], 0, 1);
                um_multw = quantize_real(um_multf, iw_out[i], qw_out[i], 0, 0);

                $display("INPUT1 - SIGNED - MODEL : (int) %0d, (float) %.10e", s1_rand, s1_randf);
                $display("INPUT1 - SIGNED - SIM   : (int) %0d, (float) %.10e", s1.val, s1.fval);
                $display("INPUT2 - SIGNED - MODEL : (int) %0d, (float) %.10e", s2_rand, s2_randf);
                $display("INPUT2 - SIGNED - SIM   : (int) %0d, (float) %.10e", s2.val, s2.fval);

                $display("ADD    - SIGNED - MODEL : (full) %.10e, (clip) %.10e, (wrap) %.10e", sm_addf, sm_addc, sm_addw);
                $display("ADD    - SIGNED - SIM   : (full) %.10e, (clip) %.10e, (wrap) %.10e", so_addf.fval, so_addc.fval, so_addw.fval);
                check_signed_add_full : `ASSERT(sm_addf == so_addf.fval);
                check_signed_add_clip : `ASSERT(sm_addc == so_addc.fval);
                check_signed_add_wrap : `ASSERT(sm_addw == so_addw.fval);

                $display("SUB    - SIGNED - MODEL : (full) %.10e, (clip) %.10e, (wrap) %.10e", sm_subf, sm_subc, sm_subw);
                $display("SUB    - SIGNED - SIM   : (full) %.10e, (clip) %.10e, (wrap) %.10e", so_subf.fval, so_subc.fval, so_subw.fval);
                check_signed_sub_full : `ASSERT(sm_subf == so_subf.fval);
                check_signed_sub_clip : `ASSERT(sm_subc == so_subc.fval);
                check_signed_sub_wrap : `ASSERT(sm_subw == so_subw.fval);

                $display("MUL    - SIGNED - MODEL : (full) %.10e, (clip) %.10e, (wrap) %.10e", sm_multf, sm_multc, sm_multw);
                $display("MUL    - SIGNED - SIM   : (full) %.10e, (clip) %.10e, (wrap) %.10e", so_multf.fval, so_multc.fval, so_multw.fval);
                check_signed_mult_full : `ASSERT(sm_multf == so_multf.fval);
                check_signed_mult_clip : `ASSERT(sm_multc == so_multc.fval);
                check_signed_mult_wrap : `ASSERT(sm_multw == so_multw.fval);

                $display("---------------------------------");

                $display("INPUT1 - UNSIGNED - MODEL : (int) %0d, (float) %.10e", u1_rand, u1_randf);
                $display("INPUT1 - UNSIGNED - SIM   : (int) %0d, (float) %.10e", u1.val, u1.fval);
                $display("INPUT2 - UNSIGNED - MODEL : (int) %0d, (float) %.10e", u2_rand, u2_randf);
                $display("INPUT2 - UNSIGNED - SIM   : (int) %0d, (float) %.10e", u2.val, u2.fval);

                $display("ADD    - UNSIGNED - MODEL : (full) %.10e, (clip) %.10e, (wrap) %.10e", um_addf, um_addc, um_addw);
                $display("ADD    - UNSIGNED - SIM   : (full) %.10e, (clip) %.10e, (wrap) %.10e", uo_addf.fval, uo_addc.fval, uo_addw.fval);
                check_unsigned_add_full : `ASSERT(um_addf == uo_addf.fval);
                check_unsigned_add_clip : `ASSERT(um_addc == uo_addc.fval);
                check_unsigned_add_wrap : `ASSERT(um_addw == uo_addw.fval);

                $display("SUB    - UNSIGNED - MODEL : (full) %.10e, (clip) %.10e, (wrap) %.10e", um_subf, um_subc, um_subw);
                $display("SUB    - UNSIGNED - SIM   : (full) %.10e, (clip) %.10e, (wrap) %.10e", uo_subf.fval, uo_subc.fval, uo_subw.fval);
                check_unsigned_sub_full : `ASSERT(um_subf == uo_subf.fval);
                check_unsigned_sub_clip : `ASSERT(um_subc == uo_subc.fval);
                check_unsigned_sub_wrap : `ASSERT(um_subw == uo_subw.fval);

                $display("MUL    - UNSIGNED - MODEL : (full) %.10e, (clip) %.10e, (wrap) %.10e", um_multf, um_multc, um_multw);
                $display("MUL    - UNSIGNED - SIM   : (full) %.10e, (clip) %.10e, (wrap) %.10e", uo_multf.fval, uo_multc.fval, uo_multw.fval);
                check_unsigned_mult_full : `ASSERT(um_multf == uo_multf.fval);
                check_unsigned_mult_clip : `ASSERT(um_multc == uo_multc.fval);
                check_unsigned_mult_wrap : `ASSERT(um_multw == uo_multw.fval);
            end
        end
    end

endmodule
