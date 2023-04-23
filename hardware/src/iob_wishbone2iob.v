`timescale 1ns/1ps

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
    
    // Wishbone auxiliar wire

    // Logic
    assign valid_o = (wb_cyc_i & wb_stb_i)&(~ready_i);
    assign address_o  = wb_addr_i;
    assign wdata_o = wb_data_i;
    assign wstrb_o = wb_we_i? wb_select_i:4'h0;
    
    assign wb_data_o = rdata_i;
    assign wb_ack_o = ready_i;
    assign wb_error_o = 1'b0;


endmodule