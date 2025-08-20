transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work +incdir+D:/IntelFPGA/sem\ 5/UART {D:/IntelFPGA/sem 5/UART/uart_tx.sv}
vlog -sv -work work +incdir+D:/IntelFPGA/sem\ 5/UART {D:/IntelFPGA/sem 5/UART/uart_rx.sv}
vlog -sv -work work +incdir+D:/IntelFPGA/sem\ 5/UART {D:/IntelFPGA/sem 5/UART/uart.sv}
vlog -sv -work work +incdir+D:/IntelFPGA/sem\ 5/UART {D:/IntelFPGA/sem 5/UART/uart_tb.sv}

vlog -sv -work work +incdir+D:/IntelFPGA/sem\ 5/UART {D:/IntelFPGA/sem 5/UART/tranceiver_tb.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  transceiver_tb

add wave *
view structure
view signals
run -all
