module testfuncional (
    input  wire [3:0] sw,         // Operando A (Switches 3 a 0)
    input  wire [5:0] btn,        // btn[3:0]: Operando B | btn[5:4]: Selector de Modo Externo
    output reg  [3:0] led,        // LEDs verdes: Resultado de la operación (4 bits)
    output reg        led6_r,     // LED RGB: Canal Rojo
    output reg        led6_g,     // LED RGB: Canal Verde
    output reg        led6_b      // LED RGB: Canal Azul
);

    // Operandos de 4 bits
    wire [3:0] op_a = sw[3:0];
    wire [3:0] op_b = btn[3:0];
    
    // Selector codificado con los botones externos: {BTN5, BTN4}
    wire [1:0] modo = {btn[5], btn[4]};

    // Lógica Combinacional para Selección de Operaciones y Color del RGB
    always @(*) begin
        case (modo)
            2'b00: begin 
                // Operación AND
                led    = op_a & op_b;
                led6_r = 1'b1; // Encender ROJO
                led6_g = 1'b0;
                led6_b = 1'b0;
            end
            
            2'b01: begin 
                // Operación OR
                led    = op_a | op_b;
                led6_r = 1'b0;
                led6_g = 1'b1; // Encender VERDE
                led6_b = 1'b0;
            end
            
            2'b10: begin 
                // Operación XOR
                led    = op_a ^ op_b;
                led6_r = 1'b0; // 1'b0
                led6_g = 1'b0;
                led6_b = 1'b1; // Encender AZUL
            end
            
            2'b11: begin 
                // Operación Aritmética: Suma (Requisito obligatorio de la guía)
                led    = op_a + op_b;
                led6_r = 1'b1; // Encender BLANCO (Rojo + Verde + Azul)
                led6_g = 1'b1;
                led6_b = 1'b1;
            end
        endcase
    end

endmodule
