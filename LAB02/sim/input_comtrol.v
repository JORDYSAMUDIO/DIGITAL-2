module input_control (
    input  wire       clk,
    input  wire [3:0] sw,
    input  wire [3:0] btn,
    output reg  [3:0] reg_a      = 4'b0000,
    output reg  [3:0] reg_b      = 4'b0000,
    output reg  [1:0] reg_opcode = 2'b00
);

    reg [3:0] btn_d = 4'b0000;

    always @(posedge clk) begin
        btn_d <= btn; // Guarda estado previo 

        // BTN0: Cargar A
        if (btn[0] && !btn_d[0]) begin
            reg_a <= sw;
        end

        // BTN1: Cargar B
        if (btn[1] && !btn_d[1]) begin
            reg_b <= sw;
        end

        // BTN2: Conmutar Bit 0 del Opcode
        if (btn[2] && !btn_d[2]) begin
            reg_opcode[0] <= ~reg_opcode[0];
        end

        // BTN3: Conmutar Bit 1 del Opcode
        if (btn[3] && !btn_d[3]) begin
            reg_opcode[1] <= ~reg_opcode[1];
        end
    end

endmodule
