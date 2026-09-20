`timescale 1ns/1ps

module tb_serial_tx;

    parameter CLKS_PER_BIT = 8;

    //entradas y salidas del UUT
    reg clk;
    reg rst;
    reg start;
    reg [7:0] data_in;
    wire tx;
    wire busy;
    wire done;


    serial_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_in(data_in),
        .tx(tx),
        .busy(busy),
        .done(done)
    );


    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_serial_tx);

        clk = 0;
        rst = 1;
        start = 0;
        data_in = 8'h00;

        #20;
        rst = 0;
        #20;

        data_in = 8'hA5;
        start = 1;
        #10;         
        start = 0;

        wait(done);
        #30;

        data_in = 8'h3C;
        start = 1;
        #10;          
        start = 0;

        wait(done);
        #50;

        $display("Simulación completada exitosamente.");
        $finish;
    end

endmodule