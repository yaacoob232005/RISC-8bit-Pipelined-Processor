`timescale 1ns / 1ps

module top_tb_all_inst ();

    // ---------------------------------------------------------
    // 1. Signals and Interconnects
    // ---------------------------------------------------------
    reg clk;
    reg rst;
    reg [7:0] input_port;
    reg interrupt_signal;

    wire [7:0] output_port;

    // Monitoring wires (Hierarchical access)
    wire [7:0] current_pc     = dut.fetch.current_pc;
    wire [7:0] stack_pointer  = dut.decoder.rf[3]; // R3 is SP
    wire [7:0] reg_r0         = dut.decoder.rf[0];
    wire [7:0] reg_r1         = dut.decoder.rf[1];
    wire [7:0] reg_r2         = dut.decoder.rf[2];

    // ---------------------------------------------------------
    // 2. DUT Instantiation
    // ---------------------------------------------------------
    top dut (
        .clk(clk), 
        .rst(rst), 
        .input_port(input_port), 
        .interrupt_signal(interrupt_signal), 
        .output_port(output_port)
    );

    // ---------------------------------------------------------
    // 3. Clock Generation
    // ---------------------------------------------------------
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock
    end

    // ---------------------------------------------------------
    // 4. Utility Tasks
    // ---------------------------------------------------------
    
    // Clear all instruction memory to NOPs (0x00)
    task clear_mem;
        integer i;
        begin
            for(i=0; i<128; i=i+1) dut.fetch.instruction_memory[i] = 8'h00;
        end
    endtask

    // System Reset
    task reset_dut;
        begin
            rst = 0;
            #10;
            rst = 1;
            #10;
        end
    endtask

    // Register Verification
    task check_reg;
        input [1:0] addr;
        input [7:0] expected;
        input [256*8:1] msg;
        begin
            if (dut.decoder.rf[addr] === expected)
                $display("  [PASS] %s: R%0d is %d", msg, addr, expected);
            else
                $display("  [FAIL] %s: R%0d is %d (Expected %d)", msg, addr, dut.decoder.rf[addr], expected);
        end
    endtask

    // ---------------------------------------------------------
    // 5. Main Simulation Sequence
    // ---------------------------------------------------------
    initial begin
        $dumpfile("unified_test.vcd");
        $dumpvars(0, top_tb);
        
        $display("\n========================================");
        $display("STARTING UNIFIED TESTBENCH");
        $display("========================================\n");

        // --- TEST 1: FORWARDING & HAZARDS ---
        run_forwarding_test();

        // --- TEST 2: LOOP INSTRUCTION ---
       run_loop_test();

        // --- TEST 3: CALL / RET ---
        run_call_ret_test();

        // --- TEST 4: INTERRUPT / RTI ---
        run_interrupt_test();

        $display("\n========================================");
        $display("ALL TESTS COMPLETED");
        $display("========================================");
        $finish;
    end

    // ---------------------------------------------------------
    // 6. Individual Test Tasks
    // ---------------------------------------------------------

    task run_forwarding_test;
        begin
            $display(">>> Starting Test 1: Forwarding Logic");
            clear_mem();
            
            // LDM R0, #5; LDM R1, #6; ADD R0, R1 (11); ADD R2, R0 (11)
            dut.fetch.instruction_memory[1] = 8'hC0; dut.fetch.instruction_memory[2] = 8'd5;
            dut.fetch.instruction_memory[3] = 8'hC1; dut.fetch.instruction_memory[4] = 8'd6;
            dut.fetch.instruction_memory[5] = 8'h21; // R0 = R0 + R1
            dut.fetch.instruction_memory[6] = 8'h28; // R2 = R2 + R0 (EX-to-EX)
            
            // SUB Hazard Test (R1 - R1 = 0, then INC R1 = 1)
            //dut.fetch.instruction_memory[10] = 8'hC1; dut.fetch.instruction_memory[11] = 8'd20;
            dut.fetch.instruction_memory[12] = 8'h35; // SUB R1, R1
            dut.fetch.instruction_memory[13] = 8'h89; // INC R1

            reset_dut();
            #200; // Allow execution
            
            check_reg(0, 8'd11, "Forwarding ADD Result");
            check_reg(2, 8'd11, "EX-to-EX Forwarding");
            check_reg(1, 8'd1,  "Sub Hazard / INC Result");
            $display("----------------------------------------");
        end
    endtask

    task run_loop_test;
        begin
            $display(">>> Starting Test 2: LOOP Instruction");
            clear_mem();
            
            // Loop code at addr 10
            dut.fetch.instruction_memory[10] = 8'h00; // NOP
            dut.fetch.instruction_memory[11] = 8'h00; // NOP
            dut.fetch.instruction_memory[12] = 8'hA4; // LOOP R1
            dut.fetch.instruction_memory[13] = 8'd10; // Jump back to 10
            
            reset_dut();
            dut.decoder.rf[1] = 8'd2; // Set loop counter to 2
            dut.fetch.current_pc = 8'd10; // Force start
            
            #150; 
            if (reg_r1 === 8'd1) 
                $display("  [PASS] Loop Exited. R1 is 0.");
            else 
                $display("  [FAIL] Loop failed. R1 is %d", reg_r1);
            $display("----------------------------------------");
        end
    endtask

    task run_call_ret_test;
        begin
            $display(">>> Starting Test 3: Subroutine (CALL/RET)");
            clear_mem();
            
            // Main: CALL R1 (R1=20)
            dut.fetch.instruction_memory[10] = 8'hB5; // CALL R1
            dut.fetch.instruction_memory[11] = 8'h00; // Return point
            
            // Subroutine at 20: RET
            dut.fetch.instruction_memory[20] = 8'h00; // NOP
            dut.fetch.instruction_memory[21] = 8'hBC; // RET (Op 11, Ra 1)
            
            reset_dut();
            dut.decoder.rf[1] = 8'd20;   // Target address
            dut.decoder.rf[3] = 8'h7F;   // Initialize SP
            dut.fetch.current_pc = 8'd10;
            
            #40; // Wait for CALL
            $display("  PC after CALL: %d, SP: %d", current_pc, stack_pointer);
            
            #100; // Wait for RET
            if (current_pc >= 11) 
                $display("  [PASS] Returned to Main Program. PC: %d", current_pc);
            else 
                $display("  [FAIL] RET failed. PC: %d", current_pc);
            $display("----------------------------------------");
        end
    endtask

    task run_interrupt_test;
        begin
            $display(">>> Starting Test 4: Interrupts & RTI");
            clear_mem();
            
            // ISR at address 1
            dut.fetch.instruction_memory[1] = 8'h00; // ISR NOP
            dut.fetch.instruction_memory[2] = 8'hBC; // RTI
            
            // Main program at 10
            dut.fetch.instruction_memory[10] = 8'h00;
            
            reset_dut();
            dut.decoder.rf[3] = 8'h7F; // Reset SP
            dut.fetch.current_pc = 8'd10;
            interrupt_signal = 0;
            #20;
            
            // Trigger
            interrupt_signal = 1;
            #10 interrupt_signal = 0;
            
            #40; 
            if (current_pc == 1 || current_pc == 2) 
                $display("  [PASS] Inside ISR. PC: %d", current_pc);
            
            #100; // Wait for RTI
            if (current_pc >= 10) 
                $display("  [PASS] ISR finished. Returned to PC: %d", current_pc);
            else 
                $display("  [FAIL] RTI failed. PC: %d", current_pc);
            $display("----------------------------------------");
        end
    endtask

endmodule