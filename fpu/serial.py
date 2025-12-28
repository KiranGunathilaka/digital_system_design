#!/usr/bin/env python3
import struct
import serial
import sys

SYNC_REQ  = 0xA5
SYNC_RESP = 0x5A

OP_ADD = 0
OP_MUL = 1
OP_DIV = 2

def send_cmd(ser, op, a_u32, b_u32):
    # packet: A5 op A(le32) B(le32)
    pkt = struct.pack("<BBII", SYNC_REQ, op & 0xFF, a_u32 & 0xFFFFFFFF, b_u32 & 0xFFFFFFFF)
    ser.write(pkt)

    # response: 5A status Z(le32)
    resp = ser.read(6)
    if len(resp) != 6:
        raise RuntimeError(f"Timeout reading response, got {len(resp)} bytes")
    hdr, status, z_u32 = struct.unpack("<BBI", resp)
    if hdr != SYNC_RESP:
        raise RuntimeError(f"Bad response header: 0x{hdr:02X}")
    return status, z_u32

def f2u32(x: float) -> int:
    return struct.unpack("<I", struct.pack("<f", x))[0]

def u32_2f(u: int) -> float:
    return struct.unpack("<f", struct.pack("<I", u & 0xFFFFFFFF))[0]

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 fpu_uart_client.py /dev/ttyUSB0")
        sys.exit(1)

    port = sys.argv[1]
    ser = serial.Serial(port, 115200, timeout=1)

    # Example: 1.0 + 2.0 = 3.0
    a = f2u32(1.0)   # 0x3F800000
    b = f2u32(2.0)   # 0x40000000
    status, z = send_cmd(ser, OP_ADD, a, b)
    print(f"status=0x{status:02X} z=0x{z:08X} float={u32_2f(z)}")
