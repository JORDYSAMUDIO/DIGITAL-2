module alu (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire [1:0] opcode,
    output wire [3:0] result
);

    assign result = (opcode == 2'b00) ? (a + b) :
                    (opcode == 2'b01) ? (a - b) :
                    (opcode == 2'b10) ? (a & b) :
                    (opcode == 2'b11) ? (a | b) : 4'b0000;

endmodule
