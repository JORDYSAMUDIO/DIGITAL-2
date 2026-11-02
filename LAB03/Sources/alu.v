module alu (
    input wire [3:0] A,
    input wire [3:0] B,
    input wire [2:0] alu_op,
    output reg [7:0] result
);
    always @(*) begin
        case (alu_op)
            3'b000: result = {4'b0000, A + B};     // SUMA
            3'b001: result = {4'b0000, A - B};     // RESTA
            3'b010: result = {4'b0000, A & B};     // AND
            3'b011: result = {4'b0000, A | B};     // OR
            3'b100: result = {4'b0000, A ^ B};     // XOR
            3'b101: result = {4'b0000, ~A};        // NOT A
            3'b110: result = {4'b0000, A << 1};    // SHIFT LEFT A
            3'b111: result = {4'b0000, A >> 1};    // SHIFT RIGHT A
            default: result = 8'h00;
        endcase
    end
endmodule