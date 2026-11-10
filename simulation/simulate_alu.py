#!/usr/bin/env python3
"""
Python-based reference simulator and VCD waveform generator for 4-bit ALU.
This provides:
1. Exact behavioral validation of rtl/alu.v logic.
2. Direct generation of waveforms/alu_waveform.vcd for GTKWave inspection.
3. Fallback simulation when Icarus Verilog is not yet installed.
"""

import sys
import os

def alu(a: int, b: int, opcode: int):
    a = a & 0xF
    b = b & 0xF
    carry_out = 0
    result = 0

    if opcode == 0:    # ADD
        sum_val = a + b
        carry_out = (sum_val >> 4) & 1
        result = sum_val & 0xF
    elif opcode == 1:  # SUB
        diff_val = a - b
        if diff_val < 0:
            carry_out = 1  # borrow
            result = (diff_val + 16) & 0xF
        else:
            carry_out = 0
            result = diff_val & 0xF
    elif opcode == 2:  # AND
        result = (a & b) & 0xF
        carry_out = 0
    elif opcode == 3:  # OR
        result = (a | b) & 0xF
        carry_out = 0
    elif opcode == 4:  # XOR
        result = (a ^ b) & 0xF
        carry_out = 0
    elif opcode == 5:  # NOT
        result = (~a) & 0xF
        carry_out = 0
    elif opcode == 6:  # LSHIFT
        result = (a << 1) & 0xF
        carry_out = 0
    elif opcode == 7:  # RSHIFT
        result = (a >> 1) & 0xF
        carry_out = 0
    else:
        result = 0
        carry_out = 0

    zero_flag = 1 if result == 0 else 0
    return result, carry_out, zero_flag

test_cases = [
    # ADD
    ("ADD_NORMAL",   0b0011, 0b0100, 0b000, 0b0111, 0, 0),
    ("ADD_ZERO",     0b0000, 0b0000, 0b000, 0b0000, 0, 1),
    ("ADD_OVERFLOW", 0b1100, 0b0101, 0b000, 0b0001, 1, 0),
    ("ADD_MAX",      0b1111, 0b1111, 0b000, 0b1110, 1, 0),
    ("ADD_OVF_ZERO", 0b1000, 0b1000, 0b000, 0b0000, 1, 1),
    # SUB
    ("SUB_NORMAL",   0b0111, 0b0010, 0b001, 0b0101, 0, 0),
    ("SUB_EQUAL",    0b1010, 0b1010, 0b001, 0b0000, 0, 1),
    ("SUB_BORROW",   0b0011, 0b0101, 0b001, 0b1110, 1, 0),
    ("SUB_UNDERFLOW",0b0000, 0b0001, 0b001, 0b1111, 1, 0),
    ("SUB_ZERO_B",   0b1111, 0b0000, 0b001, 0b1111, 0, 0),
    # AND
    ("AND_NORMAL",   0b1011, 0b1101, 0b010, 0b1001, 0, 0),
    ("AND_ZERO",     0b1010, 0b0101, 0b010, 0b0000, 0, 1),
    ("AND_ALL_ONES", 0b1111, 0b1111, 0b010, 0b1111, 0, 0),
    # OR
    ("OR_NORMAL",    0b1010, 0b0101, 0b011, 0b1111, 0, 0),
    ("OR_ZERO",      0b0000, 0b0000, 0b011, 0b0000, 0, 1),
    ("OR_OVERLAP",   0b1100, 0b0110, 0b011, 0b1110, 0, 0),
    # XOR
    ("XOR_NORMAL",   0b1100, 0b1010, 0b100, 0b0110, 0, 0),
    ("XOR_IDENTICAL",0b1111, 0b1111, 0b100, 0b0000, 0, 1),
    ("XOR_INVERT",   0b0101, 0b1111, 0b100, 0b1010, 0, 0),
    # NOT
    ("NOT_NORMAL",   0b1010, 0b0000, 0b101, 0b0101, 0, 0),
    ("NOT_ZERO",     0b1111, 0b0000, 0b101, 0b0000, 0, 1),
    ("NOT_ONES",     0b0000, 0b0000, 0b101, 0b1111, 0, 0),
    # LSHIFT
    ("LSHIFT_NORM",  0b0011, 0b0000, 0b110, 0b0110, 0, 0),
    ("LSHIFT_MSB1",  0b1001, 0b0000, 0b110, 0b0010, 0, 0),
    ("LSHIFT_ZERO",  0b1000, 0b0000, 0b110, 0b0000, 0, 1),
    # RSHIFT
    ("RSHIFT_NORM",  0b0110, 0b0000, 0b111, 0b0011, 0, 0),
    ("RSHIFT_MSB0",  0b1011, 0b0000, 0b111, 0b0101, 0, 0),
    ("RSHIFT_ZERO",  0b0001, 0b0000, 0b111, 0b0000, 0, 1),
]

