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
 This file contains Fast Corner delays for the design using part EP4CE22F17C8
 with speed grade M, core voltage 1.2V, and temperature 0 Celsius

*/
MODEL_VERSION "1.0";
DESIGN "fpu_qp";
DATE "12/28/2025 03:02:27";
PROGRAM "Quartus Prime";



INPUT RESET_N;
INPUT CLOCK_50;
INPUT UART_RX;
OUTPUT UART_TX;

/*Arc definitions start here*/
pos_RESET_N__CLOCK_50__setup:		SETUP (POSEDGE) RESET_N CLOCK_50 ;
pos_UART_RX__CLOCK_50__setup:		SETUP (POSEDGE) UART_RX CLOCK_50 ;
pos_RESET_N__CLOCK_50__hold:		HOLD (POSEDGE) RESET_N CLOCK_50 ;
pos_UART_RX__CLOCK_50__hold:		HOLD (POSEDGE) UART_RX CLOCK_50 ;
pos_CLOCK_50__UART_TX__delay:		DELAY (POSEDGE) CLOCK_50 UART_TX ;

ENDMODEL
