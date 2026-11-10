# Design and Implementation Documentation: 4-bit Arithmetic Logic Unit (ALU)

## 1. Executive Summary & Overview
An **Arithmetic Logic Unit (ALU)** is the foundational computational core of modern microprocessors and digital signal processors (DSPs). It executes elementary arithmetic (addition, subtraction) and bitwise logical (AND, OR, XOR, NOT, shift) operations on binary operands.

This project implements a fully **synthesizable, combinational 4-bit ALU** modeled in **Verilog HDL (IEEE 1364-2001)**. It processes two 4-bit input vectors ($A$ and $B$) guided by a 3-bit selection vector (`opcode`), yielding a 4-bit `result`, a 1-bit arithmetic `carry_out` (or borrow indicator), and a 1-bit `zero_flag`.

---

## 2. ALU Architecture & Block Diagram

```
                 +-----------------------+
    A [3:0] ---->|                       |
                 |       4-BIT ALU       |----> result [3:0]
    B [3:0] ---->|     (Combinational)   |
                 |                       |----> carry_out
 opcode [2:0] -->|                       |----> zero_flag
                 +-----------------------+
```

### Signal Interface Table

| Signal Name | Direction | Bit Width | Data Type | Description |
|:---|:---:|:---:|:---:|:---|
| `A` | Input | 4-bit `[3:0]` | `wire` | First binary operand (bits $A_3, A_2, A_1, A_0$). |
| `B` | Input | 4-bit `[3:0]` | `wire` | Second binary operand (bits $B_3, B_2, B_1, B_0$). |
| `opcode` | Input | 3-bit `[2:0]` | `wire` | Operation selector encoding 8 distinct operations. |
| `result` | Output | 4-bit `[3:0]` | `reg` | Primary 4-bit computation output. |
| `carry_out` | Output | 1-bit | `reg` | Arithmetic carry-out for addition / borrow for subtraction; $0$ for logic/shifts. |
| `zero_flag` | Output | 1-bit | `wire` | Active-HIGH status flag: $1$ when `result == 4'b0000`, else $0$. |

---

## 3. Supported Operations & Functional Specification

