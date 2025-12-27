#!/usr/bin/env python3
import os
import sys
import subprocess
from random import randint
from itertools import permutations

IVERILOG_OUT = "test_bench_tb"
C_MODEL = "./c_test/test"
STIM_A_FILE = "stim_a"
STIM_B_FILE = "stim_b"
RESP_Z_FILE = "resp_z"

C_MODEL_TIMEOUT = 10
SIM_TIMEOUT_BASE = 5          # seconds
SIM_TIMEOUT_PER_1K = 5        # seconds per 1000 vectors


def compile_verilog():
    cmd = [
        "iverilog",
        "-o", IVERILOG_OUT,
        "file_reader_a.v",
        "file_reader_b.v",
        "file_writer.v",
        "adder.v",
        "test_bench.v",
        "test_bench_tb.v",
    ]
    print("Compiling Verilog:", " ".join(cmd), flush=True)
    subprocess.check_call(cmd)


def get_mantissa(x): return 0x7fffff & x
def get_exponent(x): return ((x & 0x7f800000) >> 23) - 127
def get_sign(x): return ((x & 0x80000000) >> 31)

def is_nan(x): return get_exponent(x) == 128 and get_mantissa(x) != 0
def is_inf(x): return get_exponent(x) == 128 and get_mantissa(x) == 0
def is_pos_inf(x): return is_inf(x) and not get_sign(x)
def is_neg_inf(x): return is_inf(x) and get_sign(x)

def match(x, y):
    return (
        (is_pos_inf(x) and is_pos_inf(y)) or
        (is_neg_inf(x) and is_neg_inf(y)) or
        (is_nan(x) and is_nan(y)) or
        (x == y)
    )


def run_c_model(stimulus_a, stimulus_b):
    # Provide pairs as "a b" per line (C reads two ints per iteration).
    input_lines = [f"{a} {b}" for a, b in zip(stimulus_a, stimulus_b)]
    input_text = "\n".join(input_lines) + "\n"

    try:
        p = subprocess.run(
            [C_MODEL],
            input=input_text,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            timeout=C_MODEL_TIMEOUT,
        )
    except subprocess.TimeoutExpired:
        raise RuntimeError("C model timed out. It is likely blocked waiting for input or stuck in an infinite loop.")

    if p.returncode != 0:
        raise RuntimeError(f"C model failed (rc={p.returncode}). stderr:\n{p.stderr}")

    out_lines = [ln.strip() for ln in p.stdout.splitlines() if ln.strip() != ""]
    expected = [int(ln) for ln in out_lines]

    if len(expected) != len(stimulus_a):
        raise RuntimeError(
            f"C model output count mismatch: expected {len(stimulus_a)} lines, got {len(expected)}.\n"
            f"First few stdout lines: {out_lines[:10]}\n"
            f"stderr:\n{p.stderr}"
        )

    return expected


def run_verilog_sim(num_vectors: int):
    # scale timeout with vector count
    sim_timeout = SIM_TIMEOUT_BASE + (num_vectors // 1000 + 1) * SIM_TIMEOUT_PER_1K

    try:
        subprocess.run(
            ["vvp", IVERILOG_OUT, f"+VECTORS={num_vectors}"],
            check=True,
            timeout=sim_timeout,
        )
    except subprocess.TimeoutExpired:
        raise RuntimeError(
            f"Verilog simulation timed out after {sim_timeout}s.\n"
            "This usually means the testbench never finishes (handshake stuck or stop condition missing)."
        )
    except subprocess.CalledProcessError as e:
        raise RuntimeError(f"Verilog simulation failed: {e}")


def run_test(stimulus_a, stimulus_b):
    n = len(stimulus_a)
    print(f"Generating expected results for {n} vectors...", flush=True)

    # Write stimuli for Verilog readers
    with open(STIM_A_FILE, "w") as fa, open(STIM_B_FILE, "w") as fb:
        for a, b in zip(stimulus_a, stimulus_b):
            fa.write(f"{a}\n")
            fb.write(f"{b}\n")

    expected_responses = run_c_model(stimulus_a, stimulus_b)

    # Ensure we do not accidentally read stale outputs
    if os.path.exists(RESP_Z_FILE):
        os.remove(RESP_Z_FILE)

    print("Running Verilog simulation...", flush=True)
    run_verilog_sim(n)

    if not os.path.exists(RESP_Z_FILE):
        raise RuntimeError(
            f"Missing {RESP_Z_FILE}. Verilog did not generate it.\n"
            "Check file_writer.v and that the simulation reaches $finish."
        )

    with open(RESP_Z_FILE, "r") as f:
        actual_responses = [int(line.strip()) for line in f if line.strip() != ""]

    if len(actual_responses) < len(expected_responses):
        raise RuntimeError(
            f"Fail: not enough results. Expected {len(expected_responses)} got {len(actual_responses)}.\n"
            "This usually means the simulation finished too early."
        )

    for expected, actual, a, b in zip(expected_responses, actual_responses, stimulus_a, stimulus_b):
        if not match(expected, actual):
            print("Fail ... expected:", hex(expected), "actual:", hex(actual))
            print("a:", hex(a), "b:", hex(b))
            sys.exit(1)


def rand32():
    return randint(0, (1 << 32) - 1)


def main():
    compile_verilog()
    count = 0

    # regression
    stimulus_a = [0x22cb525a, 0x40000000, 0x83e73d5c, 0xbf9b1e94, 0x34082401, 0x05e8ef81, 0x5c75da81, 0x0002b017]
    stimulus_b = [0xadd79efa, 0xC0000000, 0x1c800000, 0xc038ed3a, 0xb328cd45, 0x0114f3db, 0x2f642a39, 0xff3807ab]
    run_test(stimulus_a, stimulus_b)
    count += len(stimulus_a)
    print(count, "vectors passed", flush=True)

    # corner cases
    corner = [0x80000000, 0x00000000, 0x7f800000, 0xff800000, 0x7fc00000, 0xffc00000]
    pairs = list(permutations(corner, 2))
    stimulus_a = [p[0] for p in pairs]
    stimulus_b = [p[1] for p in pairs]
    run_test(stimulus_a, stimulus_b)
    count += len(stimulus_a)
    print(count, "vectors passed", flush=True)

    # edge cases
    tests = [
        (lambda: 0x80000000, rand32),
        (lambda: 0x00000000, rand32),
        (rand32, lambda: 0x80000000),
        (rand32, lambda: 0x00000000),
        (lambda: 0x7F800000, rand32),
        (lambda: 0xFF800000, rand32),
        (rand32, lambda: 0x7F800000),
        (rand32, lambda: 0xFF800000),
        (lambda: 0x7FC00000, rand32),
        (lambda: 0xFFC00000, rand32),
        (rand32, lambda: 0x7FC00000),
        (rand32, lambda: 0xFFC00000),
    ]

    for gen_a, gen_b in tests:
        stimulus_a = [gen_a() for _ in range(1000)]
        stimulus_b = [gen_b() for _ in range(1000)]
        run_test(stimulus_a, stimulus_b)
        count += 1000
        print(count, "vectors passed", flush=True)

    # random tests (reduced while debugging)
    for _ in range(10):
        stimulus_a = [rand32() for _ in range(1000)]
        stimulus_b = [rand32() for _ in range(1000)]
        run_test(stimulus_a, stimulus_b)
        count += 1000
        print(count, "vectors passed", flush=True)


if __name__ == "__main__":
    main()