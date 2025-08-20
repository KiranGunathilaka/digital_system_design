transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+D:/IntelFPGA/sem\ 5/sequence_detector {D:/IntelFPGA/sem 5/sequence_detector/overlapping_sequence_detector_0110.sv}
vlog -sv -work work +incdir+D:/IntelFPGA/sem\ 5/sequence_detector {D:/IntelFPGA/sem 5/sequence_detector/tb_overlapping_sequence_detector_0110.sv}

