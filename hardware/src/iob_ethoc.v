`timescale 1ns/1ps
`include "ethmac_defines.v"

module iob_ethoc #(
    //IOb-bus Parameters
    parameter ADDR_W      = 13,
    parameter DATA_W      = 32,
    parameter SRAM_ADDR_W = 12, // SRAM_ADDR starts at 0x800
    parameter HEXFILE     = "none",
    parameter TARGET      = "XILINX"
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
  // // Ethernet memory access, Wishbone2IOb
  wire                   s_valid;
  wire [SRAM_ADDR_W-3:0] s_addr;
  wire [DATA_W/8-1:0]    s_wstrb;
  wire [DATA_W-1:0]      s_wdata;
  wire [DATA_W-1:0]      s_rdata;
  wire                   s_ready;

  // IOb2Wishbone wires
  wire valid_e;
  wire valid_r;
  wire [DATA_W/8-1:0] wstrb_r;
  wire [ADDR_W-1:0] s_wb_addr_in;
  wire [DATA_W-1:0] s_wb_data_in;
  wire [DATA_W-1:0] s_wb_data_out;
  wire s_wb_we_in;
  wire s_wb_cyc_in; // Cycle Input, Indicates that a valid bus cycle is in progress.
  wire s_wb_stb_in; // Strobe Input, Indicates the beginning of a valid transfer cycle.
  wire [DATA_W/8-1:0] s_wb_select_in;
  wire s_wb_ack_out;
  wire s_wb_error_out;

  // Merge IOb memory access and Ethernet memory access
  wire iob_memory_access_e;

  // ETHERNET logic
  // // Connecting Ethernet PHY Module
  assign mii_mdio_io = mii_mdo_OE ? mii_mdo_O : 1'bz ;
  assign mii_mdi_I   = mii_mdio_io;
  assign mii_coll    = 1'b0; // No collision detection
  assign mii_crs     = 1'b0; // The media is always in an idle state
  /* In full-duplex mode, the Carrier Sense and the Collision Detect signals are ignored. */
  // // Ethernet memory access
  assign s_valid = (m_ETH_wb_cyc & m_ETH_wb_stb)&(~s_ready);
  assign s_addr  = m_ETH_wb_adr[SRAM_ADDR_W:2];
  assign s_wstrb = m_ETH_wb_we? m_ETH_wb_sel:4'h0;
  assign s_wdata = m_ETH_wb_dat_out;
  assign m_ETH_wb_dat_in = s_rdata;
  assign m_ETH_wb_ack = s_ready;
  assign m_ETH_wb_err = 1'b0;
  iob_reg #(1,0) iob_reg_s_ready (clk, rst, 1'b0, 1'b1, s_valid, s_ready);
  
  // IOb2Wishbone logic
  assign s_wb_addr_in = address[ADDR_W-1:0];
  assign s_wb_data_in = wdata;
  assign s_wb_select_in = s_wb_we_in? (valid? wstrb:wstrb_r):4'hf;
  assign s_wb_we_in = valid? |wstrb:|wstrb_r;
  assign s_wb_cyc_in = valid|valid_r;
  assign s_wb_stb_in = valid|valid_r;
  //assign wb_select_in = 1<<address[1:0];
  assign ready = s_wb_ack_out|s_wb_error_out;
  assign rdata = s_wb_data_out;

  assign valid_e = valid|ready;
  iob_reg #(1,0) iob_reg_valid (clk, rst, 1'b0, valid_e, valid, valid_r);
  iob_reg #(DATA_W/8,0) iob_reg_wstrb (clk, rst, 1'b0, valid, wstrb, wstrb_r);

  // Merge IOb memory access and Ethernet memory access
  assign iob_memory_access_e = address > 16'h00ff;// SRAM_ADDR starts at 0x800
  //iob_merge #(
  //  .N_MASTERS(2)
  //) ibus_merge (
  //  .clk    ( clk                      ),
  //  .rst    ( rst                      ),
  //
  //  //master
  //  .m_req  ( {ram_w_req, ram_r_req}   ),
  //  .m_resp ( {ram_w_resp, ram_r_resp} ),
  //
  //  //slave  
  //  .s_req  ( {s_valid, s_addr, s_wstrb, s_wdata} ),
  //  .s_resp ( {s_rdata, s_ready} )
  //  );

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

  iob_ram_sp_be #(
    .HEXFILE(HEXFILE),
    .ADDR_W(SRAM_ADDR_W-2),
    .DATA_W(DATA_W)
  ) main_mem_byte (
    .clk   (clk),

    // data port
    .en   (s_valid),
    .addr (s_addr),
    .we   (s_wstrb),
    .din  (s_wdata),
    .dout (s_rdata)
    );

endmodule
