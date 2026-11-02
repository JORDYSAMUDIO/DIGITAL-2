module reg_bank (
    input wire clk,
    input wire rst,
    input wire [1:0] w_addr,
    input wire [3:0] w_data,
    input wire write_enable,
    input wire [1:0] r_addr_a,
    input wire [1:0] r_addr_b,
    output wire [3:0] r_data_a,
    output wire [3:0] r_data_b
);
    reg [3:0] registers [3:0];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 4; i = i + 1) begin
                registers[i] <= 4'b0000;
            end
        end else if (write_enable) begin
            registers[w_addr] <= w_data;
        end
    end

    assign r_data_a = registers[r_addr_a];
    assign r_data_b = registers[r_addr_b];
endmodule