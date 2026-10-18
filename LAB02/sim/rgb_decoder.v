module rgb_decoder (
    input  wire [1:0] opcode,
    output reg        led_r,
    output reg        led_g,
    output reg        led_b
);

    always @(*) begin
        case (opcode)
            2'b00: begin // Suma -> Verde
                led_r = 1'b0;
                led_g = 1'b1;
                led_b = 1'b0;
            end
            2'b01: begin // Resta -> Rojo
                led_r = 1'b1;
                led_g = 1'b0;
                led_b = 1'b0;
            end
            2'b10: begin // AND -> Azul
                led_r = 1'b0;
                led_g = 1'b0;
                led_b = 1'b1;
            end
            2'b11: begin // OR -> Amarillo (Rojo + Verde)
                led_r = 1'b1;
                led_g = 1'b0;
                led_b = 1'b1;
            end
            default: begin
                led_r = 1'b0;
                led_g = 1'b0;
                led_b = 1'b0;
            end
        endcase
    end

endmodule
