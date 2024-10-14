% ======================================================================================
% fplib - gen_pkg.m
% --------------------------------------------------------------------------------------
% % Generates test_fplib_pkg.sv containing ranodmized parameters used in the SV TB
% --------------------------------------------------------------------------------------
% https://github.com/SkyworksSolutionsInc/fplib
% Copyright (c) 2024 Skyworks Inc.
% SPDX-License-Identifier: Apache-2.0
% ======================================================================================


clc;
clear;

n_fp_sets = 100; % number of fixed point formats to test
n_rand_nums = 25; % number of random numbers to test for each FP format
n_reals = 100; % # of constant reals to test
wl_min = 2; % min FP word length
wl_max = 28; % max FP word length

%%

fid = fopen('./test_fplib_pkg.sv','w+');
fprintf(fid, "// AUTO-GENERATED BY 'gen_pkg.m' - DO NOT MODIFY!\n\n");
fprintf(fid, "package test_fplib_pkg;\n");

fprintf(fid, "    localparam int n_fp_sets = %d; // # of fixed point formats to test\n", n_fp_sets);
fprintf(fid, "    localparam int n_rand_nums = %d; // # of random numbers to test for each FP format\n", n_rand_nums);

%% 

% generate more sets than we need and exclude the ones that produce > 50 
% fractional bits after sum/mult since this exceeds the double precision 
% of the ref model

n_gen = 2 * n_fp_sets; 
wl_in1 = randi([wl_min, wl_max], 1, n_gen);
iw_in1 = zeros(1, numel(wl_in1));
for i = 1:n_gen
    iw_in1(i) = randi([-wl_in1(i), wl_in1(i)], 1);
end
qw_in1 = wl_in1 - iw_in1;

wl_in2 = randi([wl_min, wl_max], 1, n_gen);
iw_in2 = zeros(1, numel(wl_in2));
for i = 1:n_gen
    iw_in2(i) = randi([-wl_in2(i), wl_in2(i)], 1);
end
qw_in2 = wl_in2 - iw_in2;
sum_qw = max(qw_in1, qw_in2) + 1; 
mult_qw = qw_in1 + qw_in2; 
exclude_idx = find(max(mult_qw, sum_qw) < 50);

iw_in1 = iw_in1(exclude_idx(1:n_fp_sets));
qw_in1 = qw_in1(exclude_idx(1:n_fp_sets));
wl_in1 = wl_in1(exclude_idx(1:n_fp_sets));

iw_in2 = iw_in2(exclude_idx(1:n_fp_sets));
qw_in2 = qw_in2(exclude_idx(1:n_fp_sets));
wl_in2 = wl_in2(exclude_idx(1:n_fp_sets));

fprintf(fid, "    localparam int iw_in1[n_fp_sets] = '{%s};\n", join(string(iw_in1), ', '));
fprintf(fid, "    localparam int qw_in1[n_fp_sets] = '{%s};\n", join(string(qw_in1), ', '));
fprintf(fid, "    localparam int wl_in1[n_fp_sets] = '{%s};\n", join(string(wl_in1), ', '));
fprintf(fid, "    localparam int iw_in2[n_fp_sets] = '{%s};\n", join(string(iw_in2), ', '));
fprintf(fid, "    localparam int qw_in2[n_fp_sets] = '{%s};\n", join(string(qw_in2), ', '));
fprintf(fid, "    localparam int wl_in2[n_fp_sets] = '{%s};\n", join(string(wl_in2), ', '));

wl_out = randi([wl_min, wl_max], 1, n_fp_sets);
iw_out = zeros(1, numel(wl_out));
for i = 1:n_fp_sets
    iw_out(i) = randi([-wl_out(i), wl_out(i)], 1);
end
qw_out = wl_out - iw_out;

fprintf(fid, "    localparam int iw_out[n_fp_sets] = '{%s};\n", join(string(iw_out), ', '));
fprintf(fid, "    localparam int qw_out[n_fp_sets] = '{%s};\n", join(string(qw_out), ', '));
fprintf(fid, "    localparam int wl_out[n_fp_sets] = '{%s};\n", join(string(wl_out), ', '));

%% 

wl_in1 = randi([wl_min, wl_max], 1, n_reals);
iw_in1 = zeros(1, numel(wl_in1));
for i = 1:n_reals
    iw_in1(i) = randi([-wl_in1(i), wl_in1(i)], 1);
end
qw_in1 = wl_in1 - iw_in1;

fprintf(fid, "    localparam int n_reals = %d; // # of constant reals to test \n", n_reals);

fprintf(fid, "    localparam int iw_r[n_reals] = '{%s};\n", join(string(iw_in1), ', '));
fprintf(fid, "    localparam int qw_r[n_reals] = '{%s};\n", join(string(qw_in1), ', '));
fprintf(fid, "    localparam int wl_r[n_reals] = '{%s};\n", join(string(wl_in1), ', '));

rand_s = zeros(1, numel(n_reals));
rand_u = zeros(1, numel(n_reals));
for i = 1:n_reals
    smin = -(2^(wl_in1(i)-1));
    smax =  (2^(wl_in1(i)-1)) - 1;
    umin = 0;
    umax = (2^wl_in1(i)) - 1;

    rand_s(i) = randi([smin, smax], 1);
    rand_s(i) = rand_s(i) / 2^qw_in1(i);
    rand_u(i) = randi([umin, umax], 1);
    rand_u(i) = rand_u(i) / 2^qw_in1(i);
end

fprintf(fid, "    localparam bit [63:0] ureals[n_reals] = '{%s};\n", join(compose("64'h%bx", rand_u), ', '));
fprintf(fid, "    localparam bit [63:0] sreals[n_reals] = '{%s};\n", join(compose("64'h%bx", rand_s), ', '));

fprintf(fid, "endpackage\n");