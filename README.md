# RISC-Based 8-bit Pipelined Processor

A complete 8-bit RISC processor implemented in Verilog with a 5-stage pipeline architecture and FPGA deployment.

## Features

* 5-stage pipelined architecture

  * Instruction Fetch (IF)
  * Instruction Decode (ID)
  * Execute (EX)
  * Memory Access (MEM)
  * Write Back (WB)

* ALU and Register File

* Forwarding Unit

* Hazard Detection Unit

* Branch Handling

* CALL / RET Instructions

* Stack Operations

* Interrupt Support

## Tools

* Verilog HDL
* Vivado
* ModelSim
* Xilinx Artix-7 FPGA

## Verification

The processor was verified using dedicated testbenches covering:

* Arithmetic Instructions
* Logical Instructions
* Memory Operations
* Branch Instructions
* Function Calls
* Pipeline Hazards
* Forwarding Scenarios
* Edge Cases

## FPGA Results

* Target Device: Xilinx Artix-7
* Maximum Operating Frequency: 190 MHz

## Project Structure

```text
rtl/     -> RTL source files
tb/      -> Testbenches
docs/    -> Project documentation
images/  -> Architecture and simulation screenshots
```

## Author

Amr Hassan
Electronics and Communications Engineering
Cairo University
