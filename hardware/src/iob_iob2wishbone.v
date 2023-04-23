`timescale 1ns/1ps

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
    wire                valid_e;
    wire                valid_r;
    wire [DATA_W/8-1:0] wstrb_r;
    // Wishbone auxiliar wire

    // Logic
    assign wb_addr_o = address_i;
    assign wb_data_o = wdata_i;
    assign wb_select_o = wb_we_o? (valid_i? wstrb_i:wstrb_r):4'hf;
    assign wb_we_o = valid_i? |wstrb_i:|wstrb_r;
    assign wb_cyc_o = valid_i|valid_r;
    assign wb_stb_o = valid_i|valid_r;

    assign rdata_o = wb_data_i;
    assign ready_o = wb_ack_i|wb_error_i;

    assign valid_e = valid_i|ready_o;
    iob_reg #(1,0) iob_reg_valid (clk_i, arst_i, 1'b0, valid_e, valid_i, valid_r);
    iob_reg #(DATA_W/8,0) iob_reg_wstrb (clk_i, arst_i, 1'b0, valid_i, wstrb_i, wstrb_r);

endmodule