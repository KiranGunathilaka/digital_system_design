###############################################################################
# Copyright (C) 1991-2025 Altera Corporation. All rights reserved.
# Any  megafunction  design,  and related netlist (encrypted  or  decrypted),
# support information,  device programming or simulation file,  and any other
# associated  documentation or information  provided by  Intel  or a partner
# under  Intel's   Megafunction   Partnership   Program  may  be  used  only
# to program  PLD  devices (but not masked  PLD  devices) from  Intel.   Any
# other  use  of such  megafunction  design,  netlist,  support  information,
# device programming or simulation file,  or any other  related documentation
# or information  is prohibited  for  any  other purpose,  including, but not
# limited to  modification,  reverse engineering,  de-compiling, or use  with
# any other  silicon devices,  unless such use is  explicitly  licensed under
# a separate agreement with  Intel  or a megafunction partner.  Title to the
# intellectual property,  including patents,  copyrights,  trademarks,  trade
# secrets,  or maskworks,  embodied in any such megafunction design, netlist,
# support  information,  device programming or simulation file,  or any other
# related documentation or information provided by  Intel  or a megafunction
# partner, remains with Intel, the megafunction partner, or their respective
# licensors. No other licenses, including any licenses needed under any third
# party's intellectual property, are provided herein.
#
###############################################################################


# FPGA Xchange file generated using Quartus Prime Version 20.1.1 Build 720 11/11/2020 SJ Lite Edition

# DESIGN=adder_32bit
# REVISION=adder_32bit
# DEVICE=EP4CE22
# PACKAGE=FBGA
# SPEEDGRADE=6

Signal Name,Pin Number,Direction,IO Standard,Drive (mA),Termination,Slew Rate,Swap Group,Diff Type

