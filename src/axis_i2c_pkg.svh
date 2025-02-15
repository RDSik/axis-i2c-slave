`ifndef AXIS_I2C_PKG
`define AXIS_I2C_PKG

package axis_i2c_pkg;

    localparam MAIN_CLK        = 100_000_000;
    localparam I2C_CLK         = 200_000;
    localparam WRITE           = 1'b0;
    localparam READ            = 1'b1;
    localparam RW_BIT          = 7;
    localparam I2C_DATA_WIDTH  = 8;
    localparam AXIS_DATA_WIDTH = 16;
    localparam BIT_CNT_WIDTH   = $clog2(I2C_DATA_WIDTH);

endpackage

`endif
