module memory_stage (
    input  wire       clk,
    input  wire       rst,

    // Inputs from Execute Stage
    input  wire       mem_read,             // Read Enable (for LDD, LDI, POP, RET)
    input  wire       mem_write,            // Write Enable (for STD, STI, PUSH, CALL)
    input  wire [7:0] address_to_memory,    // Address for Read/Write
    input  wire [7:0] mem_write_data,       // Data to write (Operand 2 or PC)
    input  wire [7:0] ALU_in,               // ALU Result (bypassing memory for arithmetic)
    input wire [7:0]  data_to_output_port,          // Destination Register Address from Execute
    input wire [7:0]  out_port_enable,             // Enable signal for output port
    // Pass-through Pipeline Signals (for Write Back)
    input  wire       write_reg_enable_in,  // From Execute (write_reg_enable_exe)
    input  wire [1:0] dist_reg_in,          // From Execute (address_to_wb)

    // Outputs to Decode Stage (Closing the Loop)
    output reg [7:0] wb_data,               // Final data for Register File
    output reg [1:0] wb_register_address,   // Address to write to
    output reg       wb_enable_out,        // Enable signal for Decode stage
    output reg [7:0]     out_port
    );

    // 1. Memory Array (256 Bytes)
    reg [7:0] DMEM [127:0]; 
    integer i;

   
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // Reset state
            wb_data <= 8'd0;
            wb_register_address <= 2'd0;
            wb_enable_out <= 1'b0;
            out_port <= 8'd0;
           
            for (i = 0; i < 128; i = i + 1) begin
                DMEM[i] <= 8'd0;
            end
        end 
        else begin
            // A. Pass Control Signals to Next Stage (Decode)
            wb_register_address <= dist_reg_in;
            wb_enable_out <= write_reg_enable_in;

            // B. Memory Write Operation
            if (mem_write) begin
                DMEM[address_to_memory] <= mem_write_data;
            end

            // C. Write Back Selection Logic (The "Mux")
            // We decide WHAT goes back to the register file based on 'mem_read'
            if (mem_read) begin
                // If it's a Load instruction, data comes from Memory
                wb_data <= DMEM[address_to_memory]; 
            end 
            else if (out_port_enable) begin
                // If it's an OUT instruction, data comes from output port
                out_port <= data_to_output_port;
            end else begin
                // If it's an ALU instruction (ADD, MOV, etc.), data comes from ALU
                wb_data <= ALU_in;
            end
        end
    end

endmodule