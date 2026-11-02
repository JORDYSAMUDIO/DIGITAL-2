module top (
    input wire clk,              // Reloj principal (Pin K17 - 125MHz)
    input wire [3:0] sw,         // SW[3:0]
    input wire btn0,             // BTN0: Seleccionar registro de escritura
    input wire btn1,             // BTN1: Escribir dato
    input wire btn2,             // BTN2: Cambiar combinación de operandos
    input wire btn3,             // BTN3: Ejecutar ALU y actualizar display
    output wire [3:0] led,       // LEDs indicadores de combinación activa
    output reg [2:0] rgb_led,    // LED RGB indicador del registro de escritura
    output wire tm1637_clk,      // Pin CLK del display TM1637
    output wire tm1637_dio       // Pin DIO del display TM1637
);

    // Filtro antirrebote para cada botón
    wire p_btn0, p_btn1, p_btn2, p_btn3;

    debounce_edge db0 (.clk(clk), .async_btn(btn0), .pulse(p_btn0));
    debounce_edge db1 (.clk(clk), .async_btn(btn1), .pulse(p_btn1));
    debounce_edge db2 (.clk(clk), .async_btn(btn2), .pulse(p_btn2));
    debounce_edge db3 (.clk(clk), .async_btn(btn3), .pulse(p_btn3));

    // Dirección del registro a escribir (incrementa con BTN0)
    reg [1:0] w_addr = 2'b00;
    always @(posedge clk) begin
        if (p_btn0) begin
            w_addr <= w_addr + 1'b1;
        end
    end

    // Color del LED RGB según el registro destino (R0..R3)
    always @(*) begin
        case (w_addr)
            2'b00: rgb_led = 3'b100; // R0 -> Rojo
            2'b01: rgb_led = 3'b010; // R1 -> Verde
            2'b10: rgb_led = 3'b001; // R2 -> Azul
            2'b11: rgb_led = 3'b110; // R3 -> Amarillo (Rojo + Verde)
        endcase
    end

    // Selector de combinaciones de operandos
    wire [1:0] r_addr_a, r_addr_b;
    comb_selector u_comb (
        .clk(clk),
        .rst(1'b0),
        .btn_next(p_btn2),
        .addr_a(r_addr_a),
        .addr_b(r_addr_b),
        .active_leds(led)
    );

    // Banco de Registros
    wire [3:0] op_a, op_b;
    reg_bank u_reg_bank (
        .clk(clk),
        .rst(1'b0),
        .w_addr(w_addr),
        .w_data(sw[3:0]),
        .write_enable(p_btn1),
        .r_addr_a(r_addr_a),
        .r_addr_b(r_addr_b),
        .r_data_a(op_a),
        .r_data_b(op_b)
    );

    // ALU
    wire [7:0] alu_raw_out;
    alu u_alu (
        .A(op_a),
        .B(op_b),
        .alu_op(sw[2:0]),
        .result(alu_raw_out)
    );

    // Registro Latch: Se actualiza ÚNICAMENTE cuando se presiona BTN3
    reg [7:0] latched_result = 8'h00;
    always @(posedge clk) begin
        if (p_btn3) begin
            latched_result <= alu_raw_out;
        end
    end

    // Control del Display TM1637
    display_tm1637 u_display (
        .clk(clk),
        .rst(1'b0),
        .data_in(latched_result),
        .tm1637_clk(tm1637_clk),
        .tm1637_dio(tm1637_dio)
    );

endmodule
