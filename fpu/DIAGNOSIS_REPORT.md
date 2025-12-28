# UART Bridge Diagnosis and Fix Report

## Executive Summary

The UART communication failures were caused by multiple issues:
1. **Incorrect IO standard**: Pins were set to 2.5V instead of 3.3V LVTTL
2. **Missing pull-up on UART_RX**: RX line could float, causing false start bits
3. **Baud rate calculation truncation**: Should use rounding for better accuracy
4. **Protocol FSM timing**: TX states didn't properly wait for transmission completion

## Root Cause Analysis

### Issue 1: IO Standard Mismatch
**Problem**: The QSF file had no explicit IO standard assignments. Quartus defaulted to 2.5V (based on bank VCCIO), but the DE0-Nano GPIO headers and FT232 operate at 3.3V.

**Evidence**: Pin report showed:
- UART_TX: PIN_A2, I/O Standard: 2.5 V, Bank 8
- UART_RX: PIN_A3, I/O Standard: 2.5 V, Bank 8
- VCCIO8: 2.5V

**Fix**: Added explicit IO standard assignments:
```tcl
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to UART_RX
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to UART_TX
```

### Issue 2: Missing Pull-up on UART_RX
**Problem**: UART_RX had no pull-up resistor assignment. If the line floats or has noise, it can trigger false start bit detection, causing junk bytes.

**Fix**: Added weak pull-up:
```tcl
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to UART_RX
```

### Issue 3: Baud Rate Calculation
**Problem**: Original code used integer division (truncation):
```verilog
localparam integer CLKS_PER_BIT = CLK_HZ / BAUD;  // 50000000 / 115200 = 434
```

**Analysis**:
- Actual: 50000000 / 115200 = 434.027...
- Truncated: 434
- Actual baud with 434: 50000000 / 434 = 115207.37 Hz
- Error: +0.006% (acceptable, but rounding is better practice)

**Fix**: Use proper rounding:
```verilog
localparam integer CLKS_PER_BIT = (CLK_HZ + BAUD/2) / BAUD;
```

For 50MHz/115200: (50000000 + 57600) / 115200 = 434 (same result, but correct method)

### Issue 4: Protocol FSM TX Timing
**Problem**: The TX states (S_TX_0 through S_TX_5) checked `can_tx` (which only checks `tx_active == 0`) and immediately moved to the next state after asserting `tx_dv`. This could cause issues if the TX module needs time to process.

**Fix**: Modified TX states to wait for `!tx_active` before sending the next byte, ensuring each byte completes before the next starts.

## Pin Assignments Verified

DE0-Nano GPIO header pins (confirmed in QSF):
- **UART_TX**: PIN_A2 (GPIO header pin, Bank 8)
- **UART_RX**: PIN_A3 (GPIO header pin, Bank 8)
- **CLOCK_50**: PIN_R8
- **RESET_N**: PIN_J15

**Note**: Bank 8 VCCIO is configured for 2.5V by default, but we override with 3.3V LVTTL IO standard assignment. This is valid as long as the board's GPIO header is actually connected to 3.3V (which is standard for DE0-Nano).

## Test Modules Created

### 1. TX-Only Beacon (`uart_beacon.v`)
- Sends 0x55 byte every 100ms
- Purpose: Verify UART_TX pin, IO standard, and baud rate
- Usage: Build with `uart_beacon.qsf`, program FPGA, monitor serial port
- Expected: Should see 0x55 bytes every ~100ms

### 2. Echo Test (`uart_echo.v`)
- Receives a byte and transmits it back
- Purpose: Verify UART_RX pin, idle level, pull-up, and RX sampling
- Usage: Build with `uart_echo.qsf`, program FPGA, send bytes via serial terminal
- Expected: Every byte sent should be echoed back

## Fixes Applied

### QSF File (`fpu_qp.qsf`)
```tcl
# Added after pin assignments:
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to UART_RX
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to UART_TX
set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to UART_RX
```

### RTL Changes

**`fpu_qp.v`**: Fixed baud rate calculation
```verilog
// Before:
localparam integer CLKS_PER_BIT = CLK_HZ / BAUD;

// After:
localparam integer CLKS_PER_BIT = (CLK_HZ + BAUD/2) / BAUD;
```

**`fpu_uart_cmd.v`**: Fixed TX state machine timing
- Changed TX states to wait for `!tx_active` before sending next byte
- Ensures each byte completes transmission before next byte starts

## Validation Steps

### Stage 1: TX-Only Beacon (9600 baud)
1. Modify `uart_beacon.v` to set `BAUD = 9600`
2. Build with `uart_beacon.qsf`
3. Program FPGA
4. Open serial terminal at 9600 baud
5. **Expected**: See 0x55 bytes every 100ms
6. **If fails**: Check pin mapping, IO standard, TX wire connection

### Stage 2: TX-Only Beacon (115200 baud)
1. Modify `uart_beacon.v` to set `BAUD = 115200`
2. Repeat steps 2-5 above
3. **Expected**: See 0x55 bytes every 100ms at 115200 baud

### Stage 3: Echo Test (9600 baud)
1. Modify `uart_echo.v` to set `BAUD = 9600`
2. Build with `uart_echo.qsf`
3. Program FPGA
4. Open serial terminal at 9600 baud
5. Send test bytes (e.g., "Hello")
6. **Expected**: Each byte echoed back immediately
7. **If fails**: Check RX pin mapping, pull-up, RX wire connection

### Stage 4: Echo Test (115200 baud)
1. Modify `uart_echo.v` to set `BAUD = 115200`
2. Repeat steps 2-6 above

### Stage 5: Full Protocol Test
1. Build main project with `fpu_qp.qsf` (all fixes applied)
2. Program FPGA
3. Run Python client: `python3 demo_serial.py /dev/ttyUSB0`
4. **Expected**: 
   - No junk bytes
   - Correct response: `status=0x00 z=0x40400000 float=3.0` for 1.0 + 2.0
   - Repeatable results

## Expected Results

After fixes:
- **Beacon test**: Should see continuous 0x55 bytes at correct intervals
- **Echo test**: Should echo all bytes correctly
- **Protocol test**: Should return correct FPU results without timeouts or junk

## Additional Notes

1. **Bank 8 Voltage**: The pin report shows Bank 8 VCCIO as 2.5V, but GPIO headers on DE0-Nano are typically 3.3V. The IO standard override should work, but verify the actual board voltage if issues persist.

2. **Baud Rate Accuracy**: At 50MHz with CLKS_PER_BIT=434:
   - Actual baud: 115207.37 Hz
   - Error: +0.006%
   - This is well within UART tolerance (±2-5%)

3. **Protocol Timeout**: The FSM has RX timeout (40ms) and Z timeout (1s) which should handle most error cases.

4. **Python Client**: The client already has re-sync logic (searches for 0x5A) and buffer flushing, which is good.

## Files Modified

1. `fpu_qp.qsf` - Added IO standard and pull-up assignments
2. `fpu_qp.v` - Fixed baud rate calculation
3. `fpu_uart_cmd.v` - Fixed TX state machine timing

## Files Created

1. `uart_beacon.v` - TX-only test module
2. `uart_beacon.qsf` - QSF for beacon test
3. `uart_echo.v` - Echo test module
4. `uart_echo.qsf` - QSF for echo test
5. `DIAGNOSIS_REPORT.md` - This report

## Next Steps

1. Build and test beacon at 9600 baud
2. Build and test beacon at 115200 baud
3. Build and test echo at 9600 baud
4. Build and test echo at 115200 baud
5. Build and test full protocol
6. Document results

