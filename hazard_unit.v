module hazard_unit (
    // Inputs from Decode Stage (Current Instruction)
    input wire [1:0] id_rs1,
    input wire [1:0] id_rs2,
    input wire id_rs1_used,
    input wire id_rs2_used,

    // Inputs from Execute Stage (Previous Instruction)
    input wire ex_mem_read,      // 1 if instruction in EX is LDD/POP
    input wire [1:0] ex_rd,      // Destination Register of instruction in EX

    // Outputs
    output reg stall,            // To Fetch (Freeze PC) and Decode (Freeze IR)
    output reg insert_bubble     // To Execute (Flush instruction)
);

    always @(*) begin
        stall = 0;
        insert_bubble = 0;

        // LOAD-USE HAZARD DETECTION
        // If Execute is reading from memory (Load) ...
        if (ex_mem_read == 1'b1) begin
            // ... and Destination matches Source 1 or Source 2 of Decode
            if ( (id_rs1_used && (id_rs1 == ex_rd)) || (id_rs2_used && (id_rs2 == ex_rd)) ) begin
                
                stall = 1;
                insert_bubble = 1;
            end
        end
    end
endmodule