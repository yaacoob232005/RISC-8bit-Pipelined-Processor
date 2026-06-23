module decode_stage(
    input wire clk,
    input wire rst,
    input wire [7:0] pc,
    input wire [7:0] IR,
    input wire [7:0] wb_data,
    input wire [1:0] wb_register_address,
    input wire [7:0] imm_value,
    input wire wb_enable,
    input wire [7:0] input_port,
    // Flags input from execution stage
    input wire Z_in,C_in,V_in,N_in,
    input wire enable_store_flags, 
    //----------------------------------------------------//
    output reg [4:0] alu_operation_control,
    output reg mem_read_signal,
    output reg mem_write_signal,
    output reg [7:0] operand1,
    output reg [7:0] operand2,
    output reg [7:0] imm_value_out,
    output reg [1:0] dist_reg,
    output reg write_reg_enable,
    output reg [3:0] flag_out,
    output reg [7:0] pc_out_loop,
    output reg [7:0] pc_out,
    output reg pc_load_enable,
    output reg output_port_enable,
    output reg pc_to_read_from_memory
);

    wire [3:0] opcode;
    wire [1:0] ra;
    wire [1:0] rb;

    assign opcode = IR[7:4]; // the opcode
    assign ra = IR[3:2];     // the address of ra
    assign rb = IR[1:0];     // the address of rb

    reg [7:0] rf[3:0];                    // the register file, R[3] is the stack pointer
    reg [3:0] conditional_flag;           // Z-N-C-V

    //----------------------------------------------------------------//
    // Combinational Logic: Control Signal Generation
    //----------------------------------------------------------------//
    always @(*) 
    begin
        // 1. Initialize Defaults to prevent Latches
        alu_operation_control = 5'd0;
        mem_read_signal = 0;
        mem_write_signal = 0;
        operand1 = 0;
        operand2 = 0;
        pc_to_read_from_memory=0;
        imm_value_out = 0;
        dist_reg = 0;
        write_reg_enable = 0;
        flag_out = 0;
        pc_out_loop = 0;      
        pc_out = 0;   
        pc_load_enable=0;
        output_port_enable = 0;

        case (opcode)
            4'd0: begin // NOP
                alu_operation_control = 5'd0;
            end

            4'd1: begin // MOV
                alu_operation_control = 5'd1;
                operand1 = rf[rb]; // Data in Operand 1
                dist_reg = ra;
                write_reg_enable = 1;
            end

            4'd2: begin // ADD
                alu_operation_control = 5'd2;
                operand1 = rf[ra];
                operand2 = rf[rb];
                dist_reg = ra;
                write_reg_enable = 1;
            end 

            4'd3: begin // SUB
                alu_operation_control = 5'd3;
                operand1 = rf[ra];
                operand2 = rf[rb];
                dist_reg = ra;
                write_reg_enable = 1;
            end

            4'd4: begin // AND
                alu_operation_control = 5'd4;
                operand1 = rf[ra];
                operand2 = rf[rb];
                dist_reg = ra;
                write_reg_enable = 1;
            end

            4'd5: begin // OR
                alu_operation_control = 5'd5;
                operand1 = rf[ra];
                operand2 = rf[rb];
                dist_reg = ra;
                write_reg_enable = 1;
            end

            4'd6: begin // RLC, RRC, SETC, CLRC
                case (ra)
                    2'd0: begin // RLC
                        alu_operation_control = 5'd6;
                        operand1 = rf[rb];
                        dist_reg = rb;
                        write_reg_enable = 1;
                    end
                    2'd1: begin // RRC
                        alu_operation_control = 5'd7;
                        operand1 = rf[rb];
                        dist_reg = rb;
                        write_reg_enable = 1;
                    end
                    2'd2: begin // SETC
                        alu_operation_control = 5'd8;
                    end
                    2'd3: begin // CLRC
                        alu_operation_control = 5'd9;
                    end
                endcase
            end

            4'd7: begin // PUSH, POP, OUT, IN
                case (ra)
                    2'd0: begin // PUSH
                        alu_operation_control = 5'd10;
                        operand1 = rf[rb];   // Data to push
                        operand2 = rf[3];    // Stack Pointer (Address)
                        mem_write_signal = 1;
                        // SP decrement happens in Sequential block
                    end
                    2'd1: begin // POP
                        alu_operation_control = 5'd11;
                        dist_reg = rb;
                        operand1 = rf[3];    // Stack Pointer
                        write_reg_enable = 1;
                        mem_read_signal = 1; 
                    end
                    2'd2: begin // OUT
                        alu_operation_control = 5'd12;
                        output_port_enable = 1;
                        operand1 = rf[rb];
                    end
                    2'd3: begin // IN
                        alu_operation_control = 5'd13;
                        operand1 = input_port;
                        dist_reg = rb;
                        write_reg_enable = 1;
                    end
                endcase
            end

            4'd8: begin // NOT, NEG, INC, DEC
                case (ra)
                    2'd0: begin // NOT
                        alu_operation_control = 5'd14;
                        operand1 = rf[rb];
                        dist_reg = rb;
                        write_reg_enable = 1;
                    end
                    2'd1: begin // NEG
                        alu_operation_control = 5'd15;
                        operand1 = rf[rb];
                        dist_reg = rb;
                        write_reg_enable = 1;
                    end
                    2'd2: begin // INC
                        alu_operation_control = 5'd16;
                        operand1 = rf[rb];
                        dist_reg = rb;
                        write_reg_enable = 1;
                    end
                    2'd3: begin // DEC
                        alu_operation_control = 5'd17;
                        operand1 = rf[rb];
                        dist_reg = rb;
                        write_reg_enable = 1;
                    end   
                endcase
            end

            // B-Format Instructions
            4'd9: begin // JZ, JN, JC, JV
                case (ra)
                    2'd0:begin 
                    if (conditional_flag[3]) 
                    begin
                      pc_out = rf[rb]; // JZ
                     pc_load_enable = 1;
                    end
            
                    end
                    2'd1: begin 
                    if (conditional_flag[2])
                    begin
                      pc_out = rf[rb]; // JN
                      pc_load_enable = 1;
                    end 
                    
                    end
                    2'd2: begin
                    if (conditional_flag[1])
                    begin
                      pc_out = rf[rb]; // JC
                      pc_load_enable = 1;
                    end
                    
                    end
                    2'd3: begin
                    if (conditional_flag[0])
                    begin
                      pc_out = rf[rb]; // JV
                      pc_load_enable = 1;
                    end 
        
                    end
                endcase
            end
             
            4'd10: begin // LOOP
                alu_operation_control = 5'd22;
                operand1 = rf[ra];
                operand2 = rf[rb];
                dist_reg = ra;
                write_reg_enable = 1;
                pc_out_loop = pc; 
            end

            4'd11: begin // JMP, CALL, RET, RTI
                case (ra)
                    2'd0: begin // JMP
                        alu_operation_control = 5'd23;
                        operand1 = rf[rb];
                        pc_out = rf[rb];
                        pc_load_enable = 1;
                        
                    end
                    2'd1: begin // CALL
                        alu_operation_control = 5'd24;
                        operand1 = rf[3]; // Stack pointer
                        operand2 = pc + 1; // Return Address put in Op2
                        pc_out = rf[rb];
                        mem_write_signal = 1;
                        pc_load_enable = 1;
                    end
                    2'd2: begin // RET
                        alu_operation_control = 5'd25;
                        operand1 = rf[3]; // Stack pointer
                        mem_read_signal = 1;
                        pc_to_read_from_memory=1;
                        pc_load_enable = 1;
                    end
                    2'd3: begin // RTI
                        alu_operation_control = 5'd26;
                        operand1 = rf[3]; // Stack pointer
                        mem_read_signal = 1;
                        flag_out = conditional_flag; 
                        pc_to_read_from_memory=1;
                        pc_load_enable = 1;
                    end
                endcase
            end

            // L-Format Instructions
            4'd12: begin
                case (ra)
                    2'd0: begin // LDM
                        alu_operation_control = 5'd27;
                        dist_reg = rb;
                        imm_value_out = imm_value;
                        operand1 = imm_value;
                        write_reg_enable = 1;
                    end
                    2'd1: begin // LDD
                        alu_operation_control = 5'd28;
                        dist_reg = rb;
                        imm_value_out = imm_value;
                        operand1 = imm_value;
                        write_reg_enable = 1;
                        mem_read_signal = 1;
                    end
                    2'd2: begin // STD
                        alu_operation_control = 5'd29;
                        operand1 = rf[rb];
                        imm_value_out = imm_value;
                        operand2 = imm_value;
                        mem_write_signal = 1;
                    end
                endcase
            end

            4'd13: begin // LDI
                alu_operation_control = 5'd30;
                operand1 = rf[ra];
                dist_reg = rb;
                mem_read_signal = 1;
                write_reg_enable = 1;
            end

            4'd14: begin // STI
                alu_operation_control = 5'd31;
                operand1 = rf[ra];
                operand2 = rf[rb];
                mem_write_signal = 1;
            end

        endcase
    end

    //----------------------------------------------------------------//
    // Sequential Logic: Register File & Flag Updates
    //----------------------------------------------------------------//
    always @(posedge clk or negedge rst)
    begin
        if (!rst) begin
            // Initialize registers
            rf[0] <= 8'd0;
            rf[1] <= 8'd0;
            rf[2] <= 8'd0;
            rf[3] <= 8'd127; // Stack pointer initialized to 127
            conditional_flag <= 4'd0;
        end else begin
            // 1. Flag Updates
            if(enable_store_flags)begin
                conditional_flag <= {Z_in,N_in,C_in,V_in};
            end

            // 2. Standard Register Writeback
            if (wb_enable == 1 && wb_register_address != 'd3) begin
                rf[wb_register_address] <= wb_data;
            end
            
            // 3. Stack Pointer Updates (PUSH/POP logic)
            if(opcode == 4'd7 && ra == 0)       rf[3] <= rf[3] - 1; // PUSH
            else if (opcode == 4'd11 && ra == 1) rf[3] <= rf[3] - 1; // CALL
            else if (opcode == 4'd7 && ra == 1)  rf[3] <= rf[3] + 1; // POP
            else if (opcode == 4'd11 && ra == 2) rf[3] <= rf[3] + 1; // RET
            else if (opcode == 4'd11 && ra == 3) rf[3] <= rf[3] + 1; // RTI
        end
    end

endmodule