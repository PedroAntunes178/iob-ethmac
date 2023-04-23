`timescale 1ns / 1ps

module iob_ethmac_sim_wrapper #(
  parameter MEM_ADDR_W = 32,
  parameter ADDR_W  = 12,
  parameter DATA_W  = 32
  ) (
  // WISHBONE common
  input  wire         wb_clk_i,     // WISHBONE clock
  input  wire         wb_rst_i,     // WISHBONE reset
  input  wire [31:0]  wb_dat_i,     // WISHBONE data input
  output wire [31:0]  wb_dat_o,     // WISHBONE data output
  output wire         wb_err_o,     // WISHBONE error output

  // WISHBONE slave
  input  wire [11:2]  wb_adr_i,     // WISHBONE address input
  input  wire  [3:0]  wb_sel_i,     // WISHBONE byte select input
  input  wire         wb_we_i,      // WISHBONE write enable input
  input  wire         wb_cyc_i,     // WISHBONE cycle input
  input  wire         wb_stb_i,     // WISHBONE strobe input
  output wire         wb_ack_o,     // WISHBONE acknowledge output

  // WISHBONE master
  output wire [31:0]  m_wb_adr_o,
  output wire  [3:0]  m_wb_sel_o,
  output wire         m_wb_we_o,
  input  wire [31:0]  m_wb_dat_i,
  output wire [31:0]  m_wb_dat_o,
  output wire         m_wb_cyc_o,
  output wire         m_wb_stb_o,
  input  wire         m_wb_ack_i,
  input  wire         m_wb_err_i,

`ifdef ETH_WISHBONE_B3
  output wire  [2:0]  m_wb_cti_o,   // Cycle Type Identifier
  output wire  [1:0]  m_wb_bte_o,   // Burst Type Extension
`endif

  // Tx
  input  wire         mtx_clk_pad_i, // Transmit clock (from PHY)
  output wire  [3:0]  mtxd_pad_o,    // Transmit nibble (to PHY)
  output wire         mtxen_pad_o,   // Transmit enable (to PHY)
  output wire         mtxerr_pad_o,  // Transmit error (to PHY)

  // Rx
  input  wire         mrx_clk_pad_i, // Receive clock (from PHY)
  input  wire  [3:0]  mrxd_pad_i,    // Receive nibble (from PHY)
  input  wire         mrxdv_pad_i,   // Receive data valid (from PHY)
  input  wire         mrxerr_pad_i,  // Receive data error (from PHY)

  // Commwireon Tx and Rx
  input  wire         mcoll_pad_i,   // Collision (from PHY)
  input  wire         mcrs_pad_i,    // Carrier sense (from PHY)

  // MII wireManagement interface
  inout  wire         md_pad_io,     // MII data input/output (from I/O cell)
  output wire         mdc_pad_o,     // MII Management data clock (to PHY)

  output wire         int_o          // Interrupt output

  // Bist
  `ifdef ETH_BIST
  ,
  input  wire                               mbist_si_i,  // bist scan serial in
  output wire                               mbist_so_o,  // bist scan serial out
  input  wire [`ETH_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i // bist chain shift control
  `endif
  );

  // Wires
  // // general
  wire clk_i;
  wire arst_i;
  wire ethernet_interrupt;
  // // Slave interface
  wire s_valid;
  wire [ADDR_W-1:2]   s_address;
  wire [DATA_W-1:0]   s_wdata;
  wire [DATA_W/8-1:0] s_wstrb;
  wire [DATA_W-1:0]   s_rdata;
  wire s_ready;
  // // Master interface
  wire m_valid;
  wire [MEM_ADDR_W-1:0] m_addr;
  wire [DATA_W-1:0]     m_wdata;
  wire [DATA_W/8-1:0]   m_wstrb;
  wire [DATA_W-1:0]     m_rdata;
  wire m_ready;
  // // Ethernet MII
  wire mii_rx_ctrl;

  // Logic
  assign clk_i = wb_clk_i;
  assign arst_i = wb_rst_i;
  assign mii_rx_ctrl = 1'b0;
  assign int_o = ethernet_interrupt;


  iob_iob2wishbone #(
    MEM_ADDR_W, DATA_W
  ) iob2wishbone (
    clk_i, arst_i,
    m_valid, m_addr, m_wdata, m_wstrb, m_rdata, m_ready,
    m_wb_adr_o, m_wb_sel_o, m_wb_we_o, m_wb_cyc_o, m_wb_stb_o, m_wb_dat_o, m_wb_ack_i, m_wb_err_i, m_wb_dat_i
  );

  iob_wishbone2iob #(
    ADDR_W-2, DATA_W
  ) wishbone2iob (
    clk_i, arst_i,
    wb_adr_i, wb_sel_i, wb_we_i, wb_cyc_i, wb_stb_i,  wb_dat_i, wb_ack_o, wb_err_o,  wb_dat_o,
    s_valid, s_address, s_wdata, s_wstrb, s_rdata, s_ready
  );

  iob_ethmac #(
    //IOb-bus Parameters
    .ADDR_W(ADDR_W),
    .MEM_ADDR_W(MEM_ADDR_W),
    .DATA_W(DATA_W),
    .TARGET("SIM")
  ) eth_0 (
    .clk(clk_i),
    .rst(arst_i),

    .s_valid(s_valid),
    .s_address(s_address),
    .s_wdata(s_wdata),
    .s_wstrb(s_wstrb),
    .s_rdata(s_rdata),
    .s_ready(s_ready),

    .m_valid(m_valid),
    .m_addr(m_addr),
    .m_wdata(m_wdata),
    .m_wstrb(m_wstrb),
    .m_rdata(m_rdata),
    .m_ready(m_ready),

    .mii_rx_clk_i(mrx_clk_pad_i),
    .mii_rxd_i(mrxd_pad_i),
    .mii_rx_dv_i(mrxdv_pad_i),
    .mii_rx_er_i(mrxerr_pad_i),
    .mii_rx_ctrl_i(mii_rx_ctrl),
    .mii_tx_clk_i(mtx_clk_pad_i),
    .mii_txd_o(mtxd_pad_o),
    .mii_tx_en_o(mtxen_pad_o),
    .mii_tx_er_o(mtxerr_pad_o),
    .mii_mdc_o(mdc_pad_o),
    .mii_mdio_io(md_pad_io),
    .mii_coll_i(mcoll_pad_i),
    .mii_crs_i(mcrs_pad_i),

    .eth_int_o(ethernet_interrupt)
    );
endmodule
