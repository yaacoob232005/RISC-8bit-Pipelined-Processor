`timescale 1ns / 1ps

module top_tb;
    reg clk;
    reg rst;
    reg [7:0] input_port;
    reg interrupt_signal;
    wire [7:0] output_port;

    // Instantiate the Top module
    top dut (
        .clk(clk),
        .rst(rst),
        .input_port(input_port),
        .interrupt_signal(interrupt_signal),
        .output_port(output_port)
    );

    // Clock Generation
    always #5 clk = ~clk;

    initial begin
        // Initialize signals
        clk = 0;
        rst = 0;
        input_port = 8'h00;
        interrupt_signal = 0;

        // Reset the system
        #10 rst = 1;

        // --- Load Instructions into Fetch Memory ---
        // Note: Replace dut.fetch.instruction_memory with the correct path if needed
        
        // 1. LDM R0, 10 (Load 10 into R0) -> 2-byte instruction
        dut.fetch.instruction_memory[1] = 8'hC0; // Opcode 12, rb=0
        dut.fetch.instruction_memory[2] = 8'h0A; // Imm = 10

        // 2. LDM R1, 30 (Load 30 into R1)
        dut.fetch.instruction_memory[3] = 8'hC1; // Opcode 12, rb=1
        dut.fetch.instruction_memory[4] = 8'h1E; // Imm = 30
        // 3. ADD R0, R1 (R0 = 10 + 30 = 40)
        dut.fetch.instruction_memory[5] = 8'h21; // Opcode 2, ra=0, rb=1

        // 4. SUB R0, R1 (R0 = 40 - 30 = 10)
        dut.fetch.instruction_memory[6] = 8'h31; // Opcode 3, ra=0, rb=1

        // 5. OUT R0 (Send R0 to output_port)
        dut.fetch.instruction_memory[7] = 8'h78; // Opcode 7, ra=2, rb=0

        // 6. CALL R1 (Jump to address in R1, which is 5)
        // This tests the Control Hazard (flushing/stalling)
        dut.fetch.instruction_memory[8] = 8'hB5; // Opcode 11, brx=1, rb=1
        // 7. STD R0, 100 (Store R0 at Mem[100]) - At subroutine address
        dut.fetch.instruction_memory[30] = 8'hC8; // Opcode 12, rb=0
        dut.fetch.instruction_memory[31] = 8'h64; // ea = 100

        // 8. RET (Return to address 8)
        dut.fetch.instruction_memory[32] = 8'hB8; // Opcode 11, brx=2

        // Wait for execution
        #200;
        $stop;
    end
endmodule
