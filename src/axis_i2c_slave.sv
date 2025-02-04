`include "axis_i2c_pkg.svh"

module axis_i2c_slave
    import axis_i2c_pkg::*;
(
    input  logic                      clk_i,
    input  logic                      arstn_i,
    inout                             i2c_sda_io,
    output logic                      i2c_scl_o,
    output logic [I2C_DATA_WIDTH-1:0] i2c_rdata_o,
    output logic                      rvalid_o,

    axis_if.slave s_axis
);

    enum logic [2:0] {
        IDLE      = 3'b000,
        START     = 3'b001,
        ADDR      = 3'b010,
        WACK_ADDR = 3'b011,
        DATA      = 3'b100,
        WACK_DATA = 3'b101,
        STOP      = 3'b110
    } state;

    logic [I2C_DATA_WIDTH-1:0] rd_data;
    logic [I2C_DATA_WIDTH-1:0] data_reg;
    logic [I2C_DATA_WIDTH-1:0] addr_reg;
    logic [BIT_IND_WIDTH-1:0 ] bit_ind;
    logic                      i2c_scl_en;
    logic                      i2c_sda_en;
    logic                      rd_bit;
    logic                      wr_bit;

    assign i2c_sda_io = (i2c_sda_en) ? 1'bz : wr_bit;
    assign rd_bit     = i2c_sda_io;

    // IOBUF iobuf_inst (
        // .O  (rd_bit    ), // Buffer output
        // .IO (i2c_sda_io), // Buffer inout port
        // .I  (wr_bit    ), // Buffer input
        // .T  (i2c_sda_en)  // 3-state enable input, high=input, low=output
    // );

    always_ff @(posedge clk_i or negedge arstn_i) begin
        if (~arstn_i) begin
            state    <= IDLE;
            data_reg <= '0;
            addr_reg <= '0;
            rd_data  <= '0;
        end else begin
            case (state)
                IDLE: begin
                    if (s_axis.tvalid) begin
                        state      <= START;
                        data_reg   <= s_axis.tdata[AXIS_DATA_WIDTH-1:I2C_DATA_WIDTH];
                        addr_reg   <= s_axis.tdata[I2C_DATA_WIDTH-1:0];
                        i2c_sda_en <= WRITE;
                    end
                end
                START: begin
                    state  <= ADDR;
                    wr_bit <= 1'b0;
                end
                ADDR: begin
                    wr_bit <= addr_reg[bit_ind];
                    if (~(|bit_ind)) state <= WACK_ADDR;
                end
                WACK_ADDR: begin
                    state      <= DATA;
                    i2c_sda_en <= (addr_reg[I2C_RW_BIT]) ? READ : WRITE;
                end
                DATA: begin
                    if (addr_reg[I2C_RW_BIT] == WRITE) begin
                        wr_bit <= data_reg[bit_ind];
                        if (~(|bit_ind)) state <= WACK_DATA;
                    end else if (addr_reg[I2C_RW_BIT] == READ) begin
                        rd_data[bit_ind] <= rd_bit;
                        if (~(|bit_ind)) state <= WACK_DATA;
                    end
                end
                WACK_DATA: begin
                    state       <= STOP;
                    i2c_sda_en  <= WRITE;
                    i2c_rdata_o <= rd_data;
                end
                STOP: begin
                    state  <= IDLE;
                    wr_bit <= 1'b1;
                end
                default: state <= IDLE;
            endcase
        end
    end

    always_ff @(posedge clk_i or negedge arstn_i) begin
        if (~arstn_i) begin
            bit_ind <= '0;
        end else if ((state == DATA) || (state == ADDR)) begin
            bit_ind <= bit_ind - 1;
        end else if ((state == WACK_ADDR) || (state == START)) begin
            bit_ind <= I2C_DATA_WIDTH - 1;
        end
    end

    always_ff @(negedge clk_i or negedge arstn_i) begin
        if (~arstn_i) begin
            i2c_scl_en <= 1'b0;
        end else begin
            if ((state == IDLE) || (state == START) || (state == STOP)) begin
                i2c_scl_en <= 1'b0;
            end else begin
                i2c_scl_en <= 1'b1;
            end
        end
    end

    always_comb begin
        s_axis.tready = ((arstn_i == 1'b1) && (state == IDLE)) ? 1'b1 : 1'b0;
        i2c_scl_o     = i2c_scl_en ? ~clk_i : 1'b1;
        rvalid_o      = (state == STOP) && (addr_reg[I2C_RW_BIT] == READ);
    end

endmodule