sum[0],B7,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[1],D1,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[2],F1,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[3],L13,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[4],K2,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[5],T10,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[6],A13,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[7],B16,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[8],A2,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[9],A15,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[10],B13,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[11],C11,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[12],B3,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[13],D11,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[14],A12,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[15],D9,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[16],N9,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[17],G1,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[18],A14,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[19],F15,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[20],J15,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[21],P8,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[22],N8,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[23],A3,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[24],L8,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[25],G5,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[26],B4,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[27],J16,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[28],R10,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[29],F13,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[30],R11,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
sum[31],R12,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
Cout,L15,output,2.5 V,Default,Series 50 Ohm without Calibration,FAST,swap_0,--
reset,B10,input,2.5 V,,Off,--,swap_1,--
clk,E1,input,2.5 V,,Off,--,swap_1,--
num_a[31],D14,input,2.5 V,,Off,--,swap_1,--
num_b[31],E11,input,2.5 V,,Off,--,swap_1,--
num_a[30],T11,input,2.5 V,,Off,--,swap_1,--
num_b[30],B12,input,2.5 V,,Off,--,swap_1,--
num_a[29],E10,input,2.5 V,,Off,--,swap_1,--
num_b[29],D15,input,2.5 V,,Off,--,swap_1,--
num_a[28],N16,input,2.5 V,,Off,--,swap_1,--
num_b[28],C15,input,2.5 V,,Off,--,swap_1,--
num_a[27],B14,input,2.5 V,,Off,--,swap_1,--
num_b[27],D12,input,2.5 V,,Off,--,swap_1,--
num_a[26],F14,input,2.5 V,,Off,--,swap_1,--
num_b[26],G15,input,2.5 V,,Off,--,swap_1,--
num_a[25],C14,input,2.5 V,,Off,--,swap_1,--
num_b[25],L14,input,2.5 V,,Off,--,swap_1,--
num_a[24],P9,input,2.5 V,,Off,--,swap_1,--
num_b[24],G16,input,2.5 V,,Off,--,swap_1,--
num_a[23],F2,input,2.5 V,,Off,--,swap_1,--
num_b[23],D16,input,2.5 V,,Off,--,swap_1,--
num_a[22],L7,input,2.5 V,,Off,--,swap_1,--
num_b[22],T7,input,2.5 V,,Off,--,swap_1,--
num_a[21],J1,input,2.5 V,,Off,--,swap_1,--
num_b[21],R8,input,2.5 V,,Off,--,swap_1,--
num_a[20],T8,input,2.5 V,,Off,--,swap_1,--
num_b[20],K15,input,2.5 V,,Off,--,swap_1,--
num_a[19],R9,input,2.5 V,,Off,--,swap_1,--
num_b[19],T9,input,2.5 V,,Off,--,swap_1,--
num_a[18],C9,input,2.5 V,,Off,--,swap_1,--
num_b[18],C8,input,2.5 V,,Off,--,swap_1,--
num_a[17],E7,input,2.5 V,,Off,--,swap_1,--
num_b[17],F3,input,2.5 V,,Off,--,swap_1,--
num_a[16],B11,input,2.5 V,,Off,--,swap_1,--
num_b[16],C16,input,2.5 V,,Off,--,swap_1,--
num_a[15],E9,input,2.5 V,,Off,--,swap_1,--
num_b[15],C3,input,2.5 V,,Off,--,swap_1,--
num_a[14],D6,input,2.5 V,,Off,--,swap_1,--
num_b[14],A11,input,2.5 V,,Off,--,swap_1,--
num_a[13],D5,input,2.5 V,,Off,--,swap_1,--
num_b[13],T12,input,2.5 V,,Off,--,swap_1,--
num_a[12],P11,input,2.5 V,,Off,--,swap_1,--
num_b[12],F9,input,2.5 V,,Off,--,swap_1,--
num_a[11],D8,input,2.5 V,,Off,--,swap_1,--
num_b[11],N15,input,2.5 V,,Off,--,swap_1,--
num_a[10],K16,input,2.5 V,,Off,--,swap_1,--
num_b[10],A10,input,2.5 V,,Off,--,swap_1,--
num_a[9],M2,input,2.5 V,,Off,--,swap_1,--
num_b[9],M1,input,2.5 V,,Off,--,swap_1,--
num_a[8],L16,input,2.5 V,,Off,--,swap_1,--
num_b[8],M8,input,2.5 V,,Off,--,swap_1,--
num_a[7],G2,input,2.5 V,,Off,--,swap_1,--
num_b[7],C6,input,2.5 V,,Off,--,swap_1,--
num_a[6],D3,input,2.5 V,,Off,--,swap_1,--
num_b[6],C2,input,2.5 V,,Off,--,swap_1,--
num_a[5],J13,input,2.5 V,,Off,--,swap_1,--
num_b[5],A5,input,2.5 V,,Off,--,swap_1,--
num_a[4],B6,input,2.5 V,,Off,--,swap_1,--
num_b[4],A7,input,2.5 V,,Off,--,swap_1,--
num_a[3],R7,input,2.5 V,,Off,--,swap_1,--
num_b[3],B1,input,2.5 V,,Off,--,swap_1,--
num_a[2],B5,input,2.5 V,,Off,--,swap_1,--
num_b[2],E8,input,2.5 V,,Off,--,swap_1,--
num_a[1],F8,input,2.5 V,,Off,--,swap_1,--
num_b[1],A6,input,2.5 V,,Off,--,swap_1,--
num_a[0],A4,input,2.5 V,,Off,--,swap_1,--
num_b[0],E6,input,2.5 V,,Off,--,swap_1,--
Cin,J14,input,2.5 V,,Off,--,swap_1,--
~ALTERA_ASDO_DATA1~,C1,input,2.5 V,,Off,--,NOSWAP,--
~ALTERA_FLASH_nCE_nCSO~,D2,input,2.5 V,,Off,--,NOSWAP,--
~ALTERA_DCLK~,H1,output,2.5 V,Default,Off,FAST,NOSWAP,--
~ALTERA_DATA0~,H2,input,2.5 V,,Off,--,NOSWAP,--
~ALTERA_nCEO~,F16,output,2.5 V,8,Off,FAST,NOSWAP,--
