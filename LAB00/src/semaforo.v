module semaforo (
    input  wire       clk,
    input  wire       rst,
    output reg        green,
    output reg        yellow,
    output reg        red,
    output reg  [1:0] state,
    output reg  [3:0] cont
);


    localparam S0 = 2'b00;
    localparam S1 = 2'b01;
    localparam S2 = 2'b10;
    localparam S3 = 2'b11;

    reg [1:0] next_state;

    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S0;
            cont  <= 4'd0;
        end else begin
            if (state != next_state) begin
                state <= next_state;
                cont  <= 4'd0; 
            end else begin
                cont <= cont + 4'd1;
            end
        end
    end

    //logica combinacional
    always @(*) begin
        case (state)
            S0: begin
                if (cont < 4'd4)
                    next_state = S0;
                else
                    next_state = S1; 
            end

            S1: begin
                if (cont < 4'd1)
                    next_state = S1;
                else
                    next_state = S2; 
            end

            S2: begin
                if (cont < 4'd3)
                    next_state = S2;
                else
                    next_state = S3; 
            end

            S3: begin
                if (cont < 4'd1)
                    next_state = S3;
                else
                    next_state = S0; 
            end

            default: next_state = S0;
        endcase
    end

    //logica de luces
    always @(*) begin
        green  = 1'b0;
        yellow = 1'b0;
        red    = 1'b0;

        case (state)
            S0: green  = 1'b1; 
            S1: yellow = 1'b1; 
            S2: red    = 1'b1; 
            S3: yellow = 1'b1; 
            default: ;
        endcase
    end

endmodule