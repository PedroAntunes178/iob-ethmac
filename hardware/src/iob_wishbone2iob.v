`include "timescale.v"

module iob_wishbone2iob #(
    parameter ADDR_W = 32,
    parameter DATA_W = 32
) (
    input wire clk_i,
    input wire arst_i,

    // Wishbone interface
    input  wire [ADDR_W-1:0]   wb_addr_i,
    input  wire [DATA_W/8-1:0] wb_select_i,
    input  wire                wb_we_i,
    input  wire                wb_cyc_i,
    input  wire                wb_stb_i,
    input  wire [DATA_W-1:0]   wb_data_i,
    output wire                wb_ack_o,
    output wire                wb_error_o,
    output wire [DATA_W-1:0]   wb_data_o,

    // IOb interface
    output wire                valid_o,
    output wire [ADDR_W-1:0]   address_o,
    output wire [DATA_W-1:0]   wdata_o,
    output wire [DATA_W/8-1:0] wstrb_o,
    input  wire [DATA_W-1:0]   rdata_i,
    input  wire                ready_i
);
    
    // IOb auxiliar wires
    wire valid_r;
    wire valid;
    wire ready_r;
    wire [DATA_W/8-1:0] wstrb;
    wire [DATA_W/8-1:0] wstrb_r;
    wire [DATA_W-1:0] rdata_r;
    // Wishbone auxiliar wire
    wire [ADDR_W-1:0] wb_addr_r;
    wire [DATA_W-1:0] wb_data_r;

    // Logic
    assign valid_o = (valid)&(~valid_r);
    assign address_o  = valid? wb_addr_i:wb_addr_r;
    assign wdata_o = valid? wb_data_i:wb_data_r;
    assign wstrb_o = valid? wstrb:wstrb_r;
    
    assign valid = wb_stb_i&wb_cyc_i;
    assign wstrb = wb_we_i? wb_select_i:4'h0;

    iob_reg #(1,0) iob_reg_valid (clk_i, arst_i, ready_i, valid, 1'b1, valid_r);
    iob_reg #(ADDR_W,0) iob_reg_addr (clk_i, arst_i, 1'b0, valid, wb_addr_i, wb_addr_r);
    iob_reg #(DATA_W,0) iob_reg_data_i (clk_i, arst_i, 1'b0, valid, wb_data_i, wb_data_r);
    iob_reg #(DATA_W/8,0) iob_reg_strb (clk_i, arst_i, 1'b0, valid, wstrb, wstrb_r);

    assign wb_data_o = ready_i? rdata_i:rdata_r;
    assign wb_ack_o = ready_i;
    assign wb_error_o = 1'b0;
    iob_reg #(1,0) iob_reg_ready (clk_i, arst_i, ~valid, ready_i, 1'b1, ready_r);
    iob_reg #(DATA_W,0) iob_reg_data_o (clk_i, arst_i, 1'b0, ready_i, rdata_i, rdata_r);


endmodule