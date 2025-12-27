#!/usr/bin/env python3
import struct
import serial
import sys
import time

SYNC_REQ  = 0xA5
SYNC_RESP = 0x5A

OP_ADD = 0
OP_MUL = 1
OP_DIV = 2

def f2u32(x: float) -> int:
    return struct.unpack("<I", struct.pack("<f", x))[0]

def u32_2f(u: int) -> float:
    return struct.unpack("<f", struct.pack("<I", u & 0xFFFFFFFF))[0]

def send_cmd(ser, op, a_f, b_f):
    a_u32 = f2u32(a_f)
    b_u32 = f2u32(b_f)

    pkt = struct.pack("<BBII", SYNC_REQ, op & 0xFF, a_u32, b_u32)
    ser.reset_input_buffer()
    ser.write(pkt)

    resp = ser.read(6)
    if len(resp) != 6:
        raise RuntimeError(f"Timeout reading response ({len(resp)} bytes)")
    hdr, status, z_u32 = struct.unpack("<BBI", resp)
    if hdr != SYNC_RESP:
        raise RuntimeError(f"Bad response header: 0x{hdr:02X}")

    return status, z_u32, u32_2f(z_u32)

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 demo_fpu_uart.py /dev/ttyUSB0")
        sys.exit(1)

    port = sys.argv[1]
    ser = serial.Serial(port, 115200, timeout=1)
    time.sleep(0.1)

    tests = [
        ("ADD", OP_ADD,  1.0,  2.0,  3.0),
        ("MUL", OP_MUL,  3.0,  4.0, 12.0),
        ("DIV", OP_DIV, 10.0,  2.0,  5.0),
        ("ADD", OP_ADD, -1.5,  0.5, -1.0),
        ("MUL", OP_MUL,  0.0, -7.0, -0.0),
    ]

    for name, op, a, b, expected in tests:
        status, z_u32, z_f = send_cmd(ser, op, a, b)
        print(f"{name}  a={a} b={b}")
        print(f"  status=0x{status:02X}  z=0x{z_u32:08X}  z_float={z_f}  expected~={expected}")
        print()

if __name__ == "__main__":
    main()
