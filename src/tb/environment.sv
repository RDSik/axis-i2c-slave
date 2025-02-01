`ifndef ENV_SV
`define ENV_SV

class environment;

    local virtual axis_i2c_top_if dut_if;
    local virtual axis_if         s_axis;

    function new(virtual axis_i2c_top_if dut_if, virtual axis_if s_axis);
        this.dut_if = dut_if;
        this.s_axis = s_axis;
    endfunction

    task data_gen();
        begin
            for (int i = 0; i < 50; i++) begin
                wait(s_axis.tready);
                s_axis.tvalid = 1'b1;
                s_axis.tdata  = $urandom_range(0, (2**16)-1);
                $display("%d AXIS tansaction done at: %t ns\n", i, $time);
                @(posedge dut_if.clk_i);
                s_axis.tvalid = 1'b0;
                s_axis.tdata = '0;
            end
        end
    endtask

    task run();
        begin
            dut_if.clk_i  = 1'b0;
            s_axis.tvalid = 1'b0;
            s_axis.tdata  = '0;
            reset();
            data_gen();
            $display("Stop simulation at: %t ns\n", $time);
        end
    endtask

    task reset();
        begin
            dut_if.arstn_i = 1'b0;
            $display("Reset at %t ns\n.", $time);
            @(posedge dut_if.clk_i);
            dut_if.arstn_i = 1'b1;
        end
    endtask

endclass

`endif