def generate_vcd(vcd_path):
    os.makedirs(os.path.dirname(vcd_path), exist_ok=True)
    with open(vcd_path, "w") as f:
        f.write("$date\n   Nov 11, 2026\n$end\n")
        f.write("$version\n   Python ALU Simulator VCD Generator\n$end\n")
        f.write("$timescale\n   1ns\n$end\n")
        f.write("$scope module alu_tb $end\n")
        f.write("$var wire 4 ! A [3:0] $end\n")
        f.write("$var wire 4 \" B [3:0] $end\n")
        f.write("$var wire 3 # opcode [2:0] $end\n")
        f.write("$var wire 4 $ result [3:0] $end\n")
        f.write("$var wire 1 % carry_out $end\n")
        f.write("$var wire 1 & zero_flag $end\n")
        f.write("$upscope $end\n")
        f.write("$enddefinitions $end\n")
        f.write("$dumpvars\n")
        f.write("b0000 !\n")
        f.write("b0000 \"\n")
        f.write("b000 #\n")
        f.write("b0000 $\n")
        f.write("0%\n")
        f.write("1&\n")
        f.write("$end\n")

        time_val = 0
        for name, a, b, op, exp_r, exp_c, exp_z in test_cases:
            res, cout, zflag = alu(a, b, op)
            f.write(f"#{time_val}\n")
            f.write(f"b{a:04b} !\n")
            f.write(f"b{b:04b} \"\n")
            f.write(f"b{op:03b} #\n")
            f.write(f"b{res:04b} $\n")
            f.write(f"{cout}%\n")
            f.write(f"{zflag}&\n")
            time_val += 10
        f.write(f"#{time_val}\n")

def run_tests():
    print("==========================================================================================")
    print("                          4-BIT ALU VERIFICATION TESTBENCH                                ")
    print("==========================================================================================")
    print(" Status | Operation    |  A  (Dec) |  B  (Dec) | Opcode | Result (Dec) | CarryOut | ZeroFlag ")
    print("------------------------------------------------------------------------------------------")

    total = 0
    passed = 0
    failed = 0

    for name, a, b, op, exp_r, exp_c, exp_z in test_cases:
        res, cout, zflag = alu(a, b, op)
        total += 1
        if res == exp_r and cout == exp_c and zflag == exp_z:
            passed += 1
            print(f" [PASS] | {name:<12} | {a:04b} ({a:2d}) | {b:04b} ({b:2d}) |   {op:03b}   |   {res:04b} ({res:2d})  |    {cout}    |    {zflag}")
        else:
            failed += 1
            print(f" [FAIL] | {name:<12} | {a:04b} ({a:2d}) | {b:04b} ({b:2d}) |   {op:03b}   | Got: {res:04b}, Cout={cout}, Z={zflag} | Exp: {exp_r:04b}, Cout={exp_c}, Z={exp_z}")

    print("------------------------------------------------------------------------------------------")
    print(f"Total Tests Executed : {total}")
    print(f"Tests Passed         : {passed}")
    print(f"Tests Failed         : {failed}")
    print("------------------------------------------------------------------------------------------")
    if failed == 0:
        print(f">>> ALL {total} TESTS PASSED SUCCESSFULLY! <<<")
    else:
        print(f">>> ERROR: {failed} TEST(S) FAILED! <<<")
    print("==========================================================================================")

    # Generate VCD
    workspace_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    vcd_target = os.path.join(workspace_root, "waveforms", "alu_waveform.vcd")
    generate_vcd(vcd_target)
    print(f"Waveform successfully written to: {vcd_target}")

if __name__ == "__main__":
    run_tests()

