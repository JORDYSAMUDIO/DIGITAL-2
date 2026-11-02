module debounce_edge (
    input wire clk,
    input wire async_btn,
    output wire pulse
);
    reg [19:0] count = 0;
    reg btn_state = 0;
    reg btn_sync_0 = 0, btn_sync_1 = 0;

    // Sincronización del botón asíncrono
    always @(posedge clk) begin
        btn_sync_0 <= async_btn;
        btn_sync_1 <= btn_sync_0;
    end

    // Contador antirrebote (~10ms a 125 MHz)
    always @(posedge clk) begin
        if (btn_sync_1 != btn_state) begin
            count <= count + 1'b1;
            if (count == 20'd1_250_000) begin
                btn_state <= btn_sync_1;
                count <= 0;
            end
        end else begin
            count <= 0;
        end
    end

    // Detector de flanco ascendente
    reg btn_state_d = 0;
    always @(posedge clk) begin
        btn_state_d <= btn_state;
    end

    assign pulse = btn_state & ~btn_state_d;
endmodule