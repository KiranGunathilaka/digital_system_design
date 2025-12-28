#!/usr/bin/env python3
import struct, serial, sys, time

SYNC_REQ  = 0xA5
SYNC_RESP = 0x5A

OP_ADD = 0
OP_MUL = 1
OP_DIV = 2

def _read_exact(ser, n, deadline_s):
  buf = b""
  end = time.time() + deadline_s
  while len(buf) < n and time.time() < end:
    chunk = ser.read(n - len(buf))
    if chunk:
      buf += chunk
  return buf

def send_cmd(ser, op, a_u32, b_u32, timeout_s=2.0):
  # Always start clean
  ser.reset_input_buffer()
  ser.reset_output_buffer()

  pkt = struct.pack("<BBII", SYNC_REQ, op & 0xFF, a_u32 & 0xFFFFFFFF, b_u32 & 0xFFFFFFFF)
  ser.write(pkt)
  ser.flush()

  # Re-sync: find 0x5A, then read status + z
  end = time.time() + timeout_s
  junk = bytearray()

  while time.time() < end:
    b = ser.read(1)
    if not b:
      continue
    v = b[0]
    if v == SYNC_RESP:
      rest = _read_exact(ser, 5, deadline_s=end - time.time())
      if len(rest) != 5:
        raise RuntimeError(f"Timeout after header, got {len(rest)} of 5 bytes; junk={junk.hex()}")
      status = rest[0]
      z_u32 = struct.unpack("<I", rest[1:])[0]
      return status, z_u32, bytes(junk)
    else:
      junk.append(v)

  raise RuntimeError(f"Timeout waiting for 0x5A; junk={junk.hex()}")

def f2u32(x: float) -> int:
  return struct.unpack("<I", struct.pack("<f", x))[0]

def u32_2f(u: int) -> float:
  return struct.unpack("<f", struct.pack("<I", u & 0xFFFFFFFF))[0]

if __name__ == "__main__":
  port = sys.argv[1]
  ser = serial.Serial(port, 115200, timeout=0.05)  # small read timeout; we manage overall timeout
  time.sleep(0.1)

  a = f2u32(1.0)
  b = f2u32(2.0)
  status, z, junk = send_cmd(ser, OP_ADD, a, b, timeout_s=2.0)
  print(f"junk={junk.hex()} status=0x{status:02X} z=0x{z:08X} float={u32_2f(z)}")
