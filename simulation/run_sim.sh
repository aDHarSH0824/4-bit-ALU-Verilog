#!/usr/bin/env bash
# =============================================================================
# Script: run_sim.sh
# Purpose: Compile and execute 4-bit ALU simulation using Icarus Verilog & GTKWave
# =============================================================================

set -e

# Resolve repository root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

RTL_FILE="${PROJECT_ROOT}/rtl/alu.v"
TB_FILE="${PROJECT_ROOT}/testbench/alu_tb.v"
SIM_OUT="${PROJECT_ROOT}/simulation/alu_sim"
WAVE_OUT="${PROJECT_ROOT}/waveforms/alu_waveform.vcd"

mkdir -p "${PROJECT_ROOT}/waveforms"
mkdir -p "${PROJECT_ROOT}/simulation"

echo "======================================================================"
echo "          4-bit ALU Compilation & Simulation Script                   "
echo "======================================================================"

if command -v iverilog >/dev/null 2>&1 && command -v vvp >/dev/null 2>&1; then
    echo "[1/3] Compiling RTL and Testbench using Icarus Verilog (iverilog)..."
    iverilog -Wall -g2001 -o "${SIM_OUT}" "${RTL_FILE}" "${TB_FILE}"
    echo "      Compilation successful -> ${SIM_OUT}"

    echo "[2/3] Executing simulation with vvp..."
    cd "${PROJECT_ROOT}"
    vvp "${SIM_OUT}"

    if [ -f "alu_waveform.vcd" ]; then
        mv "alu_waveform.vcd" "${WAVE_OUT}"
    fi
    echo "      Waveform saved -> ${WAVE_OUT}"

else
    echo "[!] Icarus Verilog (iverilog / vvp) not detected in system PATH."
    echo "    To install on Ubuntu / Debian: sudo apt update && sudo apt install -y iverilog gtkwave"
    echo "    To install on Windows: Download Icarus Verilog from bleyer.org/icarus"
    echo "    To install on macOS: brew install icarus-verilog gtkwave"
    echo ""
    echo "[*] Falling back to included Python Reference Simulator to demonstrate testbench..."
    python3 "${SCRIPT_DIR}/simulate_alu.py"
fi

echo ""
echo "[3/3] Waveform inspection:"
if [ "$1" == "--view" ] || [ "$1" == "-v" ]; then
    if command -v gtkwave >/dev/null 2>&1; then
        echo "Opening GTKWave with ${WAVE_OUT}..."
        gtkwave "${WAVE_OUT}" &
    else
        echo "GTKWave executable not found. Install gtkwave or open ${WAVE_OUT} manually in your waveform viewer."
    fi
else
    echo "To view waveforms in GTKWave, run:"
    echo "    gtkwave ${WAVE_OUT} &"
    echo "Or run this script with --view flag:"
    echo "    ./simulation/run_sim.sh --view"
fi

echo "======================================================================"
echo "                      Simulation Finished                             "
echo "======================================================================"

