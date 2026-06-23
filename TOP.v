module top(
  input wire clk,
  input wire rst,
  input wire [7:0] input_port,
  input wire interrupt_signal,
  output wire [7:0] output_port
);  
wire out_port_enable;
wire out_port_enable_exe;
wire [7:0] input_port_to_decoder;
    wire stall;                     
    wire [7:0] pc_fetch;                 
    wire [7:0] pc;
    wire [7:0] IR; // Opcode
    wire [7:0] wb_data;
    wire [1:0] wb_register_address;
    wire [7:0] imm_value; // Immediate / Operand
    wire wb_enable;
    wire [4:0] alu_operation_control;
    wire mem_read_signal;
    wire mem_write_signal;
    wire [7:0] imm_value_out;
    wire [1:0] dist_reg;
    wire [7:0] pc_save;
    wire [3:0] flag_out;
    wire [7:0] pc_out;
    wire [7:0] pc_out_loop;
    wire pc_to_read_from_memory;
    wire write_reg_enable;
    wire [7:0] input_from_out_side;
    wire signed [7:0] operand1, operand2;
    wire [7:0] data_to_wb;       
    wire [1:0] address_to_wb; 
    wire Z_flag, N_flag, C_flag, V_flag;
    wire [7:0] data_to_memory;
    wire [7:0] address_to_memory;
    wire write_reg_enable_exe;
    wire mem_read_exe;
    wire mem_write_exe;
    wire [7:0] mem_write_data;      
    wire [7:0] ALU_in;
    wire       write_reg_enable_in;   
    wire [7:0] pc_out_exe;
    wire pc_load_enable;
    wire enable_store_flags;
    wire [7:0] out_port_wire;
            
fetch_stage fetch( .clk(clk), .rst(rst), .pc_from_decode(pc_out),.pc_from_memory(mem_out), .pc_from_decode_control(pc_to_read_from_memory), .interupt(interupt), 
                .stall(stall), .pc_fetch(pc_fetch), .ir1(IR), .ir2(imm_value) , .pc_load_enable(pc_load_enable),.input_port_to_decoder(input_port_to_decoder),.in_port(input_port)
                );


decode_stage decoder(.clk(clk), .rst(rst), .pc(pc_fetch),.IR(IR), .wb_data(wb_data), .wb_register_address(wb_register_address),
                .imm_value(imm_value),.Z_in(Z_flag),.N_in(N_flag),.C_in(C_flag),.V_in(V_flag),.wb_enable(wb_enable),.alu_operation_control(alu_operation_control),
                .mem_read_signal(mem_read_signal),
                .mem_write_signal(mem_write_signal),
                .operand1(operand1),
                .operand2(operand2),
                .imm_value_out(imm_value_out),
                .dist_reg(dist_reg),
                .write_reg_enable(write_reg_enable),
                .flag_out(flag_out),
                .pc_out_loop(pc_out_loop),
                .pc_out(pc_out),
                .pc_load_enable(pc_load_enable),
                .enable_store_flags(enable_store_flags),
                .pc_to_read_from_memory(pc_to_read_from_memory),
                .output_port_enable(out_port_enable),.input_port(input_port_to_decoder)
                );


execute_stage execute( .clk(clk), .rst(rst),.mem_read_signal(mem_read_signal),.mem_write_signal(mem_write_signal), .dist_reg(dist_reg),.write_reg_enable(write_reg_enable),
.input_from_out_side(operand1),.pc_in_loop(pc_out_loop), .imm_value(imm_value_out), .operand1(operand1), .operand2(operand2),.alu_operation_control(alu_operation_control),
.data_to_wb(data_to_wb),.address_to_wb(address_to_wb), .Z_flag(Z_flag), .N_flag(N_flag), .C_flag(C_flag), .V_flag(V_flag),.flages(flag_out), 
.data_to_memory(data_to_memory), .address_to_memory(address_to_memory),.write_reg_enable_exe(write_reg_enable_exe), .mem_read_exe(mem_read_exe), 
.mem_write_exe(mem_write_exe),.data_to_output_port(out_port_wire),.pc_out_exe(pc_out_exe), .enable_store_flags(enable_store_flags),
.out_port_enable_exe(out_port_enable_exe),.out_port_enable(out_port_enable));


memory_stage memory(.clk(clk), .rst(rst),.mem_read(mem_read_exe),.mem_write(mem_write_exe),.address_to_memory(address_to_memory),
 .mem_write_data(data_to_memory),.ALU_in(data_to_wb),.write_reg_enable_in(write_reg_enable_exe),.dist_reg_in(address_to_wb),
 .wb_data(wb_data),.wb_register_address(wb_register_address),.wb_enable_out(wb_enable),.data_to_output_port(out_port_wire),.out_port_enable(out_port_enable_exe),.out_port(output_port)
 );


endmodule