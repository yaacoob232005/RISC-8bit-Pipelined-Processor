module fetch_stage (
    input wire clk,
    input wire rst,
    
    // Inputs from other stages
    input wire [7:0] pc_from_decode,      // Normal PC+1 or Jump target from Decode
    input wire [7:0] pc_from_memory,      // Return address (RET/RTI) or Loop target
    input wire [7:0] in_port,             // (Optional unused input from previous context)
    
    // Control Signals
    input wire pc_from_decode_control,    // 0 = from Decode, 1 = from Memory
    input wire interupt,                  // 1 = Jump to ISR (M1)
    input wire stall,                     // 1 = Freeze PC (Hazard)
    input wire pc_load_enable,            // 1 = JUMP/BRANCH taken (Force PC update)

    // Outputs
    output reg [7:0] pc_fetch,            // Current PC sent to Decode
    output reg [7:0] ir1,                 // Opcode (The Instruction)
    output reg [7:0] ir2,                 // Operand (Immediate value or Next Instruction)
    output reg [7:0] input_port_to_decoder
);
    
    // Memory Array (128 Bytes)
    reg [7:0] instruction_memory [127:0]; 

    // Internal Registers
    reg [7:0] current_pc;    
    reg [7:0] next_pc; 

    // Helper: Peek at the Opcode bits (7:4) of the CURRENT instruction
    wire [3:0] current_opcode_bits;
    assign current_opcode_bits = instruction_memory[current_pc][7:4];

    // --------------------------------------------------------
    // Combinational Logic: Calculate Next PC
    // --------------------------------------------------------
    always @(*) begin
        // Priority 1: Hardware Interrupt (Highest Priority)
        // Note: Usually vector is at address 1
        if (interupt) begin
            next_pc = instruction_memory[1]; 
        end
        
        // Priority 2: Stall (Freeze Pipeline)
        else if (stall) begin
            next_pc = current_pc;
        end
        
        // Priority 3: Control Hazards (Jumps, Branches, Returns)
        // This signal comes from Decode/Memory when a flow change is needed
        else if (pc_load_enable) begin
            if (pc_from_decode_control) 
                next_pc = pc_from_memory; // RET, RTI
            else 
                next_pc = pc_from_decode; // JMP, CALL, Branch (Taken)
        end
        
        // Priority 4: Normal Execution (Auto-Increment)
        else begin
            // PRE-DECODE LOGIC:
            // Check if the current instruction is 2-bytes (LDM, LDD, STD -> Opcode 12)
            if (current_opcode_bits == 4'd12) begin
                next_pc = current_pc + 2; // Skip the immediate value byte
            end
            else begin
                next_pc = current_pc + 1; // Standard 1-byte increment
            end
        end
    end

    // --------------------------------------------------------
    // Sequential Logic: Update State
    // --------------------------------------------------------
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // Reset State
            current_pc            <= 8'd0;
            pc_fetch              <= 8'd0;
            ir1                   <= 8'd0; // NOP
            ir2                   <= 8'd0;
            input_port_to_decoder <= 8'd0;
        end
        else begin 
            // Update PC
            current_pc <= next_pc;
            
            // Pass current PC down pipeline
            pc_fetch <= current_pc; 
            
            // Fetch Instruction
            // IR1 gets the Instruction Opcode
            ir1 <= instruction_memory[current_pc];
            
            // IR2 gets the Next Byte (Immediate value OR Next Instruction)
            // This is always valid; the Decoder decides if it needs it.
            ir2 <= instruction_memory[current_pc + 1]; 
            
            // Pass input port
            input_port_to_decoder <= in_port;
        end
    end

endmodule