module forwarding_unit(
    // Inputs
    input wire [1:0] rs1_decode,
    input wire [1:0] rs2_decode,
    input wire rs1_used,
    input wire rs2_used,
    input wire [1:0] rd_execute,
    input wire write_enable_execute,
    input wire [7:0] alu_result_execute,
    input wire [1:0] rd_memory,
    input wire write_enable_memory,
    input wire [7:0] data_memory,
    
    // Outputs
    output reg [1:0] forward_a,
    output reg [1:0] forward_b,
    output reg [7:0] forwarded_data_a,
    output reg [7:0] forwarded_data_b
);

    // Forwarding Logic for Operand A
    always @(*) begin
        // 1. Default Defaults
        forward_a = 2'b00;
        forwarded_data_a = 8'd0;

        if (rs1_used) begin
            // Priority 1: Forward from Execute (Most recent)
            // REMOVED: "&& (rd_execute != 2'd3)" to allow SP forwarding
            if (write_enable_execute && (rd_execute == rs1_decode)) begin
                forward_a = 2'b01;
                forwarded_data_a = alu_result_execute;
            end
            // Priority 2: Forward from Memory
            else if (write_enable_memory && (rd_memory == rs1_decode)) begin
                forward_a = 2'b10;
                forwarded_data_a = data_memory;
            end
        end
    end

    // Forwarding Logic for Operand B
    always @(*) begin
        // 1. Defaults
        forward_b = 2'b00;
        forwarded_data_b = 8'd0;

        if (rs2_used) begin
            if (write_enable_execute && (rd_execute == rs2_decode)) begin
                forward_b = 2'b01;
                forwarded_data_b = alu_result_execute;
            end
            else if (write_enable_memory && (rd_memory == rs2_decode)) begin
                forward_b = 2'b10;
                forwarded_data_b = data_memory;
            end
        end
    end

endmodule