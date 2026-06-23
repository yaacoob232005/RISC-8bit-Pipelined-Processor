module execute_stage(
    input wire clk,
    input wire rst,
    //-------------------------------------------additional only by passing signals not for execute----------------------//
    input wire mem_read_signal,
    input wire mem_write_signal,
    input wire [1:0] dist_reg,
    input wire write_reg_enable,
    input wire [7:0] input_from_out_side,   //this for the IN instruction
    input wire [7:0] pc_in_loop,
    input wire [7:0] imm_value,
    input wire out_port_enable,
    //-------------------------------------------------------------------------------------------------------------------//
    input  signed [7:0] operand1, operand2,
    input         [4:0] alu_operation_control,
    input         [3:0] flages, // flags from decode stage
    output reg enable_store_flags, // to enable storing flags on RET instruction

    output reg [7:0] data_to_wb,       // this to control the data to the write back (Connect to Memory ALU_in)
    output reg [1:0] address_to_wb,    // this to control the address of the register
    output reg Z_flag, N_flag, C_flag, V_flag,
    output reg  [7:0] data_to_memory,
    output reg [7:0] address_to_memory,
    output reg write_reg_enable_exe,
    output reg mem_read_exe,
    output reg mem_write_exe,
    output reg [7:0] data_to_output_port,
    output reg [7:0] pc_out_exe,
    output reg pc_to_read_from_memory,
    output reg out_port_enable_exe
);

    reg [7:0] ALU_out;
    //-------------------registers for the pipelining---------------------------//
    reg mem_read_signal_delay;
    reg mem_write_signal_delay;
    reg [7:0] operand1_delay;
    reg [7:0] operand2_delay;
    reg [1:0] dist_reg_delay;
    reg write_reg_enable_delay;
    reg [4:0] alu_operation_control_delay;
    reg [7:0] input_from_out_side_delay;
    reg [7:0] pc_in_loop_delay;
    reg [7:0] imm_value_delay;
    reg out_port_enable_delay;
    //----------------------------------------------------------------------------//

    always @(*) begin
        // Initialize Defaults to avoid latches
        Z_flag = 0;
        N_flag = 0;
        C_flag = 0;
        V_flag = 0;
        ALU_out = 0;
        data_to_memory = 0;
        address_to_memory = 0;
        mem_read_exe = 0;
        mem_write_exe = 0;
        write_reg_enable_exe = 0;
        data_to_wb = 0;
        address_to_wb = 0;
        data_to_output_port = 0;
        pc_out_exe = pc_in_loop;
        pc_to_read_from_memory = 0;
        enable_store_flags = 0;
        out_port_enable_exe = 0;
        case (alu_operation_control_delay)
            5'd0: begin
               // NOP
            end
            5'd1: begin // MOV
                data_to_wb = operand1_delay; // Fixed: Use Operand1 for MOV
                address_to_wb = dist_reg_delay;
                write_reg_enable_exe = write_reg_enable_delay;
            end
            5'd2: begin // ADD
                {C_flag, ALU_out} = operand1_delay + operand2_delay;
                Z_flag = (ALU_out == 0);
                N_flag = ALU_out[7];
                V_flag = (operand1_delay[7] & operand2_delay[7] & ~ALU_out[7]) | 
                         (~operand1_delay[7] & ~operand2_delay[7] & ALU_out[7]); 
                enable_store_flags = 1;         
                data_to_wb = ALU_out;
                address_to_wb = dist_reg_delay; 
                write_reg_enable_exe = write_reg_enable_delay;  
                
            end
            5'd3: begin // SUB
                {C_flag, ALU_out} = operand1_delay - operand2_delay;
                Z_flag = (ALU_out == 0);
                N_flag = ALU_out[7];
                V_flag = (operand1_delay[7] & ~operand2_delay[7] & ~ALU_out[7]) | 
                         (~operand1_delay[7] & operand2_delay[7] & ALU_out[7]); 
                enable_store_flags = 1;
                data_to_wb = ALU_out;
                address_to_wb = dist_reg_delay;
                write_reg_enable_exe = write_reg_enable_delay; 
            end
            5'd4: begin // AND
                ALU_out = operand1_delay & operand2_delay;
                Z_flag = (ALU_out == 0);
                N_flag = ALU_out[7];
                enable_store_flags = 1;
                data_to_wb = ALU_out;
                address_to_wb = dist_reg_delay;
                write_reg_enable_exe = write_reg_enable_delay;   
            end
            5'd5: begin // OR
                ALU_out = operand1_delay | operand2_delay;
                Z_flag = (ALU_out == 0);
                N_flag = ALU_out[7];
                enable_store_flags = 1;
                data_to_wb = ALU_out;
                address_to_wb = dist_reg_delay;
                write_reg_enable_exe = write_reg_enable_delay;  
            end
            5'd6: begin // RLC
                C_flag = operand1_delay[7];
                enable_store_flags = 1;
                ALU_out = {operand1_delay[6:0], operand1_delay[7]}; 
                data_to_wb = ALU_out;
                address_to_wb = dist_reg_delay;
                write_reg_enable_exe = write_reg_enable_delay;
            end
            5'd7: begin // RRC
                C_flag = operand1_delay[0];
                enable_store_flags = 1;
                ALU_out = {operand1_delay[0], operand1_delay[7:1]};
                data_to_wb = ALU_out;
                address_to_wb = dist_reg_delay;
                write_reg_enable_exe = write_reg_enable_delay;
            end
            5'd8: begin // SETC
                C_flag = 1; 
                enable_store_flags = 1;   
            end
            5'd9: begin // CLRC
                C_flag = 0;   
                enable_store_flags = 1; 
            end
            5'd10: begin // PUSH
                data_to_memory = operand1_delay; // Data
                address_to_memory = operand2_delay; // SP
                mem_read_exe = mem_read_signal_delay;
                mem_write_exe = mem_write_signal_delay;
            end
            5'd11: begin // POP
                data_to_memory = 0; 
                address_to_memory = operand1_delay; // Pre-Increment POP
                mem_read_exe = mem_read_signal_delay;
                mem_write_exe = mem_write_signal_delay;
                write_reg_enable_exe = write_reg_enable_delay;
                address_to_wb = dist_reg_delay;
            end
            5'd12: begin // OUT
                data_to_output_port = operand1_delay;  
                out_port_enable_exe = out_port_enable_delay;
            end
            5'd13: begin // IN
                data_to_wb = input_from_out_side_delay;
                address_to_wb = dist_reg_delay;
                write_reg_enable_exe = write_reg_enable_delay;
            end
            5'd14:  begin // NOT
                ALU_out = ~operand1_delay; // Corrected to Operand1
                Z_flag = (ALU_out == 0);
                N_flag = ALU_out[7];
                enable_store_flags = 1;
                data_to_wb = ALU_out;
                address_to_wb = dist_reg_delay;
                write_reg_enable_exe = write_reg_enable_delay;    
            end
            5'd15: begin // NEG
                ALU_out = -operand1_delay; // Corrected to Operand1
                Z_flag = (ALU_out == 0);
                N_flag = ALU_out[7];   
                enable_store_flags = 1;
                data_to_wb = ALU_out;
                address_to_wb = dist_reg_delay;
                write_reg_enable_exe = write_reg_enable_delay; 
            end
            5'd16: begin // INC
                ALU_out = operand1_delay + 1;  // Corrected to Operand1
                Z_flag = (ALU_out == 0);
                N_flag = ALU_out[7]; 
                enable_store_flags = 1;
                data_to_wb = ALU_out;
                address_to_wb = dist_reg_delay;
                write_reg_enable_exe = write_reg_enable_delay; 
            end
            5'd17: begin // DEC
                ALU_out = operand1_delay - 1;  // Corrected to Operand1
                Z_flag = (ALU_out == 0);
                N_flag = ALU_out[7];
                enable_store_flags = 1;
                data_to_wb = ALU_out;
                address_to_wb = dist_reg_delay;
                write_reg_enable_exe = write_reg_enable_delay;  
            end
            5'd22: begin // LOOP
                ALU_out = operand1_delay - 1; // Decrement Counter (RB)
                Z_flag = (ALU_out == 0);
                N_flag = ALU_out[7];
                enable_store_flags = 1;
                data_to_wb = ALU_out;
                address_to_wb = dist_reg_delay; 
                write_reg_enable_exe = write_reg_enable_delay; 
                if(ALU_out != 0) begin
                    pc_out_exe = operand2_delay; // Branch target
                end else begin
                    pc_out_exe = pc_in_loop_delay + 1;
                end
            end
            5'd24: begin // CALL
                address_to_memory = operand1_delay; // SP
                data_to_memory = operand2_delay;    // Return Address (PC+1)
                mem_write_exe = mem_write_signal_delay;
            end        
            5'd25: begin // RET
                address_to_memory = operand1_delay + 1; // SP + 1
                mem_read_exe = mem_read_signal_delay;
                {Z_flag,N_flag,C_flag,V_flag} = flages;
            end   
            5'd26: begin // RTI
                address_to_memory = operand1_delay + 1; 
                mem_read_exe = mem_read_signal_delay;
            end          
            5'd27: begin // LDM
                address_to_wb = dist_reg_delay;
                data_to_wb = imm_value_delay;
                write_reg_enable_exe = write_reg_enable_delay;

            end
            5'd28: begin  // LDD
                address_to_wb = dist_reg_delay;
                address_to_memory = imm_value_delay;
                write_reg_enable_exe = write_reg_enable_delay;
                mem_read_exe = mem_read_signal_delay;
                // data_to_wb is 0 here, Memory Stage will provide data
            end
            5'd29: begin   // STD
                data_to_memory = operand1_delay;
                address_to_memory = imm_value_delay;
                mem_write_exe = mem_write_signal_delay;
            end
            5'd30: begin   // LDI
                address_to_wb = dist_reg_delay;
                address_to_memory = operand1_delay;
                mem_read_exe = mem_read_signal_delay;
                write_reg_enable_exe = write_reg_enable_delay;
            end
            5'd31: begin   // STI
                address_to_memory = operand1_delay;
                data_to_memory = operand2_delay;
                mem_write_exe = mem_write_signal_delay;
            end  
        endcase
    end

    // Sequential Block for Pipeline Registers
    always @(posedge clk or negedge rst)
    begin
        if(!rst)
        begin
            mem_read_signal_delay <= 0;
            mem_write_signal_delay <= 0;
            operand1_delay <= 0;
            operand2_delay <= 0;
            dist_reg_delay <= 0;
            write_reg_enable_delay <= 0;
            alu_operation_control_delay <= 0;
            input_from_out_side_delay <= 0 ;
            pc_in_loop_delay <= 0;
            imm_value_delay <= 0;
            out_port_enable_delay <= 0;
        end
        else
        begin
            mem_read_signal_delay <= mem_read_signal;
            mem_write_signal_delay <= mem_write_signal; // FIXED: Typo here
            operand1_delay <= operand1;
            operand2_delay <= operand2;
            dist_reg_delay <= dist_reg;
            write_reg_enable_delay <= write_reg_enable;
            alu_operation_control_delay <= alu_operation_control;
            input_from_out_side_delay <= input_from_out_side;
            pc_in_loop_delay <= pc_in_loop;
            imm_value_delay <= imm_value;
            out_port_enable_delay <= out_port_enable;
        end
    end

endmodule