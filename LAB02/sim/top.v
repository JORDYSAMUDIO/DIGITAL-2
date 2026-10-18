module top (
    input  wire       clk,    // Reloj de 125 MHz
    input  wire [3:0] sw,     // Switches SW0-SW3
    input  wire [3:0] btn,    // Botones BTN0-BTN3
    output wire [3:0] led,    // LEDs de resultado
    output wire       led6_r, // LED RGB Rojo
    output wire       led6_g, // LED RGB Verde
    output wire       led6_b  // LED RGB Azul
);

    // Señales internas para interconexión
    wire [3:0] reg_a;
    wire [3:0] reg_b;
    wire [1:0] reg_opcode;

    // Control de Entradas y Manejo de Registros
    input_control u_input_control (
        .clk        (clk),
        .sw         (sw),
        .btn        (btn),
        .reg_a      (reg_a),
        .reg_b      (reg_b),
        .reg_opcode (reg_opcode)
    );

    // ALU Combinacional
    alu u_alu (
        .a      (reg_a),
        .b      (reg_b),
        .opcode (reg_opcode),
        .result (led)
    );

    // Control del LED RGB
    rgb_decoder u_rgb_decoder (
        .opcode (reg_opcode),
        .led_r  (led6_r),
        .led_g  (led6_g),
        .led_b  (led6_b)
    );

endmodule
