# Design and Simulation of a 4-bit Arithmetic Logic Unit (ALU) using Verilog HDL

[![Language: Verilog-2001](https://img.shields.io/badge/Language-Verilog--2001-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![Simulator: Icarus Verilog](https://img.shields.io/badge/Simulator-Icarus_Verilog-green.svg)](http://iverilog.icarus.com/)
[![Viewer: GTKWave](https://img.shields.io/badge/Waveform-GTKWave-orange.svg)](http://gtkwave.sourceforge.net/)
[![Tests: 28/28 Passed](https://img.shields.io/badge/Verification-100%25_Passed-brightgreen.svg)]()

---

## 1. Project Overview

An **Arithmetic Logic Unit (ALU)** is the computational core of every central processing unit (CPU). It executes fundamental arithmetic and logic calculations determined by a digital control code (`opcode`).

This repository contains a complete, synthesizable, combinational **4-bit ALU** designed in standard **Verilog-2001 (IEEE 1364-2001)** along with an automated, self-checking verification testbench, simulation scripts, and VCD waveform output.

---

## 2. Project Objectives

- Design a synthesizable 4-bit combinational ALU module using RTL Verilog.
- Implement 8 arithmetic, logical, and bitwise shift operations using clean `always @(*)` and `case` structures.
- Accurately compute status flags:
  - **`carry_out`**: Detects arithmetic overflow (addition) and borrow generation (subtraction).
  - **`zero_flag`**: Active HIGH whenever the output equals `4'b0000`.
- Develop a comprehensive self-checking testbench (`alu_tb.v`) covering standard, corner, and edge cases.
- Simulate the design using **Icarus Verilog (`iverilog`)** and inspect signal transitions using **GTKWave**.
- Provide a clean, reproducible setup suitable for an ECE undergraduate project, academic viva, and technical interviews.

---

## 3. ALU Block Diagram

```
                 +-----------------------+
   A [3:0] ----->|                       |
                 |       4-BIT ALU       |-----> result [3:0]
   B [3:0] ----->|     (Combinational)   |
                 |                       |-----> carry_out
opcode [2:0] --->|                       |-----> zero_flag
                 +-----------------------+
```

### Signal Interface Summary

| Signal Name | Direction | Bit Width | Data Type | Function |
|:---|:---:|:---:|:---:|:---|
| **`A`** | Input | 4-bit `[3:0]` | `wire` | Operand A ($A_3 A_2 A_1 A_0$) |
| **`B`** | Input | 4-bit `[3:0]` | `wire` | Operand B ($B_3 B_2 B_1 B_0$) |
| **`opcode`** | Input | 3-bit `[2:0]` | `wire` | Operation selector (8 functions) |
| **`result`** | Output | 4-bit `[3:0]` | `reg` | 4-bit calculated result ($R_3 R_2 R_1 R_0$) |
| **`carry_out`**| Output | 1-bit | `reg` | Arithmetic carry-out or borrow indicator; $0$ for logic/shift |
| **`zero_flag`** | Output | 1-bit | `wire` | Status flag: $1$ when `result == 4'b0000`, else $0$ |

---

## 4. Supported Operations & Functional Details

| Opcode (`[2:0]`) | Operation | Expression | Hardware Description |
|:---:|:---|:---:|:---|
| `000` | **ADD** | $A + B$ | 4-bit unsigned binary addition. If $A + B > 15$, `carry_out = 1`. |
| `001` | **SUB** | $A - B$ | 4-bit unsigned binary subtraction. If $A < B$, `carry_out = 1` (borrow). |
| `010` | **AND** | $A \ \& \ B$ | Bitwise logical AND (conjunction). `carry_out = 0`. |
| `011` | **OR** | $A \ \| \ B$ | Bitwise logical OR (disjunction). `carry_out = 0`. |
| `100` | **XOR** | $A \ \oplus \ B$ | Bitwise logical XOR (difference detector). `carry_out = 0`. |
| `101` | **NOT** | $\sim A$ | Bitwise logical NOT (1's complement of $A$). `carry_out = 0`. |
| `110` | **LEFT SHIFT** | $A \ll 1$ | Shifts $A$ left by 1 bit, filling LSB with $0$. `carry_out = 0`. |
| `111` | **RIGHT SHIFT** | $A \gg 1$ | Shifts $A$ right by 1 bit, filling MSB with $0$. `carry_out = 0`. |

---

## 5. Verilog Implementation Approach

### 5.1 Combinational Sensitivity
The ALU is modeled using a combinational procedural block:
```verilog
always @(*) begin
    // Default assignments to eliminate unintended latches
    result    = 4'b0000;
    carry_out = 1'b0;

    case (opcode)
        3'b000: {carry_out, result} = A + B; // Extended assignment captures carry
        3'b001: {carry_out, result} = A - B; // Borrow indicator
        3'b010: result = A & B;
        3'b011: result = A | B;
        3'b100: result = A ^ B;
        3'b101: result = ~A;
        3'b110: result = A << 1;
        3'b111: result = A >> 1;
        default: begin
            result    = 4'b0000;
            carry_out = 1'b0;
        end
    endcase
end
```

### 5.2 Latch-Free Design Rule
In synthesizable digital design, any variable assigned inside an `always` block that is not assigned a value in every conditional branch creates a **transparent latch**.
- **Prevention Strategy**: All outputs (`result`, `carry_out`) are assigned sensible default values before the `case` statement.
- An explicit `default:` branch is included to handle unknown or high-impedance simulation inputs.

### 5.3 Continuous Zero Flag
The zero flag is decoupled from the procedural block and computed continuously:
```verilog
assign zero_flag = (result == 4'b0000);
```
This guarantees an immediate, glitch-free response whenever `result` equals zero.

---

## 6. Project Structure

```
EPeoject-1/
│
├── rtl/
│   └── alu.v                     # Synthesizable 4-bit ALU RTL module
│
├── testbench/
│   └── alu_tb.v                  # Self-checking automated testbench
│
├── simulation/
│   ├── run_sim.sh                # Shell script to compile & simulate via iverilog & vvp
│   └── simulate_alu.py           # Python reference simulator & VCD generator
│
├── waveforms/
│   └── alu_waveform.vcd          # Value Change Dump waveform for GTKWave
│
├── docs/
│   └── design_documentation.md   # In-depth architectural & verification guide
│
└── README.md                     # Comprehensive project guide & setup instructions
```

---

## 7. Step-by-Step Software Setup Guide

Below are the exact instructions explaining **what software to install**, **how to set it up**, and **where to paste the code**.

### Option A: Local Setup on Linux / Ubuntu / Debian (Recommended)

#### Step 1: Install Icarus Verilog and GTKWave
Open your terminal and run:
```bash
sudo apt update
sudo apt install -y iverilog gtkwave
```

#### Step 2: Run the Simulation
Navigate to the project root and execute:
```bash
chmod +x simulation/run_sim.sh
./simulation/run_sim.sh
```

#### Step 3: View the Waveforms in GTKWave
```bash
gtkwave waveforms/alu_waveform.vcd &
```
- In the left pane of GTKWave, click on `alu_tb`.
- Select signals (`A`, `B`, `opcode`, `result`, `carry_out`, `zero_flag`) and click **Append**.
- Click **Zoom Fit** (or press `Ctrl + Shift + F`) to see all waveforms clearly.

---

### Option B: Local Setup on Windows

#### Step 1: Download & Install Software
1. **Icarus Verilog for Windows**:
   - Download the installer from: [http://bleyer.org/icarus/](http://bleyer.org/icarus/) (e.g. `iverilog-v12-20220611-x64_setup.exe`).
   - During installation, **check the box**: *"Add executable folder(s) to user/system PATH"*.
   - The installer automatically includes **GTKWave**.
2. **VS Code** (Optional code editor): Download from [https://code.visualstudio.com/](https://code.visualstudio.com/).

#### Step 2: Open Command Prompt or PowerShell
Navigate to the project directory:
```powershell
cd path\to\EPeoject-1
```

#### Step 3: Compile and Run
```powershell
iverilog -Wall -g2001 -o alu_sim.vvp rtl/alu.v testbench/alu_tb.v
vvp alu_sim.vvp
gtkwave alu_waveform.vcd
```

---

### Option C: Local Setup on macOS

#### Step 1: Install using Homebrew
```bash
brew install icarus-verilog
brew install --cask gtkwave
```

#### Step 2: Compile and Run
```bash
iverilog -Wall -g2001 -o alu_sim rtl/alu.v testbench/alu_tb.v
vvp alu_sim
open -a gtkwave alu_waveform.vcd
```

---

### Option D: 100% Free Online Simulation (EDA Playground - No Install Needed!)

If you do not want to install any software on your computer, use **EDA Playground**:

1. Open your browser and go to: **[https://www.edaplayground.com/](https://www.edaplayground.com/)** (log in with Google/GitHub).
2. Look at the two main code panes on the screen:
   - **Left Pane (`testbench.sv` / `testbench.v`)**:
     - Paste the contents of `testbench/alu_tb.v` here.
   - **Right Pane (`design.sv` / `design.v`)**:
     - Paste the contents of `rtl/alu.v` here.
3. In the left control sidebar under **Tools & Simulators**:
   - Simulator: Select **Icarus Verilog 0.10.0** (or newer).
   - Check the box: **Open EPWave after run**.
4. Click the blue **Run** button at the top.
5. **Result**:
   - The bottom console will display the testbench output table with all `[PASS]` messages.
   - EPWave will automatically pop up displaying the interactive waveform diagram!

---

### Option E: Professional FPGA Suites (Xilinx Vivado / Intel Quartus)

1. **Xilinx Vivado**:
   - Create a New Project -> RTL Project.
   - Click **Add Sources** -> **Add or create design sources** -> Add `rtl/alu.v`.
   - Click **Add Sources** -> **Add or create simulation sources** -> Add `testbench/alu_tb.v`.
   - Click **Run Simulation** -> **Run Behavioral Simulation**.
2. **Intel Quartus Prime + ModelSim / Questa**:
   - Create a project and add `rtl/alu.v`.
   - Under Settings -> EDA Tool Settings -> Simulation, set Tool name to ModelSim-Altera / Questa.
   - Run compilation and launch RTL Simulation.

---

## 8. Sample Simulation Output

When you run the testbench, it produces the following console output:

```text
==========================================================================================
                          4-BIT ALU VERIFICATION TESTBENCH                                
==========================================================================================
 Status | Operation    |  A  (Dec) |  B  (Dec) | Opcode | Result (Dec) | CarryOut | ZeroFlag 
------------------------------------------------------------------------------------------
 [PASS] | ADD_NORMAL   | 0011 ( 3) | 0100 ( 4) |   000   |   0111 ( 7)  |    0    |    0
 [PASS] | ADD_ZERO     | 0000 ( 0) | 0000 ( 0) |   000   |   0000 ( 0)  |    0    |    1
 [PASS] | ADD_OVERFLOW | 1100 (12) | 0101 ( 5) |   000   |   0001 ( 1)  |    1    |    0
 [PASS] | ADD_MAX      | 1111 (15) | 1111 (15) |   000   |   1110 (14)  |    1    |    0
 [PASS] | ADD_OVF_ZERO | 1000 ( 8) | 1000 ( 8) |   000   |   0000 ( 0)  |    1    |    1
 [PASS] | SUB_NORMAL   | 0111 ( 7) | 0010 ( 2) |   001   |   0101 ( 5)  |    0    |    0
 [PASS] | SUB_EQUAL    | 1010 (10) | 1010 (10) |   001   |   0000 ( 0)  |    0    |    1
 [PASS] | SUB_BORROW   | 0011 ( 3) | 0101 ( 5) |   001   |   1110 (14)  |    1    |    0
 [PASS] | SUB_UNDERFLOW| 0000 ( 0) | 0001 ( 1) |   001   |   1111 (15)  |    1    |    0
 [PASS] | SUB_ZERO_B   | 1111 (15) | 0000 ( 0) |   001   |   1111 (15)  |    0    |    0
 [PASS] | AND_NORMAL   | 1011 (11) | 1101 (13) |   010   |   1001 ( 9)  |    0    |    0
 [PASS] | AND_ZERO     | 1010 (10) | 0101 ( 5) |   010   |   0000 ( 0)  |    0    |    1
 [PASS] | AND_ALL_ONES | 1111 (15) | 1111 (15) |   010   |   1111 (15)  |    0    |    0
 [PASS] | OR_NORMAL    | 1010 (10) | 0101 ( 5) |   011   |   1111 (15)  |    0    |    0
 [PASS] | OR_ZERO      | 0000 ( 0) | 0000 ( 0) |   011   |   0000 ( 0)  |    0    |    1
 [PASS] | OR_OVERLAP   | 1100 (12) | 0110 ( 6) |   011   |   1110 (14)  |    0    |    0
 [PASS] | XOR_NORMAL   | 1100 (12) | 1010 (10) |   100   |   0110 ( 6)  |    0    |    0
 [PASS] | XOR_IDENTICAL| 1111 (15) | 1111 (15) |   100   |   0000 ( 0)  |    0    |    1
 [PASS] | XOR_INVERT   | 0101 ( 5) | 1111 (15) |   100   |   1010 (10)  |    0    |    0
 [PASS] | NOT_NORMAL   | 1010 (10) | 0000 ( 0) |   101   |   0101 ( 5)  |    0    |    0
 [PASS] | NOT_ZERO     | 1111 (15) | 0000 ( 0) |   101   |   0000 ( 0)  |    0    |    1
 [PASS] | NOT_ONES     | 0000 ( 0) | 0000 ( 0) |   101   |   1111 (15)  |    0    |    0
 [PASS] | LSHIFT_NORM  | 0011 ( 3) | 0000 ( 0) |   110   |   0110 ( 6)  |    0    |    0
 [PASS] | LSHIFT_MSB1  | 1001 ( 9) | 0000 ( 0) |   110   |   0010 ( 2)  |    0    |    0
 [PASS] | LSHIFT_ZERO  | 1000 ( 8) | 0000 ( 0) |   110   |   0000 ( 0)  |    0    |    1
 [PASS] | RSHIFT_NORM  | 0110 ( 6) | 0000 ( 0) |   111   |   0011 ( 3)  |    0    |    0
 [PASS] | RSHIFT_MSB0  | 1011 (11) | 0000 ( 0) |   111   |   0101 ( 5)  |    0    |    0
 [PASS] | RSHIFT_ZERO  | 0001 ( 1) | 0000 ( 0) |   111   |   0000 ( 0)  |    0    |    1
------------------------------------------------------------------------------------------
Total Tests Executed : 28
Tests Passed         : 28
Tests Failed         : 0
------------------------------------------------------------------------------------------
>>> ALL 28 TESTS PASSED SUCCESSFULLY! <<<
==========================================================================================
```

---

## 9. Comprehensive Input/Output Verification Matrix

| # | Opcode | Operation | Input $A$ | Input $B$ | Expected Result | Expected Carry | Expected Zero | Purpose |
|:---:|:---:|:---|:---:|:---:|:---:|:---:|:---:|:---|
| 1 | `000` | ADD | `0011` (3) | `0100` (4) | `0111` (7) | `0` | `0` | Standard addition |
| 2 | `000` | ADD | `0000` (0) | `0000` (0) | `0000` (0) | `0` | `1` | Zero flag check |
| 3 | `000` | ADD | `1100` (12) | `0101` (5) | `0001` (1) | `1` | `0` | Carry overflow check |
| 4 | `000` | ADD | `1111` (15) | `1111` (15) | `1110` (14) | `1` | `0` | Maximum value addition |
| 5 | `000` | ADD | `1000` (8) | `1000` (8) | `0000` (0) | `1` | `1` | Carry with zero result |
| 6 | `001` | SUB | `0111` (7) | `0010` (2) | `0101` (5) | `0` | `0` | Normal subtraction |
| 7 | `001` | SUB | `1010` (10) | `1010` (10) | `0000` (0) | `0` | `1` | $A = B$ zero flag |
| 8 | `001` | SUB | `0011` (3) | `0101` (5) | `1110` (14) | `1` | `0` | $A < B$ borrow check |
| 9 | `001` | SUB | `0000` (0) | `0001` (1) | `1111` (15) | `1` | `0` | Underflow to max |
| 10 | `010` | AND | `1011` | `1101` | `1001` | `0` | `0` | Bitwise masking |
| 11 | `010` | AND | `1010` | `0101` | `0000` | `0` | `1` | Disjoint operands (Z=1) |
| 12 | `011` | OR | `1010` | `0101` | `1111` | `0` | `0` | Complementary OR |
| 13 | `011` | OR | `0000` | `0000` | `0000` | `0` | `1` | All-zero OR (Z=1) |
| 14 | `100` | XOR | `1100` | `1010` | `0110` | `0` | `0` | Bit difference |
| 15 | `100` | XOR | `1111` | `1111` | `0000` | `0` | `1` | Identity cancellation (Z=1) |
| 16 | `101` | NOT | `1010` | `xxxx` | `0101` | `0` | `0` | Bitwise inversion |
| 17 | `101` | NOT | `1111` | `xxxx` | `0000` | `0` | `1` | Inversion to zero (Z=1) |
| 18 | `110` | LSHIFT | `0011` | `xxxx` | `0110` | `0` | `0` | Shift left by 1 |
| 19 | `110` | LSHIFT | `1000` | `xxxx` | `0000` | `0` | `1` | Shift out to zero (Z=1) |
| 20 | `111` | RSHIFT | `0110` | `xxxx` | `0011` | `0` | `0` | Shift right by 1 |
| 21 | `111` | RSHIFT | `0001` | `xxxx` | `0000` | `0` | `1` | Shift out to zero (Z=1) |

---

## 10. ECE Technical Interview & Viva Preparation

Here are key questions frequently asked in digital design and VLSI interviews regarding ALU implementations:

#### Q1: Why is an ALU modeled as combinational logic rather than sequential logic?
> **Answer**: The ALU core itself is purely mathematical: given inputs $A$, $B$, and `opcode`, the result is a direct boolean function of the current inputs with no internal state or clock storage required. Sequential registers (like an Accumulator, Pipeline Registers, or Program Counter) exist *around* the ALU in a CPU datapath, not inside the combinational ALU block itself.

#### Q2: Why did you use `always @(*)` instead of an explicit sensitivity list?
> **Answer**: Verilog-2001 introduced `always @(*)`, which automatically infers all signals read inside the block (`A`, `B`, `opcode`). If an explicit list like `always @(A or B)` accidentally omitted `opcode`, the simulation would create a mismatch with hardware (simulation mismatch) where changes in opcode would fail to update outputs until $A$ or $B$ toggled.

#### Q3: How do you prevent accidental latch inference in Verilog?
> **Answer**: A latch is inferred when a variable inside a combinational `always` block is not assigned in every possible branch. In this design, latch inference is eliminated by:
> 1. Setting default assignments (`result = 4'b0000; carry_out = 1'b0;`) at the top of the `always @(*)` block.
> 2. Providing an exhaustive `case` statement with a `default` fallback.

#### Q4: How is arithmetic carry vs borrow handled in your ALU?
> **Answer**:
> - In **Addition** ($A + B$), `{carry_out, result} = A + B` utilizes bit 4 as the 5th bit of the sum. When $A + B > 15$, `carry_out` becomes $1$.
> - In **Subtraction** ($A - B$), in unsigned binary arithmetic, if $A < B$, an underflow occurs and a borrow is needed. The 5-bit subtraction produces a borrow bit at bit 4 (`carry_out = 1`). If $A \ge B$, no borrow is required (`carry_out = 0`).

#### Q5: Why is `zero_flag` generated via `assign zero_flag = (result == 4'b0000);`?
> **Answer**: Assigning `zero_flag` via continuous assignment cleanly decouples the status calculation from the operation decoding. It acts as a 4-input NOR gate on the output bits ($Z = \overline{R_3 + R_2 + R_1 + R_0}$), evaluating instantly whenever `result` changes.

---

## 11. Authors & License
- **Author**: ECE Digital System Design Team
- **Language**: Verilog HDL (IEEE 1364-2001)
- **License**: MIT Open Source Academic License

