`timescale 1ns/1ps

module tb_semaforo;

    reg        clk;
    reg        rst;

    wire       green;
    wire       yellow;
    wire       red;
    wire [1:0] state;
    wire [3:0] cont;


    semaforo uut (
        .clk(clk),
        .rst(rst),
        .green(green),
        .yellow(yellow),
        .red(red),
        .state(state),
        .cont(cont)
    );

    
    always #5 clk = ~clk;

    initial begin
        $dumpfile("semaforo.vcd");
        $dumpvars(0, tb_semaforo);

        
        clk = 0;
        rst = 1;

    
        #15;
        rst = 0;


        #300;

        $display("Simulación finalizada.");
        $finish;
    end

endmodule