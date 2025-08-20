/*
 Copyright (C) 2020  Intel Corporation. All rights reserved.
 Your use of Intel Corporation's design tools, logic functions 
 and other software and tools, and any partner logic 
 functions, and any output files from any of the foregoing 
 (including device programming or simulation files), and any 
 associated documentation or information are expressly subject 
 to the terms and conditions of the Intel Program License 
 Subscription Agreement, the Intel Quartus Prime License Agreement,
 the Intel FPGA IP License Agreement, or other applicable license
 agreement, including, without limitation, that your use is for
 the sole purpose of programming logic devices manufactured by
 Intel and sold by Intel or its authorized distributors.  Please
 refer to the applicable agreement for further details, at
 https://fpgasoftware.intel.com/eula.
*/
MODEL
/*MODEL HEADER*/
/*
 This file contains Slow Corner delays for the design using part EP4CE22F17C6
 with speed grade 6, core voltage 1.2V, and temperature 85 Celsius

*/
MODEL_VERSION "1.0";
DESIGN "adder_32bit";
DATE "08/20/2025 15:35:49";
PROGRAM "Quartus Prime";



INPUT reset;
INPUT Cin;
INPUT clk;
INPUT num_b[0];
INPUT num_a[0];
INPUT num_b[1];
INPUT num_a[1];
INPUT num_b[2];
INPUT num_a[2];
INPUT num_b[3];
INPUT num_a[3];
INPUT num_a[4];
INPUT num_b[4];
INPUT num_a[5];
INPUT num_b[5];
INPUT num_b[6];
INPUT num_a[6];
INPUT num_b[7];
INPUT num_a[7];
INPUT num_a[8];
INPUT num_b[8];
INPUT num_a[9];
INPUT num_b[9];
INPUT num_b[10];
INPUT num_a[10];
INPUT num_a[11];
INPUT num_b[11];
INPUT num_b[12];
INPUT num_a[12];
INPUT num_a[13];
INPUT num_b[13];
INPUT num_a[14];
INPUT num_b[14];
INPUT num_b[15];
INPUT num_a[15];
INPUT num_a[16];
INPUT num_b[16];
INPUT num_a[17];
INPUT num_b[17];
INPUT num_b[18];
INPUT num_a[18];
INPUT num_b[19];
INPUT num_a[19];
INPUT num_b[20];
INPUT num_a[20];
INPUT num_a[21];
INPUT num_b[21];
INPUT num_b[22];
INPUT num_a[22];
INPUT num_a[23];
INPUT num_b[23];
INPUT num_a[24];
INPUT num_b[24];
INPUT num_a[25];
INPUT num_b[25];
INPUT num_a[26];
INPUT num_b[26];
INPUT num_a[27];
INPUT num_b[27];
INPUT num_a[28];
INPUT num_b[28];
INPUT num_b[29];
INPUT num_a[29];
INPUT num_b[30];
INPUT num_a[30];
INPUT num_b[31];
INPUT num_a[31];
OUTPUT sum[0];
OUTPUT sum[1];
OUTPUT sum[2];
OUTPUT sum[3];
OUTPUT sum[4];
OUTPUT sum[5];
OUTPUT sum[6];
OUTPUT sum[7];
OUTPUT sum[8];
OUTPUT sum[9];
OUTPUT sum[10];
OUTPUT sum[11];
OUTPUT sum[12];
OUTPUT sum[13];
OUTPUT sum[14];
OUTPUT sum[15];
OUTPUT sum[16];
OUTPUT sum[17];
OUTPUT sum[18];
OUTPUT sum[19];
OUTPUT sum[20];
OUTPUT sum[21];
OUTPUT sum[22];
OUTPUT sum[23];
OUTPUT sum[24];
OUTPUT sum[25];
OUTPUT sum[26];
OUTPUT sum[27];
OUTPUT sum[28];
OUTPUT sum[29];
OUTPUT sum[30];
OUTPUT sum[31];
OUTPUT Cout;

