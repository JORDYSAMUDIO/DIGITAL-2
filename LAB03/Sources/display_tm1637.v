module display_tm1637 (
    input wire clk,           // Reloj 125 MHz
    input wire rst,
    input wire [7:0] data_in, // Valor de 8 bits en HEX (2 dígitos)
    output reg tm1637_clk,
    output reg tm1637_dio
);
    // Divisor para reloj del bus serie (~50 kHz)
    reg [11:0] clk_div = 0;
    reg bus_clk = 0;

    always @(posedge clk) begin
        if (clk_div == 12'd1249) begin
            clk_div <= 0;
            bus_clk <= ~bus_clk;
        end else begin
            clk_div <= clk_div + 1'b1;
        end
    end

    // Decodificador HEX a 7 Segmentos
    function [7:0] hex_to_7seg(input [3:0] hex);
        case (hex)
            4'h0: hex_to_7seg = 8'h3F;
            4'h1: hex_to_7seg = 8'h06;
            4'h2: hex_to_7seg = 8'h5B;
            4'h3: hex_to_7seg = 8'h4F;
            4'h4: hex_to_7seg = 8'h66;
            4'h5: hex_to_7seg = 8'h6D;
            4'h6: hex_to_7seg = 8'h7D;
            4'h7: hex_to_7seg = 8'h07;
            4'h8: hex_to_7seg = 8'h7F;
            4'h9: hex_to_7seg = 8'h6F;
            4'hA: hex_to_7seg = 8'h77;
            4'hB: hex_to_7seg = 8'h7C;
            4'hC: hex_to_7seg = 8'h39;
            4'hD: hex_to_7seg = 8'h5E;
            4'hE: hex_to_7seg = 8'h79;
            4'hF: hex_to_7seg = 8'h71;
            default: hex_to_7seg = 8'h00; // Todos los segmentos apagados
        endcase
    endfunction

    reg [7:0] state = 0;
    reg [7:0] current_byte;
    reg [3:0] bit_cnt;
    reg [15:0] power_on_delay = 0;

    // Asignación de dígitos para mostrar data_in en los dos extremos derechos:
    // DIG1 (Izquierda): Apagado (0x00)
    // DIG2:             Apagado (0x00)
    // DIG3:             data_in[7:4] (Dígito más significativo)
    // DIG4 (Derecha):   data_in[3:0] (Dígito menos significativo)
    wire [7:0] digit0_blank = 8'h00;
    wire [7:0] digit1_blank = 8'h00;
    wire [7:0] digit2_msb   = hex_to_7seg(data_in[7:4]);
    wire [7:0] digit3_lsb   = hex_to_7seg(data_in[3:0]);

    always @(posedge bus_clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            tm1637_clk <= 1;
            tm1637_dio <= 1;
            bit_cnt <= 0;
            power_on_delay <= 0;
        end else begin
            case (state)
                // Espera inicial de encendido
                0: begin
                    tm1637_clk <= 1;
                    tm1637_dio <= 1;
                    if (power_on_delay < 16'd5000) begin
                        power_on_delay <= power_on_delay + 1'b1;
                    end else begin
                        state <= 1;
                    end
                end

                // -------------------------------------------------------------
                // 1. COMANDO DATA (0x40): Auto-incremento de dirección
                // -------------------------------------------------------------
                1: begin tm1637_dio <= 0; state <= 2; end // START
                2: begin tm1637_clk <= 0; current_byte <= 8'h40; bit_cnt <= 0; state <= 3; end
                3: begin tm1637_clk <= 0; tm1637_dio <= current_byte[bit_cnt]; state <= 4; end
                4: begin tm1637_clk <= 1; if (bit_cnt == 7) state <= 5; else begin bit_cnt <= bit_cnt + 1'b1; state <= 3; end end
                5: begin tm1637_clk <= 0; state <= 6; end // Ciclo ACK
                6: begin tm1637_clk <= 1; state <= 7; end
                7: begin tm1637_clk <= 0; tm1637_dio <= 0; state <= 8; end // STOP
                8: begin tm1637_clk <= 1; state <= 9; end
                9: begin tm1637_dio <= 1; state <= 10; end

                // -------------------------------------------------------------
                // 2. COMANDO DIRECCIÓN INICIAL (0xC0)
                // -------------------------------------------------------------
                10: begin tm1637_dio <= 0; state <= 11; end // START
                11: begin tm1637_clk <= 0; current_byte <= 8'hC0; bit_cnt <= 0; state <= 12; end
                12: begin tm1637_clk <= 0; tm1637_dio <= current_byte[bit_cnt]; state <= 13; end
                13: begin tm1637_clk <= 1; if (bit_cnt == 7) state <= 14; else begin bit_cnt <= bit_cnt + 1'b1; state <= 12; end end
                14: begin tm1637_clk <= 0; state <= 15; end // Ciclo ACK
                15: begin tm1637_clk <= 1; state <= 16; end

                // -------------------------------------------------------------
                // 3. ENVÍO DE DATOS DE LOS 4 DÍGITOS
                // -------------------------------------------------------------
                // Dígito 1 (Extremo Izquierdo) -> APAGADO
                16: begin tm1637_clk <= 0; current_byte <= digit0_blank; bit_cnt <= 0; state <= 17; end
                17: begin tm1637_clk <= 0; tm1637_dio <= current_byte[bit_cnt]; state <= 18; end
                18: begin tm1637_clk <= 1; if (bit_cnt == 7) state <= 19; else begin bit_cnt <= bit_cnt + 1'b1; state <= 17; end end
                19: begin tm1637_clk <= 0; state <= 20; end // ACK
                20: begin tm1637_clk <= 1; state <= 21; end

                // Dígito 2 -> APAGADO
                21: begin tm1637_clk <= 0; current_byte <= digit1_blank; bit_cnt <= 0; state <= 22; end
                22: begin tm1637_clk <= 0; tm1637_dio <= current_byte[bit_cnt]; state <= 23; end
                23: begin tm1637_clk <= 1; if (bit_cnt == 7) state <= 24; else begin bit_cnt <= bit_cnt + 1'b1; state <= 22; end end
                24: begin tm1637_clk <= 0; state <= 25; end // ACK
                25: begin tm1637_clk <= 1; state <= 26; end

                // Dígito 3 -> Parte alta de data_in
                26: begin tm1637_clk <= 0; current_byte <= digit2_msb; bit_cnt <= 0; state <= 27; end
                27: begin tm1637_clk <= 0; tm1637_dio <= current_byte[bit_cnt]; state <= 28; end
                28: begin tm1637_clk <= 1; if (bit_cnt == 7) state <= 29; else begin bit_cnt <= bit_cnt + 1'b1; state <= 27; end end
                29: begin tm1637_clk <= 0; state <= 30; end // ACK
                30: begin tm1637_clk <= 1; state <= 31; end

                // Dígito 4 (Extremo Derecho) -> Parte baja de data_in
                31: begin tm1637_clk <= 0; current_byte <= digit3_lsb; bit_cnt <= 0; state <= 32; end
                32: begin tm1637_clk <= 0; tm1637_dio <= current_byte[bit_cnt]; state <= 33; end
                33: begin tm1637_clk <= 1; if (bit_cnt == 7) state <= 34; else begin bit_cnt <= bit_cnt + 1'b1; state <= 32; end end
                34: begin tm1637_clk <= 0; state <= 35; end // ACK
                35: begin tm1637_clk <= 1; state <= 36; end

                // STOP tras enviar la ráfaga de datos
                36: begin tm1637_clk <= 0; tm1637_dio <= 0; state <= 37; end
                37: begin tm1637_clk <= 1; state <= 38; end
                38: begin tm1637_dio <= 1; state <= 39; end

                // -------------------------------------------------------------
                // 4. CONTROL DE DISPLAY Y BRILLO (0x8F)
                // -------------------------------------------------------------
                39: begin tm1637_dio <= 0; state <= 40; end // START
                40: begin tm1637_clk <= 0; current_byte <= 8'h8F; bit_cnt <= 0; state <= 41; end
                41: begin tm1637_clk <= 0; tm1637_dio <= current_byte[bit_cnt]; state <= 42; end
                42: begin tm1637_clk <= 1; if (bit_cnt == 7) state <= 43; else begin bit_cnt <= bit_cnt + 1'b1; state <= 41; end end
                43: begin tm1637_clk <= 0; state <= 44; end // ACK
                44: begin tm1637_clk <= 1; state <= 45; end
                45: begin tm1637_clk <= 0; tm1637_dio <= 0; state <= 46; end // STOP
                46: begin tm1637_clk <= 1; state <= 47; end
                47: begin tm1637_dio <= 1; state <= 1; end  // Bucle continuo

                default: state <= 0;
            endcase
        end
    end
endmodule