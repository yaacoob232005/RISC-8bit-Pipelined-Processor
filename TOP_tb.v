
`timescale 1ns/1ps

module top_tb_all_inst();
    
  reg clk_tb;
  reg rst_tb;
  reg [7:0] input_port_tb;
  reg interrupt_signal_tb;
  wire [7:0] output_port_tb;

  top dut
  (
    .clk(clk_tb),
    .rst(rst_tb),
    .input_port(input_port_tb),
    .interrupt_signal(interrupt_signal_tb),
    .output_port(output_port_tb)
  );

  always #5 clk_tb = ~clk_tb; // Period = 10ns

  initial 
  begin
    $dumpfile("processor.vcd");
    $dumpvars;

    // Initial inputs
    clk_tb = 0;
    rst_tb = 0;
    input_port_tb = 0;
    interrupt_signal_tb = 0;

    // =========================================================
    // TEST 1: MOV R0, R1 (Move value from R1 to R0)
    // Opcode: 1, RA:0, RB:1 -> Binary: 0001 00 01 -> Hex: 11
    // =========================================================
    $display("--- Starting Test 1: MOV R0, R1 ---");
    rst_tb = 0; // Hold Reset
    
    dut.fetch.instruction_memory[0] = 8'h11; // MOV R0, R1
    dut.fetch.instruction_memory[1] = 8'h00; // NOP (safety)
    
    #10; rst_tb = 1; // Release Reset (Start Processor)
 
    // Inject values directly into registers
    dut.decoder.rf[0] = 8'd0;  // Target
    dut.decoder.rf[1] = 8'd55; // Source

    #100; // Wait for pipeline

    if(dut.decoder.rf[0] == 8'd55) 
        $display("PASS: MOV R0, R1. Result: %d", dut.decoder.rf[0]);
    else 
        $display("FAIL: MOV R0, R1. Expected 55, Got: %d", dut.decoder.rf[0]);

    // =========================================================
    // TEST 2: ADD R0, R1 (R0 = R0 + R1)
    // Opcode: 2, RA:0, RB:1 -> Binary: 0010 00 01 -> Hex: 21
    // =========================================================
    $display("--- Starting Test 2: ADD R0, R1 ---");
    rst_tb = 0; // Reset PC to 0
    
    dut.fetch.instruction_memory[0] = 8'h21; 
    #10; rst_tb = 1;
    dut.decoder.rf[0] = 8'd10; 
    dut.decoder.rf[1] = 8'd20;

    #100;

    if(dut.decoder.rf[0] == 8'd30) 
        $display("PASS: ADD R0, R1. Result: %d", dut.decoder.rf[0]);
    else 
        $display("FAIL: ADD R0, R1. Expected 30, Got: %d", dut.decoder.rf[0]);

    // =========================================================
    // TEST 3: SUB R0, R1 (R0 = R0 - R1)
    // Opcode: 3, RA:0, RB:1 -> Binary: 0011 00 01 -> Hex: 31
    // =========================================================
    $display("--- Starting Test 3: SUB R0, R1 ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h31; 
    #10; rst_tb = 1;
    dut.decoder.rf[0] = 8'd50; 
    dut.decoder.rf[1] = 8'd20;

    #100;

    if(dut.decoder.rf[0] == 8'd30) 
        $display("PASS: SUB R0, R1. Result: %d", dut.decoder.rf[0]);
    else 
        $display("FAIL: SUB R0, R1. Expected 30, Got: %d", dut.decoder.rf[0]);

    // =========================================================
    // TEST 4: AND R0, R1 
    // Opcode: 4, RA:0, RB:1 -> Binary: 0100 00 01 -> Hex: 41
    // =========================================================
    $display("--- Starting Test 4: AND R0, R1 ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h41; 
    #10; rst_tb = 1;
    // 1100 (12) AND 1010 (10) = 1000 (8)
    dut.decoder.rf[0] = 8'd12; 
    dut.decoder.rf[1] = 8'd10;

    #100;

    if(dut.decoder.rf[0] == 8'd8) 
        $display("PASS: AND R0, R1. Result: %d", dut.decoder.rf[0]);
    else 
        $display("FAIL: AND R0, R1. Expected 8, Got: %d", dut.decoder.rf[0]);

    // =========================================================
    // TEST 5: OR R0, R1
    // Opcode: 5, RA:0, RB:1 -> Binary: 0101 00 01 -> Hex: 51
    // =========================================================
    $display("--- Starting Test 5: OR R0, R1 ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h51; 
    #10; rst_tb = 1;
    // 1100 (12) OR 1010 (10) = 1110 (14)
    dut.decoder.rf[0] = 8'd12; 
    dut.decoder.rf[1] = 8'd10;

    #100;

    if(dut.decoder.rf[0] == 8'd14) 
        $display("PASS: OR R0, R1. Result: %d", dut.decoder.rf[0]);
    else 
        $display("FAIL: OR R0, R1. Expected 14, Got: %d", dut.decoder.rf[0]);

    // =========================================================
    // TEST 6: INC R0 (Increment)
    // Opcode: 8, RA:2 (INC), RB:0 (R0) -> Binary: 1000 10 00 -> Hex: 88
    // =========================================================
    $display("--- Starting Test 6: INC R0 ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h88; 
    #10; rst_tb = 1;
    dut.decoder.rf[0] = 8'd10; 

    #100;

    if(dut.decoder.rf[0] == 8'd11) 
        $display("PASS: INC R0. Result: %d", dut.decoder.rf[0]);
    else 
        $display("FAIL: INC R0. Expected 11, Got: %d", dut.decoder.rf[0]);

    // =========================================================
    // TEST 7: DEC R0 (Decrement)
    // Opcode: 8, RA:3 (DEC), RB:0 (R0) -> Binary: 1000 11 00 -> Hex: 8C
    // =========================================================
    $display("--- Starting Test 7: DEC R0 ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h8C; 
    #10; rst_tb = 1; 
    dut.decoder.rf[0] = 8'd10; 

    #100;

    if(dut.decoder.rf[0] == 8'd9) 
        $display("PASS: DEC R0. Result: %d", dut.decoder.rf[0]);
    else 
        $display("FAIL: DEC R0. Expected 9, Got: %d", dut.decoder.rf[0]);

    // =========================================================
    // TEST 8: NOT R0 (Bitwise Invert)
    // Opcode: 8, RA:0 (NOT), RB:0 (R0) -> Binary: 1000 00 00 -> Hex: 80
    // =========================================================
    $display("--- Starting Test 8: NOT R0 ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h80; 
    
    #10; rst_tb = 1; 
    dut.decoder.rf[0] = 8'b00000000; 

    #100;

    if(dut.decoder.rf[0] == 8'b11111111) 
        $display("PASS: NOT R0. Result: %d", dut.decoder.rf[0]);
    else 
        $display("FAIL: NOT R0. Expected 255, Got: %d", dut.decoder.rf[0]);

    // =========================================================
    // TEST 9: NEG R0 (2's Complement Negate)
    // Opcode: 8, RA:1 (NEG), RB:0 (R0) -> Binary: 1000 01 00 -> Hex: 84
    // =========================================================
    $display("--- Starting Test 9: NEG R0 ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h84; 
    
    #10; rst_tb = 1;
    dut.decoder.rf[0] = 8'd10; 

    #100;

    // Expected: -10 -> 256 - 10 = 246
    if(dut.decoder.rf[0] == 8'd246) 
        $display("PASS: NEG R0. Result: %d", dut.decoder.rf[0]);
    else 
        $display("FAIL: NEG R0. Expected 246 (-10), Got: %d", dut.decoder.rf[0]);

    // =========================================================
    // TEST 10: SETC (Set Carry Flag)
    // Opcode: 6, RA:2 (SETC), RB:X -> Binary: 0110 10 00 -> Hex: 68
    // =========================================================
    $display("--- Starting Test 10: SETC ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h68; 
    
    #10; rst_tb = 1;
    
    #100;

    // conditional_flag structure: {Z, N, C, V} -> C is bit 1
    if(dut.decoder.conditional_flag[1] == 1'b1) 
        $display("PASS: SETC. Carry Flag is 1.");
    else 
        $display("FAIL: SETC. Carry Flag is %b", dut.decoder.conditional_flag[1]);

    // =========================================================
    // TEST 11: CLRC (Clear Carry Flag)
    // Opcode: 6, RA:3 (CLRC), RB:X -> Binary: 0110 11 00 -> Hex: 6C
    // =========================================================
    $display("--- Starting Test 11: CLRC ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h6C; 
    
    #10; rst_tb = 1;
    // Force Carry to 1 first to prove it clears (using SETC logic or force)
    // Here we rely on the instruction executing
    dut.decoder.conditional_flag[1] = 1'b1; 

    #100;

    if(dut.decoder.conditional_flag[1] == 1'b0) 
        $display("PASS: CLRC. Carry Flag is 0.");
    else 
        $display("FAIL: CLRC. Carry Flag is %b", dut.decoder.conditional_flag[1]);

    // =========================================================
    // TEST 12: RLC R0 (Rotate Left through Carry)
    // Opcode: 6, RA:0 (RLC), RB:0 (R0) -> Binary: 0110 00 00 -> Hex: 60
    // =========================================================
    $display("--- Starting Test 12: RLC R0 ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h60; 
    
    #10; rst_tb = 1;
    
    // Setup: R0 = 128 (10000000), Carry = 0
    // Result should be 0 (00000000), Carry out = 1
    dut.decoder.rf[0] = 8'd128; 
    dut.decoder.conditional_flag[1] = 1'b0; 

    #100;

    if(dut.decoder.rf[0] == 8'd1 && dut.decoder.conditional_flag[1] == 1'b1)  // Checking Result
        $display("PASS: RLC R0. Result: %d", dut.decoder.rf[0]);
    else 
        $display("FAIL: RLC R0. Expected 0, Got: %d", dut.decoder.rf[0]);

    // =========================================================
    // TEST 13: RRC R0 (Rotate Right through Carry)
    // Opcode: 6, RA:1 (RRC), RB:0 (R0) -> Binary: 0110 01 00 -> Hex: 64
    // =========================================================
    $display("--- Starting Test 13: RRC R0 ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h64; 
    
    #10; rst_tb = 1;

    // Setup: R0 = 1 (00000001), Carry = 0
    // Result should be 0 (00000000), Carry out = 1
    dut.decoder.rf[0] = 8'd1; 
    dut.decoder.conditional_flag[1] = 1'b0; 

    #100;

    if(dut.decoder.rf[0] == 8'd128 && dut.decoder.conditional_flag[1]   == 1 ) 
        $display("PASS: RRC R0. Result: %d", dut.decoder.rf[0]);
    else 
        $display("FAIL: RRC R0. Expected 0, Got: %d", dut.decoder.rf[0]);

    // =========================================================
    // TEST 14: LDM R0, Immediate (Load 2-byte Immediate)
    // Opcode: 12, RA:0 (LDM), RB:0 (R0) -> Hex: C0
    // Byte 2: Immediate Value (e.g., 99)
    // =========================================================
    $display("--- Starting Test 14: LDM R0, #99 ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'hC0; // LDM R0
    dut.fetch.instruction_memory[1] = 8'd99; // Immediate Value
    
    #10; rst_tb = 1;
    dut.decoder.rf[0] = 8'd0; // Clear R0

    #100;

    if(dut.decoder.rf[0] == 8'd99) 
        $display("PASS: LDM R0. Result: %d", dut.decoder.rf[0]);
    else 
        $display("FAIL: LDM R0. Expected 99, Got: %d", dut.decoder.rf[0]);

     // =========================================================
    // TEST 15: PUSH R0
    // Opcode: 7, RA:0 (PUSH), RB:0 (R0) -> Binary: 0111 00 00 -> Hex: 70
    // Operation: Memory[SP] = R0, SP = SP - 1
    // =========================================================
    $display("--- Starting Test 15: PUSH R0 ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h70; 
    
    #10; rst_tb = 1;

    // Setup: R0 = 0xAA (170), SP (R3) = 127
    dut.decoder.rf[0] = 8'hAA; 
    dut.decoder.rf[3] = 8'd127; 

    #100;

    // Check: Memory at address 127 should contain 0xAA
    // Check: SP should be decremented to 126
    if(dut.memory.DMEM[127] == 8'hAA && dut.decoder.rf[3] == 8'd126) 
        $display("PASS: PUSH R0. Mem[127]=%h, SP=%d", dut.memory.DMEM[127], dut.decoder.rf[3]);
    else 
        $display("FAIL: PUSH R0. Expected Mem[127]=AA, SP=126. Got Mem=%h, SP=%d", dut.memory.DMEM[127], dut.decoder.rf[3]);

    // =========================================================
    // TEST 16: POP R0
    // Opcode: 7, RA:1 (POP), RB:0 (R0) -> Binary: 0111 01 00 -> Hex: 74
    // Operation: R0 = Memory[SP], SP = SP + 1
    // =========================================================
    $display("--- Starting Test 16: POP R0 ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h74; 
    
    #10; rst_tb = 1;

    // Setup: SP (R3) = 50.
    // Setup: Pre-load Memory at address 50 with value 0xBB (187)
    dut.decoder.rf[3] = 8'd50;
    dut.memory.DMEM[50] = 8'hBB; 
    dut.decoder.rf[0] = 8'd0; // Clear R0

    #100;

    // Check: R0 should be 0xBB. SP should be incremented to 51.
    if(dut.decoder.rf[0] == 8'hBB && dut.decoder.rf[3] == 8'd51) 
        $display("PASS: POP R0. R0=%h, SP=%d", dut.decoder.rf[0], dut.decoder.rf[3]);
    else 
        $display("FAIL: POP R0. Expected R0=BB, SP=51. Got R0=%h, SP=%d", dut.decoder.rf[0], dut.decoder.rf[3]);

    // =========================================================
    // TEST 17: OUT R0
    // Opcode: 7, RA:2 (OUT), RB:0 (R0) -> Binary: 0111 10 00 -> Hex: 78
    // Operation: Output Port = R0
    // =========================================================
    $display("--- Starting Test 17: OUT R0 ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h78; 
    
    #10; rst_tb = 1;

    // Setup: R0 = 0xCC (204)
    dut.decoder.rf[0] = 8'hCC; 

    #100;

    if(output_port_tb == 8'hCC) 
        $display("PASS: OUT R0. Output Port=%h", output_port_tb);
    else 
        $display("FAIL: OUT R0. Expected CC, Got %h", output_port_tb);

    // =========================================================
    // TEST 18: IN R0
    // Opcode: 7, RA:3 (IN), RB:0 (R0) -> Binary: 0111 11 00 -> Hex: 7C
    // Operation: R0 = Input Port
    // =========================================================
    $display("--- Starting Test 18: IN R0 ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h7C; 
    
    // Setup: Apply 0xDD (221) to the input port pin
    input_port_tb = 8'hDD;

    #10; rst_tb = 1;
    dut.decoder.rf[0] = 8'd0; // Clear R0

    #100;

    if(dut.decoder.rf[0] == 8'hDD) 
        $display("PASS: IN R0. Result: %h", dut.decoder.rf[0]);
    else 
        $display("FAIL: IN R0. Expected DD, Got %h", dut.decoder.rf[0]);

       // =========================================================
    // TEST 19: JZ (Jump if Zero) - TAKEN
    // Opcode: 9, RA:0 (JZ), RB:1 (Target in R1) -> Hex: 91
    // Condition: Z Flag must be 1.
    // =========================================================
    $display("--- Starting Test 19: JZ (Jump if Zero) ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h91; // JZ R1
    
    // Setup:
    // 1. Target Address in R1 = 50
    // 2. Force Z Flag = 1 (conditional_flag[3])
    // Note: conditional_flag = {Z, N, C, V}
    
    #10; rst_tb = 1;
    dut.decoder.rf[1] = 8'd50; 
    dut.decoder.conditional_flag = 4'b1000; // Z=1

    #20; // Wait for pipeline

    // Check: The Fetch Stage should now be fetching from address 50
    if(dut.fetch.current_pc == 8'd50) 
        $display("PASS: JZ Taken. PC jumped to %d", dut.fetch.current_pc);
    else 
        $display("FAIL: JZ Taken. Expected PC=50, Got PC=%d", dut.fetch.current_pc);


    // =========================================================
    // TEST 20: JN (Jump if Negative) - TAKEN
    // Opcode: 9, RA:1 (JN), RB:1 (Target in R1) -> Hex: 95
    // Condition: N Flag must be 1.
    // =========================================================
    $display("--- Starting Test 20: JN (Jump if Negative) ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h95; // JN R1
    
    #10; rst_tb = 1;
    dut.decoder.rf[1] = 8'd60; // Target Address
    dut.decoder.conditional_flag = 4'b0100; // N=1

    #20;

    if(dut.fetch.current_pc == 8'd60) 
        $display("PASS: JN Taken. PC jumped to %d", dut.fetch.current_pc);
    else 
        $display("FAIL: JN Taken. Expected PC=60, Got PC=%d", dut.fetch.current_pc);


    // =========================================================
    // TEST 21: JC (Jump if Carry) - TAKEN
    // Opcode: 9, RA:2 (JC), RB:1 (Target in R1) -> Hex: 99
    // Condition: C Flag must be 1.
    // =========================================================
    $display("--- Starting Test 21: JC (Jump if Carry) ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h99; // JC R1
    
    #10; rst_tb = 1;
    dut.decoder.rf[1] = 8'd70; // Target Address
    dut.decoder.conditional_flag = 4'b0010; // C=1

    #20;

    if(dut.fetch.current_pc == 8'd70) 
        $display("PASS: JC Taken. PC jumped to %d", dut.fetch.current_pc);
    else 
        $display("FAIL: JC Taken. Expected PC=70, Got PC=%d", dut.fetch.current_pc);


    // =========================================================
    // TEST 22: JV (Jump if Overflow) - TAKEN
    // Opcode: 9, RA:3 (JV), RB:1 (Target in R1) -> Hex: 9D
    // Condition: V Flag must be 1.
    // =========================================================
    $display("--- Starting Test 22: JV (Jump if Overflow) ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h9D; // JV R1
    
    #10; rst_tb = 1;
    dut.decoder.rf[1] = 8'd80; // Target Address
    dut.decoder.conditional_flag = 4'b0001; // V=1

    #20;

    if(dut.fetch.current_pc == 8'd80) 
        $display("PASS: JV Taken. PC jumped to %d", dut.fetch.current_pc);
    else 
        $display("FAIL: JV Taken. Expected PC=80, Got PC=%d", dut.fetch.current_pc);


    // =========================================================
    // TEST 23: JZ (Jump if Zero) - NOT TAKEN
    // Condition: Z Flag is 0. PC should NOT jump.
    // =========================================================
    $display("--- Starting Test 23: JZ (Not Taken) ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'h91; // JZ R1
    
    #10; rst_tb = 1;
    dut.decoder.rf[1] = 8'd50; 
    dut.decoder.conditional_flag = 4'b0000; // Z=0 (All Clear)

    #20;

    // The pipeline will execute at 0, then move to 1.
    // If it jumps, it goes to 50. If it fails, it goes to 1, 2, 3...
    // We check if it is definitely NOT 50.
    if(dut.fetch.current_pc != 8'd50) 
        $display("PASS: JZ Not Taken. PC is %d (Expected small number)", dut.fetch.current_pc);
    else 
        $display("FAIL: JZ Not Taken. PC jumped to %d but Z was 0", dut.fetch.current_pc);

        // =========================================================
    // TEST 24: LDM R0, #Immediate (Load Immediate)
    // Opcode: 12, RA:0 (LDM), RB:0 (R0) -> Binary: 1100 00 00 -> Hex: C0
    // Byte 2: Immediate Value (0x55)
    // =========================================================
    $display("--- Starting Test 24: LDM R0, #0x55 ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'hC0; // LDM R0
    dut.fetch.instruction_memory[1] = 8'h55; // Immediate Value
    
    #10; rst_tb = 1;
    dut.decoder.rf[0] = 8'd0; // Clear R0

    #100;

    if(dut.decoder.rf[0] == 8'h55) 
        $display("PASS: LDM R0. Result: %h", dut.decoder.rf[0]);
    else 
        $display("FAIL: LDM R0. Expected 55, Got: %h", dut.decoder.rf[0]);

    // =========================================================
    // TEST 25: STD R0, Address (Store Direct)
    // Opcode: 12, RA:2 (STD), RB:0 (R0) -> Binary: 1100 10 00 -> Hex: C8
    // Byte 2: Address (0x30)
    // Operation: Memory[0x30] = R0
    // =========================================================
    $display("--- Starting Test 25: STD R0, [0x30] ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'hC8; // STD R0
    dut.fetch.instruction_memory[1] = 8'h30; // Address to store to
    
    #10; rst_tb = 1;
    
    // Setup: R0 = 0xAA (Data to store)
    dut.decoder.rf[0] = 8'hAA; 
    // Clear Memory at address 30 first
    dut.memory.DMEM[8'h30] = 8'h00; 

    #100;

    if(dut.memory.DMEM[8'h30] == 8'hAA) 
        $display("PASS: STD R0. Mem[30]=%h", dut.memory.DMEM[8'h30]);
    else 
        $display("FAIL: STD R0. Expected Mem[30]=AA, Got: %h", dut.memory.DMEM[8'h30]);

    // =========================================================
    // TEST 26: LDD R1, Address (Load Direct)
    // Opcode: 12, RA:1 (LDD), RB:1 (R1) -> Binary: 1100 01 01 -> Hex: C5
    // Byte 2: Address (0x40)
    // Operation: R1 = Memory[0x40]
    // =========================================================
    $display("--- Starting Test 26: LDD R1, [0x40] ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'hC5; // LDD R1
    dut.fetch.instruction_memory[1] = 8'h40; // Address to read from
    
    #10; rst_tb = 1;
    
    // Setup: Put value 0xBB in Memory at address 0x40
    dut.memory.DMEM[8'h40] = 8'hBB; 
    dut.decoder.rf[1] = 8'd0; // Clear R1

    #100;

    if(dut.decoder.rf[1] == 8'hBB) 
        $display("PASS: LDD R1. Result: %h", dut.decoder.rf[1]);
    else 
        $display("FAIL: LDD R1. Expected BB, Got: %h", dut.decoder.rf[1]);

    // =========================================================
    // TEST 27: STI R0, [R1] (Store Indirect)
    // Opcode: 14 (STI). RA:1 (Pointer R1), RB:0 (Source R0) 
    // Binary: 1110 (Op) 01 (RA) 00 (RB) -> 1110 01 00 -> Hex: E4
    // Operation: Memory[R1] = R0
    // =========================================================
    $display("--- Starting Test 27: STI R0, [R1] ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'hE4; // STI
    
    #10; rst_tb = 1;

    // Setup: 
    // R0 (Data) = 0xCC
    // R1 (Pointer) = 0x50
    dut.decoder.rf[0] = 8'hCC;
    dut.decoder.rf[1] = 8'h50; 
    
    dut.memory.DMEM[8'h50] = 8'h00; // Clear memory target

    #100;

    if(dut.memory.DMEM[8'h50] == 8'hCC) 
        $display("PASS: STI R0, [R1]. Mem[50]=%h", dut.memory.DMEM[8'h50]);
    else 
        $display("FAIL: STI R0, [R1]. Expected Mem[50]=CC, Got: %h", dut.memory.DMEM[8'h50]);

    // =========================================================
    // TEST 28: LDI R2, [R1] (Load Indirect)
    // Opcode: 13 (LDI). RA:1 (Pointer R1), RB:2 (Dest R2) 
    // Binary: 1101 (Op) 01 (RA) 10 (RB) -> 1101 01 10 -> Hex: D6
    // Operation: R2 = Memory[R1]
    // =========================================================
    $display("--- Starting Test 28: LDI R2, [R1] ---");
    rst_tb = 0; 
    
    dut.fetch.instruction_memory[0] = 8'hD6; // LDI
    
    #10; rst_tb = 1;

    // Setup:
    // R1 (Pointer) = 0x60
    // Memory[0x60] = 0xDD
    dut.decoder.rf[1] = 8'h60;
    dut.memory.DMEM[8'h60] = 8'hDD;
    dut.decoder.rf[2] = 8'd0; // Clear Dest

    #100;

    if(dut.decoder.rf[2] == 8'hDD) 
        $display("PASS: LDI R2, [R1]. Result: %h", dut.decoder.rf[2]);
    else 
        $display("FAIL: LDI R2, [R1]. Expected DD, Got: %h", dut.decoder.rf[2]);

    #50;
    $stop;

  end

endmodule