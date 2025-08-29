import serial
import threading
import sys

# === CONFIG ===
PORT = "COM11"       # Change to your FT232/ESP32 port (Linux ex: "/dev/ttyUSB0")
BAUD = 9600

# Open serial connection
ser = serial.Serial(PORT, BAUD, timeout=0.1)

def read_from_serial():
    """Continuously read from serial and print to console."""
    while True:
        if ser.in_waiting:
            data = ser.read(ser.in_waiting).decode(errors="ignore")
            if data:
                sys.stdout.write(data)
                sys.stdout.flush()

# Run serial reading in background
thread = threading.Thread(target=read_from_serial, daemon=True)
thread.start()

print(f"Connected to {PORT} at {BAUD} baud.")
print("Type messages and press Enter to send. Press Ctrl+C to exit.\n")

try:
    while True:
        user_input = input()  # Take keyboard input
        ser.write((user_input + "\n").encode())  # Send to ESP32
except KeyboardInterrupt:
    print("\nExiting...")
    ser.close()