/*Arc definitions start here*/
pos_Cin__clk__setup:		SETUP (POSEDGE) Cin clk ;
pos_num_a[0]__clk__setup:		SETUP (POSEDGE) num_a[0] clk ;
pos_num_a[1]__clk__setup:		SETUP (POSEDGE) num_a[1] clk ;
pos_num_a[2]__clk__setup:		SETUP (POSEDGE) num_a[2] clk ;
pos_num_a[3]__clk__setup:		SETUP (POSEDGE) num_a[3] clk ;
pos_num_a[4]__clk__setup:		SETUP (POSEDGE) num_a[4] clk ;
pos_num_a[5]__clk__setup:		SETUP (POSEDGE) num_a[5] clk ;
pos_num_a[6]__clk__setup:		SETUP (POSEDGE) num_a[6] clk ;
pos_num_a[7]__clk__setup:		SETUP (POSEDGE) num_a[7] clk ;
pos_num_a[8]__clk__setup:		SETUP (POSEDGE) num_a[8] clk ;
pos_num_a[9]__clk__setup:		SETUP (POSEDGE) num_a[9] clk ;
pos_num_a[10]__clk__setup:		SETUP (POSEDGE) num_a[10] clk ;
pos_num_a[11]__clk__setup:		SETUP (POSEDGE) num_a[11] clk ;
pos_num_a[12]__clk__setup:		SETUP (POSEDGE) num_a[12] clk ;
pos_num_a[13]__clk__setup:		SETUP (POSEDGE) num_a[13] clk ;
pos_num_a[14]__clk__setup:		SETUP (POSEDGE) num_a[14] clk ;
pos_num_a[15]__clk__setup:		SETUP (POSEDGE) num_a[15] clk ;
pos_num_a[16]__clk__setup:		SETUP (POSEDGE) num_a[16] clk ;
pos_num_a[17]__clk__setup:		SETUP (POSEDGE) num_a[17] clk ;
pos_num_a[18]__clk__setup:		SETUP (POSEDGE) num_a[18] clk ;
pos_num_a[19]__clk__setup:		SETUP (POSEDGE) num_a[19] clk ;
pos_num_a[20]__clk__setup:		SETUP (POSEDGE) num_a[20] clk ;
pos_num_a[21]__clk__setup:		SETUP (POSEDGE) num_a[21] clk ;
pos_num_a[22]__clk__setup:		SETUP (POSEDGE) num_a[22] clk ;
pos_num_a[23]__clk__setup:		SETUP (POSEDGE) num_a[23] clk ;
pos_num_a[24]__clk__setup:		SETUP (POSEDGE) num_a[24] clk ;
pos_num_a[25]__clk__setup:		SETUP (POSEDGE) num_a[25] clk ;
pos_num_a[26]__clk__setup:		SETUP (POSEDGE) num_a[26] clk ;
pos_num_a[27]__clk__setup:		SETUP (POSEDGE) num_a[27] clk ;
pos_num_a[28]__clk__setup:		SETUP (POSEDGE) num_a[28] clk ;
pos_num_a[29]__clk__setup:		SETUP (POSEDGE) num_a[29] clk ;
pos_num_a[30]__clk__setup:		SETUP (POSEDGE) num_a[30] clk ;
pos_num_a[31]__clk__setup:		SETUP (POSEDGE) num_a[31] clk ;
pos_num_b[0]__clk__setup:		SETUP (POSEDGE) num_b[0] clk ;
pos_num_b[1]__clk__setup:		SETUP (POSEDGE) num_b[1] clk ;
pos_num_b[2]__clk__setup:		SETUP (POSEDGE) num_b[2] clk ;
pos_num_b[3]__clk__setup:		SETUP (POSEDGE) num_b[3] clk ;
pos_num_b[4]__clk__setup:		SETUP (POSEDGE) num_b[4] clk ;
pos_num_b[5]__clk__setup:		SETUP (POSEDGE) num_b[5] clk ;
pos_num_b[6]__clk__setup:		SETUP (POSEDGE) num_b[6] clk ;
pos_num_b[7]__clk__setup:		SETUP (POSEDGE) num_b[7] clk ;
pos_num_b[8]__clk__setup:		SETUP (POSEDGE) num_b[8] clk ;
pos_num_b[9]__clk__setup:		SETUP (POSEDGE) num_b[9] clk ;
pos_num_b[10]__clk__setup:		SETUP (POSEDGE) num_b[10] clk ;
pos_num_b[11]__clk__setup:		SETUP (POSEDGE) num_b[11] clk ;
pos_num_b[12]__clk__setup:		SETUP (POSEDGE) num_b[12] clk ;
pos_num_b[13]__clk__setup:		SETUP (POSEDGE) num_b[13] clk ;
pos_num_b[14]__clk__setup:		SETUP (POSEDGE) num_b[14] clk ;
pos_num_b[15]__clk__setup:		SETUP (POSEDGE) num_b[15] clk ;
pos_num_b[16]__clk__setup:		SETUP (POSEDGE) num_b[16] clk ;
pos_num_b[17]__clk__setup:		SETUP (POSEDGE) num_b[17] clk ;
pos_num_b[18]__clk__setup:		SETUP (POSEDGE) num_b[18] clk ;
pos_num_b[19]__clk__setup:		SETUP (POSEDGE) num_b[19] clk ;
pos_num_b[20]__clk__setup:		SETUP (POSEDGE) num_b[20] clk ;
pos_num_b[21]__clk__setup:		SETUP (POSEDGE) num_b[21] clk ;
pos_num_b[22]__clk__setup:		SETUP (POSEDGE) num_b[22] clk ;
pos_num_b[23]__clk__setup:		SETUP (POSEDGE) num_b[23] clk ;
pos_num_b[24]__clk__setup:		SETUP (POSEDGE) num_b[24] clk ;
pos_num_b[25]__clk__setup:		SETUP (POSEDGE) num_b[25] clk ;
pos_num_b[26]__clk__setup:		SETUP (POSEDGE) num_b[26] clk ;
pos_num_b[27]__clk__setup:		SETUP (POSEDGE) num_b[27] clk ;
pos_num_b[28]__clk__setup:		SETUP (POSEDGE) num_b[28] clk ;
pos_num_b[29]__clk__setup:		SETUP (POSEDGE) num_b[29] clk ;
pos_num_b[30]__clk__setup:		SETUP (POSEDGE) num_b[30] clk ;
pos_num_b[31]__clk__setup:		SETUP (POSEDGE) num_b[31] clk ;
pos_reset__clk__setup:		SETUP (POSEDGE) reset clk ;
pos_Cin__clk__hold:		HOLD (POSEDGE) Cin clk ;
pos_num_a[0]__clk__hold:		HOLD (POSEDGE) num_a[0] clk ;
pos_num_a[1]__clk__hold:		HOLD (POSEDGE) num_a[1] clk ;
pos_num_a[2]__clk__hold:		HOLD (POSEDGE) num_a[2] clk ;
pos_num_a[3]__clk__hold:		HOLD (POSEDGE) num_a[3] clk ;
pos_num_a[4]__clk__hold:		HOLD (POSEDGE) num_a[4] clk ;
pos_num_a[5]__clk__hold:		HOLD (POSEDGE) num_a[5] clk ;
pos_num_a[6]__clk__hold:		HOLD (POSEDGE) num_a[6] clk ;
pos_num_a[7]__clk__hold:		HOLD (POSEDGE) num_a[7] clk ;
pos_num_a[8]__clk__hold:		HOLD (POSEDGE) num_a[8] clk ;
pos_num_a[9]__clk__hold:		HOLD (POSEDGE) num_a[9] clk ;
pos_num_a[10]__clk__hold:		HOLD (POSEDGE) num_a[10] clk ;
pos_num_a[11]__clk__hold:		HOLD (POSEDGE) num_a[11] clk ;
pos_num_a[12]__clk__hold:		HOLD (POSEDGE) num_a[12] clk ;
pos_num_a[13]__clk__hold:		HOLD (POSEDGE) num_a[13] clk ;
pos_num_a[14]__clk__hold:		HOLD (POSEDGE) num_a[14] clk ;
pos_num_a[15]__clk__hold:		HOLD (POSEDGE) num_a[15] clk ;
pos_num_a[16]__clk__hold:		HOLD (POSEDGE) num_a[16] clk ;
pos_num_a[17]__clk__hold:		HOLD (POSEDGE) num_a[17] clk ;
pos_num_a[18]__clk__hold:		HOLD (POSEDGE) num_a[18] clk ;
pos_num_a[19]__clk__hold:		HOLD (POSEDGE) num_a[19] clk ;
pos_num_a[20]__clk__hold:		HOLD (POSEDGE) num_a[20] clk ;
pos_num_a[21]__clk__hold:		HOLD (POSEDGE) num_a[21] clk ;
pos_num_a[22]__clk__hold:		HOLD (POSEDGE) num_a[22] clk ;
pos_num_a[23]__clk__hold:		HOLD (POSEDGE) num_a[23] clk ;
pos_num_a[24]__clk__hold:		HOLD (POSEDGE) num_a[24] clk ;
pos_num_a[25]__clk__hold:		HOLD (POSEDGE) num_a[25] clk ;
pos_num_a[26]__clk__hold:		HOLD (POSEDGE) num_a[26] clk ;
pos_num_a[27]__clk__hold:		HOLD (POSEDGE) num_a[27] clk ;
pos_num_a[28]__clk__hold:		HOLD (POSEDGE) num_a[28] clk ;
pos_num_a[29]__clk__hold:		HOLD (POSEDGE) num_a[29] clk ;
pos_num_a[30]__clk__hold:		HOLD (POSEDGE) num_a[30] clk ;
pos_num_a[31]__clk__hold:		HOLD (POSEDGE) num_a[31] clk ;
pos_num_b[0]__clk__hold:		HOLD (POSEDGE) num_b[0] clk ;
pos_num_b[1]__clk__hold:		HOLD (POSEDGE) num_b[1] clk ;
pos_num_b[2]__clk__hold:		HOLD (POSEDGE) num_b[2] clk ;
pos_num_b[3]__clk__hold:		HOLD (POSEDGE) num_b[3] clk ;
pos_num_b[4]__clk__hold:		HOLD (POSEDGE) num_b[4] clk ;
pos_num_b[5]__clk__hold:		HOLD (POSEDGE) num_b[5] clk ;
pos_num_b[6]__clk__hold:		HOLD (POSEDGE) num_b[6] clk ;
pos_num_b[7]__clk__hold:		HOLD (POSEDGE) num_b[7] clk ;
pos_num_b[8]__clk__hold:		HOLD (POSEDGE) num_b[8] clk ;
pos_num_b[9]__clk__hold:		HOLD (POSEDGE) num_b[9] clk ;
pos_num_b[10]__clk__hold:		HOLD (POSEDGE) num_b[10] clk ;
pos_num_b[11]__clk__hold:		HOLD (POSEDGE) num_b[11] clk ;
pos_num_b[12]__clk__hold:		HOLD (POSEDGE) num_b[12] clk ;
pos_num_b[13]__clk__hold:		HOLD (POSEDGE) num_b[13] clk ;
pos_num_b[14]__clk__hold:		HOLD (POSEDGE) num_b[14] clk ;
pos_num_b[15]__clk__hold:		HOLD (POSEDGE) num_b[15] clk ;
pos_num_b[16]__clk__hold:		HOLD (POSEDGE) num_b[16] clk ;
pos_num_b[17]__clk__hold:		HOLD (POSEDGE) num_b[17] clk ;
pos_num_b[18]__clk__hold:		HOLD (POSEDGE) num_b[18] clk ;
pos_num_b[19]__clk__hold:		HOLD (POSEDGE) num_b[19] clk ;
pos_num_b[20]__clk__hold:		HOLD (POSEDGE) num_b[20] clk ;
pos_num_b[21]__clk__hold:		HOLD (POSEDGE) num_b[21] clk ;
pos_num_b[22]__clk__hold:		HOLD (POSEDGE) num_b[22] clk ;
pos_num_b[23]__clk__hold:		HOLD (POSEDGE) num_b[23] clk ;
pos_num_b[24]__clk__hold:		HOLD (POSEDGE) num_b[24] clk ;
pos_num_b[25]__clk__hold:		HOLD (POSEDGE) num_b[25] clk ;
pos_num_b[26]__clk__hold:		HOLD (POSEDGE) num_b[26] clk ;
pos_num_b[27]__clk__hold:		HOLD (POSEDGE) num_b[27] clk ;
pos_num_b[28]__clk__hold:		HOLD (POSEDGE) num_b[28] clk ;
pos_num_b[29]__clk__hold:		HOLD (POSEDGE) num_b[29] clk ;
pos_num_b[30]__clk__hold:		HOLD (POSEDGE) num_b[30] clk ;
pos_num_b[31]__clk__hold:		HOLD (POSEDGE) num_b[31] clk ;
pos_reset__clk__hold:		HOLD (POSEDGE) reset clk ;
pos_clk__Cout__delay:		DELAY (POSEDGE) clk Cout ;
pos_clk__sum[0]__delay:		DELAY (POSEDGE) clk sum[0] ;
pos_clk__sum[1]__delay:		DELAY (POSEDGE) clk sum[1] ;
pos_clk__sum[2]__delay:		DELAY (POSEDGE) clk sum[2] ;
pos_clk__sum[3]__delay:		DELAY (POSEDGE) clk sum[3] ;
pos_clk__sum[4]__delay:		DELAY (POSEDGE) clk sum[4] ;
pos_clk__sum[5]__delay:		DELAY (POSEDGE) clk sum[5] ;
pos_clk__sum[6]__delay:		DELAY (POSEDGE) clk sum[6] ;
pos_clk__sum[7]__delay:		DELAY (POSEDGE) clk sum[7] ;
pos_clk__sum[8]__delay:		DELAY (POSEDGE) clk sum[8] ;
pos_clk__sum[9]__delay:		DELAY (POSEDGE) clk sum[9] ;
pos_clk__sum[10]__delay:		DELAY (POSEDGE) clk sum[10] ;
pos_clk__sum[11]__delay:		DELAY (POSEDGE) clk sum[11] ;
pos_clk__sum[12]__delay:		DELAY (POSEDGE) clk sum[12] ;
pos_clk__sum[13]__delay:		DELAY (POSEDGE) clk sum[13] ;
pos_clk__sum[14]__delay:		DELAY (POSEDGE) clk sum[14] ;
pos_clk__sum[15]__delay:		DELAY (POSEDGE) clk sum[15] ;
pos_clk__sum[16]__delay:		DELAY (POSEDGE) clk sum[16] ;
pos_clk__sum[17]__delay:		DELAY (POSEDGE) clk sum[17] ;
pos_clk__sum[18]__delay:		DELAY (POSEDGE) clk sum[18] ;
pos_clk__sum[19]__delay:		DELAY (POSEDGE) clk sum[19] ;
pos_clk__sum[20]__delay:		DELAY (POSEDGE) clk sum[20] ;
pos_clk__sum[21]__delay:		DELAY (POSEDGE) clk sum[21] ;
pos_clk__sum[22]__delay:		DELAY (POSEDGE) clk sum[22] ;
pos_clk__sum[23]__delay:		DELAY (POSEDGE) clk sum[23] ;
pos_clk__sum[24]__delay:		DELAY (POSEDGE) clk sum[24] ;
pos_clk__sum[25]__delay:		DELAY (POSEDGE) clk sum[25] ;
pos_clk__sum[26]__delay:		DELAY (POSEDGE) clk sum[26] ;
pos_clk__sum[27]__delay:		DELAY (POSEDGE) clk sum[27] ;
pos_clk__sum[28]__delay:		DELAY (POSEDGE) clk sum[28] ;
pos_clk__sum[29]__delay:		DELAY (POSEDGE) clk sum[29] ;
pos_clk__sum[30]__delay:		DELAY (POSEDGE) clk sum[30] ;
pos_clk__sum[31]__delay:		DELAY (POSEDGE) clk sum[31] ;

ENDMODEL
