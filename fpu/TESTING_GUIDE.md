# UART Bridge Testing Guide

## Quick Reference

### Baud Rate Calculation Verification
- **Clock**: 50 MHz
- **Target Baud**: 115200
- **CLKS_PER_BIT**: 434 (rounded)
- **Actual Baud**: 115207.37 Hz
- **Error**: 0.0064% (well within ±2-5% UART tolerance)

### Pin Assignments (DE0-Nano)
- **UART_TX**: PIN_A2 (GPIO header)
- **UART_RX**: PIN_A3 (GPIO header)
- **CLOCK_50**: PIN_R8
- **RESET_N**: PIN_J15

### IO Standards
- **UART_TX**: 3.3-V LVTTL
- **UART_RX**: 3.3-V LVTTL (with weak pull-up)

## Testing Procedure

### Step 1: TX-Only Beacon Test (9600 baud)

1. **Modify `uart_beacon.v`**:
   ```verilog
   parameter integer BAUD = 9600
   ```

2. **Build**:
   ```bash
   quartus_sh --flow compile uart_beacon.qsf
   ```

3. **Program FPGA**:
   ```bash
   quartus_pgm -c usb-blaster -m jtag -o "p;output_files/uart_beacon.sof"
   ```

4. **Test**:
   ```bash
   # Open serial terminal at 9600 baud
   minicom -D /dev/ttyUSB0 -b 9600
   # Or use screen: screen /dev/ttyUSB0 9600
   ```

5. **Expected**: See `0x55` bytes every ~100ms

### Step 2: TX-Only Beacon Test (115200 baud)

1. **Modify `uart_beacon.v`**:
   ```verilog
   parameter integer BAUD = 115200
   ```

2. **Repeat Steps 2-4** from Step 1, but use 115200 baud in serial terminal

3. **Expected**: See `0x55` bytes every ~100ms at 115200 baud

### Step 3: Echo Test (9600 baud)

1. **Modify `uart_echo.v`**:
   ```verilog
   parameter integer BAUD = 9600
   ```

2. **Build**:
   ```bash
   quartus_sh --flow compile uart_echo.qsf
   ```

3. **Program FPGA** (similar to Step 1)

4. **Test**:
   ```bash
   # Open serial terminal at 9600 baud
   minicom -D /dev/ttyUSB0 -b 9600
   # Type characters - they should echo back
   ```

5. **Expected**: Every character typed is echoed back immediately

### Step 4: Echo Test (115200 baud)

1. **Modify `uart_echo.v`**:
   ```verilog
   parameter integer BAUD = 115200
   ```

2. **Repeat Steps 2-4** from Step 3, but use 115200 baud

3. **Expected**: Every character typed is echoed back immediately

### Step 5: Full Protocol Test

1. **Build main project**:
   ```bash
   quartus_sh --flow compile fpu_qp.qsf
   ```

2. **Program FPGA**

3. **Test with Python client**:
   ```bash
   python3 demo_serial.py /dev/ttyUSB0
   ```

4. **Expected Output**:
   ```
   junk= status=0x00 z=0x40400000 float=3.0
   ```
   (No junk bytes, correct result for 1.0 + 2.0 = 3.0)

## Troubleshooting

### Beacon Test Fails
- **No data received**: Check TX pin connection, IO standard, baud rate mismatch
- **Wrong data**: Check baud rate, verify pin assignment
- **Intermittent**: Check wire quality, ground connection

### Echo Test Fails
- **No echo**: Check RX pin connection, pull-up resistor, baud rate
- **Wrong echo**: Check baud rate, verify RX pin assignment
- **Missing bytes**: Check RX sampling, start bit detection

### Protocol Test Fails
- **Junk bytes**: Check both TX and RX pins, verify IO standards
- **Timeout**: Check protocol FSM, verify FPU is working
- **Wrong result**: Check FPU logic, verify data encoding

## Key Fixes Applied

1. ✅ IO Standard: Changed from 2.5V to 3.3-V LVTTL
2. ✅ Pull-up: Added weak pull-up on UART_RX
3. ✅ Baud Calculation: Fixed to use proper rounding
4. ✅ TX Timing: Fixed FSM to wait for transmission completion

## Files to Test

- `uart_beacon.v` + `uart_beacon.qsf` - TX-only test
- `uart_echo.v` + `uart_echo.qsf` - Echo test  
- `fpu_qp.v` + `fpu_qp.qsf` - Full protocol (with fixes)

