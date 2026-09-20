module serial_tx #(
    parameter CLKS_PER_BIT = 8
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire [7:0] data_in,
    output reg tx,
    output reg busy,
    output reg done
);

    //definicion de los estados
    localparam S0_IDLE       = 3'b000;
    localparam S1_LOAD       = 3'b001;
    localparam S2_BIT_HOLD   = 3'b010;
    localparam S3_SHIFT_NEXT = 3'b011;
    localparam S4_DONE       = 3'b100;

    reg [2:0] state, next_state;
    reg [7:0] shift_reg;
    reg [2:0] bit_cnt;
    reg [$clog2(CLKS_PER_BIT)-1:0] tick_cnt;

    //1.registro de estado
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S0_IDLE;
        end else begin
            state <= next_state;
        end
    end

    //2. logica del proximo estado
    always @(*) begin
        case (state)
            S0_IDLE:       next_state = (start) ? S1_LOAD : S0_IDLE;
            S1_LOAD:       next_state = S2_BIT_HOLD;
            S2_BIT_HOLD:   next_state = (tick_cnt == CLKS_PER_BIT - 1) ? S3_SHIFT_NEXT : S2_BIT_HOLD;
            S3_SHIFT_NEXT: next_state = (bit_cnt == 3'd7) ? S4_DONE : S2_BIT_HOLD;
            S4_DONE:       next_state = S0_IDLE;
            default:       next_state = S0_IDLE;
        endcase
    end

    //3.datapath y salidas
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 8'h00;
            bit_cnt   <= 3'd0;
            tick_cnt  <= 0;
            tx        <= 1'b1;
            busy      <= 1'b0;
            done      <= 1'b0;
        end else begin
            case (state)
                S0_IDLE: begin
                    tx   <= 1'b1;
                    busy <= 1'b0;
                    done <= 1'b0;
                end

                S1_LOAD: begin
                    shift_reg <= data_in;
                    bit_cnt   <= 3'd0;
                    tick_cnt  <= 0;
                    busy      <= 1'b1;
                    tx        <= 1'b1;
                    done      <= 1'b0;
                end

                S2_BIT_HOLD: begin
                    tx   <= shift_reg[0];
                    busy <= 1'b1;
                    done <= 1'b0;
                    if (tick_cnt < CLKS_PER_BIT - 1) begin
                        tick_cnt <= tick_cnt + 1'b1;
                    end
                end

                S3_SHIFT_NEXT: begin
                    tx        <= shift_reg[0];
                    busy      <= 1'b1;
                    done      <= 1'b0;
                    shift_reg <= shift_reg >> 1;
                    bit_cnt   <= bit_cnt + 3'd1;
                    tick_cnt  <= 0;
                end

                S4_DONE: begin
                    tx   <= 1'b1;
                    busy <= 1'b0;
                    done <= 1'b1;
                end
            endcase
        end
    end

endmodule