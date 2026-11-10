// =============================================================================
// Module Name: alu_tb
// Description: Comprehensive Self-Checking Testbench for 4-bit ALU
// Author:      ECE Design Team
// Standard:    Verilog-2001
// 
// Features:
//   - Covers all 8 operations (ADD, SUB, AND, OR, XOR, NOT, LSHIFT, RSHIFT)
//   - Tests normal, edge, and corner cases (0000, 1111, overflow, borrow, zero flag)
//   - Automatic self-checking with comparison against expected outputs
//   - Formatted table output for console inspection
//   - Generates VCD waveform file for GTKWave visualization
// =============================================================================

`timescale 1ns / 1ps

module alu_tb;

    // -------------------------------------------------------------------------
    // Signal Declarations
    // -------------------------------------------------------------------------
    reg  [3:0] A;
    reg  [3:0] B;
    reg  [2:0] opcode;

    wire [3:0] result;
    wire       carry_out;
    wire       zero_flag;

    // Counters for testbench verification metrics
    integer total_tests = 0;
    integer pass_count  = 0;
    integer fail_count  = 0;

    // -------------------------------------------------------------------------
    // Instantiate Device Under Test (DUT)
    // -------------------------------------------------------------------------
    alu uut (
        .A(A),
        .B(B),
        .opcode(opcode),
        .result(result),
        .carry_out(carry_out),
        .zero_flag(zero_flag)
    );

    // -------------------------------------------------------------------------
    // Waveform Dumping for GTKWave
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("alu_waveform.vcd");
        $dumpvars(0, alu_tb);
    end

    // -------------------------------------------------------------------------
    // Self-Checking Verification Task
    // -------------------------------------------------------------------------
    task check_alu;
        input [3:0]      test_a;
        input [3:0]      test_b;
        input [2:0]      test_op;
        input [3:0]      exp_result;
        input            exp_carry;
        input            exp_zero;
        input [8*12:1]   test_name;
        begin
            A      = test_a;
            B      = test_b;
            opcode = test_op;

            #10; // Propagation delay for combinational logic settling

            total_tests = total_tests + 1;

            if ((result === exp_result) && 
                (carry_out === exp_carry) && 
                (zero_flag === exp_zero)) begin
                $display(" [PASS] | %-12s | %b (%2d) | %b (%2d) |   %b   |   %b (%2d)  |    %b    |    %b",
                         test_name, A, A, B, B, opcode, result, result, carry_out, zero_flag);
                pass_count = pass_count + 1;
            end else begin
                $display(" [FAIL] | %-12s | %b (%2d) | %b (%2d) |   %b   | Got: %b, Cout=%b, Z=%b | Exp: %b, Cout=%b, Z=%b",
                         test_name, A, A, B, B, opcode,
                         result, carry_out, zero_flag,
                         exp_result, exp_carry, exp_zero);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Main Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        $display("==========================================================================================");
        $display("                          4-BIT ALU VERIFICATION TESTBENCH                                ");
        $display("==========================================================================================");
        $display(" Status | Operation    |  A  (Dec) |  B  (Dec) | Opcode | Result (Dec) | CarryOut | ZeroFlag ");
        $display("------------------------------------------------------------------------------------------");

        // =====================================================================
        // 1. ADDITION TESTS (opcode = 3'b000)
        // =====================================================================
        // Test 1: Simple Addition without carry
        check_alu(4'b0011, 4'b0100, 3'b000, 4'b0111, 1'b0, 1'b0, "ADD_NORMAL");    // 3 + 4 = 7
        // Test 2: Addition yielding Zero (0 + 0)
        check_alu(4'b0000, 4'b0000, 3'b000, 4'b0000, 1'b0, 1'b1, "ADD_ZERO");      // 0 + 0 = 0 (Z=1)
        // Test 3: Addition with Carry Out (Overflow past 4 bits: 12 + 5 = 17 -> 1 with Cout=1)
        check_alu(4'b1100, 4'b0101, 3'b000, 4'b0001, 1'b1, 1'b0, "ADD_OVERFLOW");  // 12 + 5 = 17
        // Test 4: Addition of Maximum Values (15 + 15 = 30 -> 14 with Cout=1)
        check_alu(4'b1111, 4'b1111, 3'b000, 4'b1110, 1'b1, 1'b0, "ADD_MAX");       // 15 + 15 = 30
        // Test 5: Addition resulting in zero with carry out (8 + 8 = 16 -> 0 with Cout=1, Z=1)
        check_alu(4'b1000, 4'b1000, 3'b000, 4'b0000, 1'b1, 1'b1, "ADD_OVF_ZERO");  // 8 + 8 = 16

        // =====================================================================
        // 2. SUBTRACTION TESTS (opcode = 3'b001)
        // =====================================================================
        // Test 6: Subtraction A > B (No borrow)
        check_alu(4'b0111, 4'b0010, 3'b001, 4'b0101, 1'b0, 1'b0, "SUB_NORMAL");    // 7 - 2 = 5
        // Test 7: Subtraction A == B (Zero Flag asserted)
        check_alu(4'b1010, 4'b1010, 3'b001, 4'b0000, 1'b0, 1'b1, "SUB_EQUAL");     // 10 - 10 = 0 (Z=1)
        // Test 8: Subtraction A < B (Borrow generated: 3 - 5 = -2 -> 14 with Cout=1)
        check_alu(4'b0011, 4'b0101, 3'b001, 4'b1110, 1'b1, 1'b0, "SUB_BORROW");    // 3 - 5 = -2
        // Test 9: Subtraction from Zero (0 - 1 = -1 -> 15 with Cout=1)
        check_alu(4'b0000, 4'b0001, 3'b001, 4'b1111, 1'b1, 1'b0, "SUB_UNDERFLOW"); // 0 - 1 = -1
        // Test 10: Subtraction 15 - 0 = 15
        check_alu(4'b1111, 4'b0000, 3'b001, 4'b1111, 1'b0, 1'b0, "SUB_ZERO_B");    // 15 - 0 = 15

        // =====================================================================
        // 3. BITWISE AND TESTS (opcode = 3'b010)
        // =====================================================================
        // Test 11: General Bitwise AND
        check_alu(4'b1011, 4'b1101, 3'b010, 4'b1001, 1'b0, 1'b0, "AND_NORMAL");    // 1011 & 1101 = 1001
        // Test 12: Disjoint patterns yielding Zero Flag
        check_alu(4'b1010, 4'b0101, 3'b010, 4'b0000, 1'b0, 1'b1, "AND_ZERO");      // 1010 & 0101 = 0000
        // Test 13: AND with 1111
        check_alu(4'b1111, 4'b1111, 3'b010, 4'b1111, 1'b0, 1'b0, "AND_ALL_ONES");  // 1111 & 1111 = 1111

        // =====================================================================
        // 4. BITWISE OR TESTS (opcode = 3'b011)
        // =====================================================================
        // Test 14: General Bitwise OR
        check_alu(4'b1010, 4'b0101, 3'b011, 4'b1111, 1'b0, 1'b0, "OR_NORMAL");     // 1010 | 0101 = 1111
        // Test 15: OR of 0000 | 0000 (Zero Flag asserted)
        check_alu(4'b0000, 4'b0000, 3'b011, 4'b0000, 1'b0, 1'b1, "OR_ZERO");       // 0000 | 0000 = 0000
        // Test 16: Partial overlap OR
        check_alu(4'b1100, 4'b0110, 3'b011, 4'b1110, 1'b0, 1'b0, "OR_OVERLAP");    // 1100 | 0110 = 1110

        // =====================================================================
        // 5. BITWISE XOR TESTS (opcode = 3'b100)
        // =====================================================================
        // Test 17: General Bitwise XOR
        check_alu(4'b1100, 4'b1010, 3'b100, 4'b0110, 1'b0, 1'b0, "XOR_NORMAL");    // 1100 ^ 1010 = 0110
        // Test 18: Identical inputs (Zero Flag asserted)
        check_alu(4'b1111, 4'b1111, 3'b100, 4'b0000, 1'b0, 1'b1, "XOR_IDENTICAL"); // 1111 ^ 1111 = 0000
        // Test 19: Inversion with 1111
        check_alu(4'b0101, 4'b1111, 3'b100, 4'b1010, 1'b0, 1'b0, "XOR_INVERT");    // 0101 ^ 1111 = 1010

        // =====================================================================
        // 6. BITWISE NOT TESTS (opcode = 3'b101)
        // =====================================================================
        // Test 20: General Inversion of A
        check_alu(4'b1010, 4'b0000, 3'b101, 4'b0101, 1'b0, 1'b0, "NOT_NORMAL");    // ~1010 = 0101
        // Test 21: Inverting 1111 produces 0000 (Zero Flag asserted)
        check_alu(4'b1111, 4'b0000, 3'b101, 4'b0000, 1'b0, 1'b1, "NOT_ZERO");      // ~1111 = 0000
        // Test 22: Inverting 0000 produces 1111
        check_alu(4'b0000, 4'b0000, 3'b101, 4'b1111, 1'b0, 1'b0, "NOT_ONES");      // ~0000 = 1111

        // =====================================================================
        // 7. LEFT SHIFT TESTS (opcode = 3'b110)
        // =====================================================================
        // Test 23: Shift 0011 left by 1 -> 0110
        check_alu(4'b0011, 4'b0000, 3'b110, 4'b0110, 1'b0, 1'b0, "LSHIFT_NORM");   // 0011 << 1 = 0110
        // Test 24: Shift 1001 left by 1 -> 0010 (MSB dropped)
        check_alu(4'b1001, 4'b0000, 3'b110, 4'b0010, 1'b0, 1'b0, "LSHIFT_MSB1");   // 1001 << 1 = 0010
        // Test 25: Shift 1000 left by 1 -> 0000 (Zero Flag asserted)
        check_alu(4'b1000, 4'b0000, 3'b110, 4'b0000, 1'b0, 1'b1, "LSHIFT_ZERO");   // 1000 << 1 = 0000

        // =====================================================================
        // 8. RIGHT SHIFT TESTS (opcode = 3'b111)
        // =====================================================================
        // Test 26: Shift 0110 right by 1 -> 0011
        check_alu(4'b0110, 4'b0000, 3'b111, 4'b0011, 1'b0, 1'b0, "RSHIFT_NORM");   // 0110 >> 1 = 0011
        // Test 27: Shift 1011 right by 1 -> 0101
        check_alu(4'b1011, 4'b0000, 3'b111, 4'b0101, 1'b0, 1'b0, "RSHIFT_MSB0");   // 1011 >> 1 = 0101
        // Test 28: Shift 0001 right by 1 -> 0000 (Zero Flag asserted)
        check_alu(4'b0001, 4'b0000, 3'b111, 4'b0000, 1'b0, 1'b1, "RSHIFT_ZERO");   // 0001 >> 1 = 0000

        // ---------------------------------------------------------------------
        // Final Summary
        // ---------------------------------------------------------------------
        $display("------------------------------------------------------------------------------------------");
        $display("Total Tests Executed : %0d", total_tests);
        $display("Tests Passed         : %0d", pass_count);
        $display("Tests Failed         : %0d", fail_count);
        $display("------------------------------------------------------------------------------------------");

        if (fail_count == 0) begin
            $display(">>> ALL %0d TESTS PASSED SUCCESSFULLY! <<<", total_tests);
        end else begin
            $display(">>> ERROR: %0d TEST(S) FAILED! <<<", fail_count);
        end
        $display("==========================================================================================");

        $finish;
    end

endmodule

