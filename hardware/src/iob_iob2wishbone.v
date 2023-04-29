`include "timescale.v"

module iob_iob2wishbone #(
    parameter ADDR_W = 32,
    parameter DATA_W = 32
) (
    input wire clk_i,
    input wire arst_i,

    // IOb interface
    input  wire                valid_i,
    input  wire [ADDR_W-1:0]   address_i,
    input  wire [DATA_W-1:0]   wdata_i,
    input  wire [DATA_W/8-1:0] wstrb_i,
    output wire [DATA_W-1:0]   rdata_o,
    output wire                ready_o,

    // Wishbone interface
    output wire [ADDR_W-1:0]   wb_addr_o,
    output wire [DATA_W/8-1:0] wb_select_o,
    output wire                wb_we_o,
    output wire                wb_cyc_o,
    output wire                wb_stb_o,
    output wire [DATA_W-1:0]   wb_data_o,
    input  wire                wb_ack_i,
    input  wire                wb_error_i,
    input  wire [DATA_W-1:0]   wb_data_i
);
    
    // IOb auxiliar wires
    wire                valid_r;
    wire [ADDR_W-1:0]   address_r;
    wire [DATA_W-1:0]   wdata_r;
    wire                ready;
    wire                ready_r;
    // Wishbone auxiliar wire
    wire [DATA_W-1:0]   wb_data_r;
    wire [DATA_W/8-1:0] wb_select;
    wire [DATA_W/8-1:0] wb_select_r;
    wire                wb_we;
    wire                wb_we_r;

    // Logic
    assign wb_addr_o = valid_i? address_i:address_r;
    assign wb_data_o = valid_i? wdata_i:wdata_r;
    assign wb_select_o = valid_i? wb_select:wb_select_r;
    assign wb_we_o = valid_i? wb_we:wb_we_r;
    assign wb_cyc_o = valid_r;
    assign wb_stb_o = (valid_r)&((~ready)|(valid_i));

    assign wb_select = wb_we? wstrb_i:1<<address_i[1:0];
    assign wb_we = |wstrb_i;

    iob_reg #(1,0) iob_reg_valid (clk_i, arst_i, 1'b0, 1'b1, valid_i, valid_r);
    iob_reg #(1,0) iob_reg_we (clk_i, arst_i, 1'b0, valid_i, wb_we, wb_we_r);
    iob_reg #(ADDR_W,0) iob_reg_addr (clk_i, arst_i, 1'b0, valid_i, address_i, address_r);
    iob_reg #(DATA_W,0) iob_reg_iob_data (clk_i, arst_i, 1'b0, valid_i, wdata_i, wdata_r);
    iob_reg #(DATA_W/8,0) iob_reg_strb (clk_i, arst_i, 1'b0, valid_i, wb_select, wb_select_r);

    assign rdata_o = ready? wb_data_i:wb_data_r;
    assign ready_o = ready;
    assign ready = wb_ack_i|wb_error_i;
    iob_reg #(1,0) iob_reg_ready (clk_i, arst_i, 1'b0, 1'b1, ready, ready_r);
    iob_reg #(DATA_W,0) iob_reg_wb_data (clk_i, arst_i, 1'b0, ready, wb_data_i, wb_data_r);
    

endmodule