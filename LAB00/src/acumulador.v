module acumulador (
    input  wire       clk,
    input  wire       reset,
    input  wire       start,
    input  wire [1:0] w,
    input  wire [7:0] x,
    output reg  [7:0] acc,
    output reg  [3:0] cont,
    output reg        done
);

    //se codifica los estados
    localparam S0 = 3'b000;
    localparam S1 = 3'b001;
    localparam S2 = 3'b010;
    localparam S3 = 3'b011;
    localparam S4 = 3'b100;
    localparam S5 = 3'b101;

    reg [2:0] state, next_state;

    //resgistro del estado y datapath
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= S0;
            acc   <= 8'd0;
            cont  <= 4'd0;
            done  <= 1'b0;
        end else begin
            state <= next_state;

            case (state)
                S0: begin
                    done <= 1'b0;
                end

                S1: begin
                    acc  <= 8'd0;
                    cont <= 4'd0;
                    done <= 1'b0;
                end

                S2: begin
                    acc  <= acc + x;
                    cont <= cont + 4'd1;
                    done <= 1'b0;
                end

                S3: begin
                    acc  <= acc + x;
                    done <= 1'b0;
                end

                S4: begin
                    acc  <= acc + x;
                    cont <= cont + 4'd1;
                    done <= 1'b0;
                end

                S5: begin
                    done <= 1'b1;
                end

                default: begin
                    acc  <= 8'd0;
                    cont <= 4'd0;
                    done <= 1'b0;
                end
            endcase
        end
    end

    //logica combinacional
    always @(*) begin
        case (state)
            S0: begin
                if (start)
                    next_state = S1;
                else
                    next_state = S0;
            end

            S1: begin
                if (w == 2'b00)
                    next_state = S2;
                else if (w == 2'b01)
                    next_state = S4;
                else if (w == 2'b10)
                    next_state = S3;
                else
                    next_state = S0; 
            end

            S2: begin
                if (cont < 4'd4)
                    next_state = S2;
                else
                    next_state = S5; //salida cuando cont == 4
            end

            S3: begin
                if (acc < 8'd20)
                    next_state = S3;
                else
                    next_state = S5; //salida cuando acc >= 20
            end

            S4: begin
                if (cont < 4'd3)
                    next_state = S4;
                else
                    next_state = S5; //salida cuando cont == 3
            end

            S5: begin
                next_state = S0; //retorna a S0 tras 1 ciclo de reloj
            end

            default: next_state = S0;
        endcase
    end

endmodule