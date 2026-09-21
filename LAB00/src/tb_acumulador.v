`timescale 1ns/1ps

module tb_acumulador;

    reg        clk;
    reg        reset;
    reg        start;
    reg  [1:0] w;
    reg  [7:0] x;

    wire [7:0] acc;
    wire [3:0] cont;
    wire       done;

    
    accumulator uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .w(w),
        .x(x),
        .acc(acc),
        .cont(cont),
        .done(done)
    );


    always #5 clk = ~clk;

    initial begin
        $dumpfile("accumulator.vcd");
        $dumpvars(0, tb_accumulator);

    
        clk   = 0;
        reset = 1;
        start = 0;
        w     = 2'b00;
        x     = 8'd0;

        #15;
        reset = 0;
        #10;


        x     = 8'd5;
        w     = 2'b00;
        start = 1;
        #10;
        start = 0;

        wait(done);
        #20;

        x     = 8'd7;
        w     = 2'b01;
        start = 1;
        #10;
        start = 0;

        wait(done);
        #20;

        x     = 8'd6;
        w     = 2'b10;
        start = 1;
        #10;
        start = 0;

        wait(done);
        #30;

        $display("Simulación completada con éxito.");
        $finish;
    end

endmodule