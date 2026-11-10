// =============================================================================
// Module Name: alu
// Description: 4-bit Arithmetic Logic Unit (ALU)
// Author:      ECE Design Team
// Standard:    Verilog-2001 (Synthesizable RTL)
// 
// Inputs:
//   - A [3:0]      : 4-bit operand A
//   - B [3:0]      : 4-bit operand B
//   - opcode [2:0] : 3-bit operation selector
//
// Outputs:
//   - result [3:0] : 4-bit operation result
//   - carry_out    : 1-bit carry / borrow flag for arithmetic operations
//   - zero_flag    : 1-bit status flag (active HIGH when result == 4'b0000)
//
// Supported Operations:
//   3'b000 : ADD         (result = A + B)
//   3'b001 : SUB         (result = A - B)
//   3'b010 : Bitwise AND (result = A & B)
//   3'b011 : Bitwise OR  (result = A | B)
//   3'b100 : Bitwise XOR (result = A ^ B)
//   3'b101 : Bitwise NOT (result = ~A)
//   3'b110 : LEFT SHIFT  (result = A << 1)
//   3'b111 : RIGHT SHIFT (result = A >> 1)
// =============================================================================

`timescale 1ns / 1ps

module alu (
    input  wire [3:0] A,         // 4-bit input operand A
    input  wire [3:0] B,         // 4-bit input operand B
    input  wire [2:0] opcode,    // 3-bit operation selection code
    output reg  [3:0] result,    // 4-bit computation result
    output reg        carry_out, // Arithmetic carry-out / borrow indicator
    output wire       zero_flag  // Status flag: 1 if result is 4'b0000
);

    // Operation code definitions for readability
    localparam OP_ADD    = 3'b000;
    localparam OP_SUB    = 3'b001;
    localparam OP_AND    = 3'b010;
    localparam OP_OR     = 3'b011;
    localparam OP_XOR    = 3'b100;
    localparam OP_NOT    = 3'b101;
    localparam OP_LSHIFT = 3'b110;
    localparam OP_RSHIFT = 3'b111;

    // Combinational always block: evaluates whenever any input changes
    always @(*) begin
        // Default assignments to prevent unintended latch inference
        result    = 4'b0000;
        carry_out = 1'b0;

        case (opcode)
            // -------------------------------------------------------------
            // Arithmetic Operations
            // -------------------------------------------------------------
            OP_ADD: begin
                // 5-bit concatenated assignment captures both carry and 4-bit sum
                {carry_out, result} = A + B;
            end

            OP_SUB: begin
                // In unsigned subtraction:
                // carry_out = 1 indicates a borrow occurred (A < B)
                // carry_out = 0 indicates no borrow (A >= B)
                {carry_out, result} = A - B;
            end

            // -------------------------------------------------------------
            // Logical Operations (carry_out is explicitly driven to 0)
            // -------------------------------------------------------------
            OP_AND: begin
                result    = A & B;
                carry_out = 1'b0;
            end

            OP_OR: begin
                result    = A | B;
                carry_out = 1'b0;
            end

            OP_XOR: begin
                result    = A ^ B;
                carry_out = 1'b0;
            end

            OP_NOT: begin
                result    = ~A; // Inversion of operand A
                carry_out = 1'b0;
            end

            // -------------------------------------------------------------
            // Shift Operations
            // -------------------------------------------------------------
            OP_LSHIFT: begin
                result    = A << 1; // Logical left shift by 1 bit (LSB filled with 0)
                carry_out = 1'b0;
            end

            OP_RSHIFT: begin
                result    = A >> 1; // Logical right shift by 1 bit (MSB filled with 0)
                carry_out = 1'b0;
            end

            default: begin
                result    = 4'b0000;
                carry_out = 1'b0;
            end
        endcase
    end

    // Zero Flag Generation:
    // Continuous assignment asserts zero_flag HIGH whenever result equals 0
    assign zero_flag = (result == 4'b0000);

endmodule

