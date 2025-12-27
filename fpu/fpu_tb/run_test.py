#!/usr/bin/env python3
import sys
import subprocess
from random import randint
from itertools import permutations

IVERILOG_OUT = "test_bench_tb"
C_MODEL = "./c_test/test"

STIM_OP_FILE = "stim_op"
STIM_A_FILE  = "stim_a"
STIM_B_FILE  = "stim_b"
RESP_Z_FILE  = "resp_z"

C_MODEL_TIMEOUT = 10
SIM_TIMEOUT = 30

MAX_FAILS_TO_PRINT = 20
MAX_FAILS_BEFORE_ABORT = 200

OP_ADD = 0
OP_MUL = 1
OP_DIV = 2

def compile_verilog():
    cmd = [
        "iverilog",
        "-g2012",
        "-o", IVERILOG_OUT,
        "../fpu_top.v",
        "../adder/adder.v",
        "../multiplier/multiplier.v",
        "../divider/divider.v",
        "test_bench.v",
        "test_bench_tb.v",
    ]
    print("Compiling Verilog:", " ".join(cmd), flush=True)
    subprocess.check_call(cmd)

def run_verilog_sim():
    subprocess.run(["vvp", IVERILOG_OUT], check=True, timeout=SIM_TIMEOUT)

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

def run_c_model(ops, stimulus_a, stimulus_b):
    lines = []
    for op, a, b in zip(ops, stimulus_a, stimulus_b):
        lines.append(str(op))
        lines.append(str(a))
        lines.append(str(b))
    input_text = "\n".join(lines) + "\n"

    p = subprocess.run(
        [C_MODEL],
        input=input_text,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=C_MODEL_TIMEOUT,
    )
    if p.returncode != 0:
        raise RuntimeError(f"C model failed (rc={p.returncode}). stderr:\n{p.stderr}")

    out_lines = [ln.strip() for ln in p.stdout.splitlines() if ln.strip() != ""]
    expected = [int(ln) for ln in out_lines]
    if len(expected) != len(stimulus_a):
        raise RuntimeError(f"C model output count mismatch: expected {len(stimulus_a)} got {len(expected)}")
    return expected

def write_stim_files(ops, stimulus_a, stimulus_b):
    with open(STIM_OP_FILE, "w") as fop, open(STIM_A_FILE, "w") as fa, open(STIM_B_FILE, "w") as fb:
        for op, a, b in zip(ops, stimulus_a, stimulus_b):
            fop.write(f"{op}\n")
            fa.write(f"{a:08x}\n")
            fb.write(f"{b:08x}\n")

def read_resp_file():
    with open(RESP_Z_FILE, "r") as f:
        return [int(ln.strip(), 16) for ln in f if ln.strip() != ""]

def run_batch(ops, stimulus_a, stimulus_b, label=""):
    n = len(stimulus_a)
    print(f"\n--- {label} ({n} vectors) ---", flush=True)

    write_stim_files(ops, stimulus_a, stimulus_b)
    expected = run_c_model(ops, stimulus_a, stimulus_b)

    run_verilog_sim()
    actual = read_resp_file()

    fails = 0
    shown = 0

    if len(actual) < len(expected):
        missing = len(expected) - len(actual)
        print(f"Fail: missing {missing} outputs from simulation.", flush=True)
        fails += missing

    m = min(len(expected), len(actual))
    for i in range(m):
        if not match(expected[i], actual[i]):
            fails += 1
            if shown < MAX_FAILS_TO_PRINT:
                print(f"[FAIL {shown+1}] idx={i} op={ops[i]} a={stimulus_a[i]:08x} b={stimulus_b[i]:08x}", flush=True)
                print(f"  expected={expected[i]:08x} actual={actual[i]:08x}", flush=True)
                shown += 1
            if MAX_FAILS_BEFORE_ABORT is not None and fails >= MAX_FAILS_BEFORE_ABORT:
                print(f"Aborting batch early at {fails} failures.", flush=True)
                break

    passed = n - fails
    print(f"{label}: passed={passed} failed={fails}", flush=True)
    return passed, fails

def rand32():
    return randint(0, (1 << 32) - 1)

def main():
    compile_verilog()

    total = total_pass = total_fail = 0

    # Mix ops intentionally to exercise op switching and busy latch behavior
    corner = [0x80000000, 0x00000000, 0x7f800000, 0xff800000, 0x7fc00000, 0xffc00000]

    # 1) Small regression: some fixed vectors, mixed ops
    ops = [OP_ADD, OP_MUL, OP_DIV, OP_ADD, OP_MUL, OP_DIV]
    stimulus_a = [0xba57711a, 0xbf9b1e94, 0x34082401, 0x05e8ef81, 0x5c75da81, 0x0002b017]
    stimulus_b = [0xee1818c5, 0xc038ed3a, 0xb328cd45, 0x0114f3db, 0x2f642a39, 0xff3807ab]
    p, f = run_batch(ops, stimulus_a, stimulus_b, "regression")
    total += len(ops); total_pass += p; total_fail += f

    # 2) Corner cases per op
    pairs = list(permutations(corner, 2))
    for op in (OP_ADD, OP_MUL, OP_DIV):
        ops = [op] * len(pairs)
        stimulus_a = [x for (x, y) in pairs]
        stimulus_b = [y for (x, y) in pairs]
        p, f = run_batch(ops, stimulus_a, stimulus_b, f"corner op={op}")
        total += len(ops); total_pass += p; total_fail += f

    # 3) Edge cases per op (small)
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
    for op in (OP_ADD, OP_MUL, OP_DIV):
        for i, (gen_a, gen_b) in enumerate(tests):
            n = 500
            ops = [op] * n
            stimulus_a = [gen_a() for _ in range(n)]
            stimulus_b = [gen_b() for _ in range(n)]
            p, f = run_batch(ops, stimulus_a, stimulus_b, f"edge op={op} case={i}")
            total += n; total_pass += p; total_fail += f

    # 4) Random mixed ops (small; scale later)
    for k in range(10):
        n = 1000
        ops = [randint(0, 2) for _ in range(n)]
        stimulus_a = [rand32() for _ in range(n)]
        stimulus_b = [rand32() for _ in range(n)]
        p, f = run_batch(ops, stimulus_a, stimulus_b, f"random mixed {k}")
        total += n; total_pass += p; total_fail += f

    print("\n===== SUMMARY =====", flush=True)
    print(f"Total vectors: {total}", flush=True)
    print(f"Passed:        {total_pass}", flush=True)
    print(f"Failed:        {total_fail}", flush=True)

    sys.exit(1 if total_fail else 0)

if __name__ == "__main__":
    main()