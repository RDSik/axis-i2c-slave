`ifndef ENV_SV
`define ENV_SV

`timescale 1ns/1ps

class environment;

    localparam CLK_PER = 2;

    local virtual axis_i2c_top_if dut_if;

    function new(virtual axis_i2c_top_if dut_if);
        this.dut_if = dut_if;
    endfunction

    task init();
        begin
            reset();
        end
    endtask

    task reset();
        begin
            dut_if.arstn = 0;
            $display("Reset at %g ns.", $time);
            #CLK_PER;
            dut_if.arstn = 1;
        end
    endtask

    

endclass

`endif
