`timescale 1ns / 1ps
`include "ethmac_defines.v"

module iob_ethoc #(
    //IOb-bus Parameters
    parameter ADDR_W   = 16,
    parameter DATA_W   = 32,
    parameter TARGET = "XILINX"
  )(
    input wire clk,
    input wire rst,
    
    input  wire                valid,
    input  wire [ADDR_W-1:0]   address,
    input  wire [DATA_W-1:0]   wdata,
    input  wire [DATA_W/8-1:0] wstrb,
    output  reg [DATA_W-1:0]   rdata,
    output wire                ready,

    input  wire       mii_rx_clk_i,
    input  wire [3:0] mii_rxd_i,
    input  wire       mii_rx_dv_i,
    input  wire       mii_rx_er_i,
    input  wire       mii_rx_ctrl_i,
    input  wire       mii_tx_clk_i,
    output wire [3:0] mii_txd_o,
    output wire       mii_tx_en_o,
    output wire       mii_tx_er_o,
    output wire       mii_mdc_o,
    inout  wire       mii_mdio_io,

    output wire eth_int_o
  );

  // ETHERNET wires
  wire mii_coll; // Collision Detected.
  wire mii_crs;
  wire mii_mdi_I;
  wire mii_mdo_O;
  wire mii_mdo_OE;
  // // Wichbone master
  wire [32-1:0] m_ETH_wb_adr;
  wire [DATA_W/8-1:0] m_ETH_wb_sel;
  wire m_ETH_wb_we;
  wire [DATA_W-1:0] m_ETH_wb_dat_in;
  wire [DATA_W-1:0] m_ETH_wb_dat_out;
  wire m_ETH_wb_cyc;
  wire m_ETH_wb_stb;
  wire m_ETH_wb_ack;
  wire m_ETH_wb_err;

  // IOb2Whichbone wires
  wire valid_r;
  wire [ADDR_W-1:0] s_wb_addr_in;
  wire [DATA_W-1:0] s_wb_data_in;
  wire [DATA_W-1:0] s_wb_data_out;
  wire s_wb_we_in;
  wire s_wb_cyc_in; // Cycle Input, Indicates that a valid bus cycle is in progress.
  wire s_wb_stb_in; // Strobe Input, Indicates the beginning of a valid transfer cycle.
  wire [DATA_W/8-1:0] s_wb_select_in;
  wire s_wb_ack_out;
  wire s_wb_error_out;

  // ETHERNET logic
  // // Connecting Ethernet PHY Module
  assign mii_mdio_io = mii_mdo_OE ? mii_mdo_O : 1'bz ;
  assign mii_mdi_I   = mii_mdio_io;
  assign mii_coll    = 1'b0; // No collision detection
  assign mii_crs     = 1'b0; // The media is always in an idle state
  // In full-duplex mode, the Carrier Sense and the Collision Detect signals are ignored.
  
  // IOb2Whichbone logic
  assign s_wb_addr_in = address[ADDR_W-1:0];
  assign s_wb_data_in = wdata;
  assign rdata = s_wb_data_out;
  assign s_wb_we_in = |wstrb;
  assign s_wb_cyc_in = ready? valid:valid|valid_r;
  assign s_wb_stb_in = valid;
  assign s_wb_select_in = wstrb;
  //assign wb_select_in = 1<<address[1:0];
  assign ready = s_wb_ack_out|s_wb_error_out;

  iob_reg #(1,0) iob_reg_valid (clk, rst, ready, valid, 1'b1, valid_r);

  // Connecting Ethernet top module
  ethmac eth_top (
    // WISHBONE common
    .wb_clk_i(clk),
    .wb_rst_i(rst), 

    // WISHBONE slave
    .wb_adr_i(s_wb_addr_in[11:2]),
    .wb_sel_i(s_wb_select_in),
    .wb_we_i(s_wb_we_in), 
    .wb_cyc_i(s_wb_cyc_in),
    .wb_stb_i(s_wb_stb_in),
    .wb_ack_o(s_wb_ack_out), 
    .wb_err_o(s_wb_error_out),
    .wb_dat_i(s_wb_data_in),
    .wb_dat_o(s_wb_data_out), 
    
    // WISHBONE master
    .m_wb_adr_o(m_ETH_wb_adr),
    .m_wb_sel_o(m_ETH_wb_sel),
    .m_wb_we_o(m_ETH_wb_we), 
    .m_wb_dat_i(m_ETH_wb_dat_in),
    .m_wb_dat_o(m_ETH_wb_dat_out),
    .m_wb_cyc_o(m_ETH_wb_cyc), 
    .m_wb_stb_o(m_ETH_wb_stb),
    .m_wb_ack_i(m_ETH_wb_ack),
    .m_wb_err_i(m_ETH_wb_err), 

  `ifdef ETH_WISHBONE_B3
    .m_wb_cti_o(eth_ma_wb_cti_o),
    .m_wb_bte_o(eth_ma_wb_bte_o),
  `endif

    //TX
    .mtx_clk_pad_i(mii_tx_clk_i),
    .mtxd_pad_o(mii_txd_o),
    .mtxen_pad_o(mii_tx_en_o),
    .mtxerr_pad_o(mii_tx_er_o),

    //RX
    .mrx_clk_pad_i(mii_rx_clk_i),
    .mrxd_pad_i(mii_rxd_i),
    .mrxdv_pad_i(mii_rx_dv_i),
    .mrxerr_pad_i(mii_rx_er_i), 
    .mcoll_pad_i(mii_coll),
    .mcrs_pad_i(mii_crs), 
    
    // MIIM
    .mdc_pad_o(mii_mdc_o),
    .md_pad_i(mii_mdi_I),
    .md_pad_o(mii_mdo_O),
    .md_padoe_o(mii_mdo_OE),
    
    .int_o(eth_int_o)

    // Bist
  `ifdef ETH_BIST
    ,
    .mbist_si_i       (1'b0),
    .mbist_so_o       (),
    .mbist_ctrl_i     (3'b001) // {enable, clock, reset}
  `endif
  );



endmodule