| Opcode (`[2:0]`) | Mnemonic | Operation | Verilog Implementation | Arithmetic / Logic Details |
|:---:|:---:|:---:|:---:|:---|
| `3'b000` | **ADD** | Addition | `{carry_out, result} = A + B;` | Unsigned 4-bit addition. `carry_out` is set if $A + B > 15$. |
| `3'b001` | **SUB** | Subtraction | `{carry_out, result} = A - B;` | Unsigned 4-bit subtraction ($A - B$). `carry_out = 1` indicates borrow ($A < B$). |
| `3'b010` | **AND** | Bitwise AND | `result = A & B; carry_out = 1'b0;` | Bitwise logical conjunction. |
| `3'b011` | **OR** | Bitwise OR | `result = A \| B; carry_out = 1'b0;` | Bitwise logical disjunction. |
| `3'b100` | **XOR** | Bitwise XOR | `result = A ^ B; carry_out = 1'b0;` | Bitwise exclusive-OR. |
| `3'b101` | **NOT** | Bitwise NOT | `result = ~A; carry_out = 1'b0;` | Bitwise inversion of operand $A$ (one's complement). |
| `3'b110` | **LSHIFT** | Left Shift | `result = A << 1; carry_out = 1'b0;` | Logical shift left by 1 position (LSB padded with $0$). |
| `3'b111` | **RSHIFT** | Right Shift | `result = A >> 1; carry_out = 1'b0;` | Logical shift right by 1 position (MSB padded with $0$). |

---

## 4. Hardware Implementation Philosophy

### 4.1 Pure Combinational Design
An ALU core does not store past state; its outputs must respond instantaneously to changes in inputs (subject only to propagation delay).
- We use an `always @(*)` procedural block (Verilog-2001 wildcard sensitivity list).
- Wildcard sensitivity `@(*)` guarantees that any transition on `A`, `B`, or `opcode` triggers immediate re-evaluation.

### 4.2 Avoiding Inadvertent Latch Inference
In synthesizable Verilog, transparent latches are synthesized whenever an asynchronous procedural variable is not assigned a value under all possible conditional execution paths. To eliminate latch inference:
1. **Default assignments**: At the very top of `always @(*)`, default assignments are specified:
   ```verilog
   result    = 4'b0000;
   carry_out = 1'b0;
   ```
2. **Exhaustive case with `default`**: The `case (opcode)` covers all 8 binary combinations from `3'b000` to `3'b111`, plus a defensive `default:` branch for $X$ or $Z$ handling.

### 4.3 Carry & Borrow Handling
For addition, an extended 5-bit register or 5-bit concatenated assignment `{carry_out, result} = A + B;` allows bit 4 to cleanly represent the arithmetic carry:
- E.g., $12 + 5 = 17$ (`4'b1100 + 4'b0101 = 5'b10001`): `result = 4'b0001`, `carry_out = 1'b1`.

For subtraction ($A - B$):
- In unsigned hardware arithmetic, if $A \ge B$, no borrow is required: `carry_out = 1'b0`.
- If $A < B$, an underflow occurs: the 5-bit subtraction borrows from the phantom 5th bit, setting `carry_out = 1'b1`. For example, $3 - 5 = -2$, represented in 4-bit two's complement as `14` (`4'b1110`) with `carry_out = 1'b1`.

### 4.4 Zero Flag Logic
The zero flag is computed continuously outside the procedural block:
```verilog
assign zero_flag = (result == 4'b0000);
```
This guarantees that whenever `result` updates to zero (whether via arithmetic, masking, shifting, or inversion), `zero_flag` asserts HIGH ($1$) without skew.

---

## 5. Verification & Test Methodology

### 5.1 Verification Strategy
The testbench (`testbench/alu_tb.v`) is designed according to industry-standard self-checking principles:
1. **Direct Stimulus & Assertion**: Encapsulated inside a modular task `check_alu`.
2. **Settling Delay**: Introduces a 10 ns propagation window (`#10`) between stimulus application and sampling, simulating gate-level propagation delays.
3. **Exact Equivalence Matching (`===`)**: Uses case equality `===` to detect unintended unknown (`X`) or high-impedance (`Z`) states.
4. **Boundary & Corner Cases**:
   - Zero operations: `0 + 0`, `0 - 0`, `0 & 0`, `0 | 0`.
   - Maximum value operations: `15 + 15` (maximum sum), `15 - 0`, `15 & 15`.
   - Underflow/Borrow operations: `3 - 5`, `0 - 1`.
   - Bit boundary shifts: shifting `4'b1000` left (yielding `4'b0000` and `zero_flag=1`), shifting `4'b0001` right (yielding `4'b0000` and `zero_flag=1`).
   - Bitwise orthogonality: `4'b1010 & 4'b0101 = 4'b0000`.

### 5.2 Test Summary Table

| Test Group | Stimulus $A$ | Stimulus $B$ | Opcode | Expected Result | Expected Carry | Expected Zero | Test Intent |
|:---|:---:|:---:|:---:|:---:|:---:|:---:|:---|
| ADD | 0011 (3) | 0100 (4) | 000 | 0111 (7) | 0 | 0 | Typical addition |
| ADD | 0000 (0) | 0000 (0) | 000 | 0000 (0) | 0 | 1 | Zero flag assertion |
| ADD | 1100 (12) | 0101 (5) | 000 | 0001 (1) | 1 | 0 | Carry-out verification |
| ADD | 1111 (15) | 1111 (15) | 000 | 1110 (14) | 1 | 0 | Max value overflow |
| ADD | 1000 (8) | 1000 (8) | 000 | 0000 (0) | 1 | 1 | Simultaneous carry & zero |
| SUB | 0111 (7) | 0010 (2) | 001 | 0101 (5) | 0 | 0 | Typical subtraction |
| SUB | 1010 (10) | 1010 (10) | 001 | 0000 (0) | 0 | 1 | Identity zero flag |
| SUB | 0011 (3) | 0101 (5) | 001 | 1110 (14) | 1 | 0 | Borrow verification |
| SUB | 0000 (0) | 0001 (1) | 001 | 1111 (15) | 1 | 0 | Zero minus non-zero |
| AND | 1011 (11) | 1101 (13) | 010 | 1001 (9) | 0 | 0 | Masking |
| AND | 1010 (10) | 0101 (5) | 010 | 0000 (0) | 0 | 1 | Orthogonal zero flag |
| OR | 1010 (10) | 0101 (5) | 011 | 1111 (15) | 0 | 0 | Full bit set |
| OR | 0000 (0) | 0000 (0) | 011 | 0000 (0) | 0 | 1 | All-zero input |
| XOR | 1100 (12) | 1010 (10) | 100 | 0110 (6) | 0 | 0 | Bit toggle |
| XOR | 1111 (15) | 1111 (15) | 100 | 0000 (0) | 0 | 1 | Self-cancellation |
| NOT | 1010 (10) | 0000 (0) | 101 | 0101 (5) | 0 | 0 | Single operand inversion |
| NOT | 1111 (15) | 0000 (0) | 101 | 0000 (0) | 0 | 1 | Inversion to zero |
| LSHIFT | 0011 (3) | 0000 (0) | 110 | 0110 (6) | 0 | 0 | Left shift by 1 |
| LSHIFT | 1000 (8) | 0000 (0) | 110 | 0000 (0) | 0 | 1 | Left shift to zero |
| RSHIFT | 0110 (6) | 0000 (0) | 111 | 0011 (3) | 0 | 0 | Right shift by 1 |
| RSHIFT | 0001 (1) | 0000 (0) | 111 | 0000 (0) | 0 | 1 | Right shift to zero |

---

## 6. Simulation Artifacts & Waveforms

The testbench generates a Value Change Dump (`.vcd`) file located at `waveforms/alu_waveform.vcd`.
When viewed in **GTKWave**:
- **Time 0–50 ns**: Addition operations exhibiting transition from zero result to carry assertion.
- **Time 50–100 ns**: Subtraction operations demonstrating borrow flag and zero flag behavior.
- **Time 100–190 ns**: Logic functions (AND, OR, XOR) with `carry_out` staying LOW ($0$).
- **Time 190–220 ns**: Inversion operations showing complementary bit patterns.
- **Time 220–280 ns**: Left and right shift operations confirming zero padding and boundary zero detection.

