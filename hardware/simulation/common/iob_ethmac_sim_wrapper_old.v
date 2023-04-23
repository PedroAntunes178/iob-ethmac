`timescale 1ns / 1ps

module iob_ethmac_sim_wrapper #(
  parameter ADDR_W  = 16,
  parameter DATA_W  = 32
  ) (
  input clk_i,
  input arst_i,
  input eth_clk_i,

  // IOb interface
  input                valid,
  input [ADDR_W-1:0]   address,
  input [DATA_W-1:0]   wdata,
  input [DATA_W/8-1:0] wstrb,
  output [DATA_W-1:0]  rdata,
  output wire          ready,

  output wire ethernet_interrupt
  );

  integer phy_log_file_desc;

  initial begin
    phy_log_file_desc = $fopen("../log/eth_tb_phy.log");
    if (phy_log_file_desc < 2)
    begin
      $display("*E Could not open/create eth_tb_phy.log file in ../log/ directory!");
      $finish;
    end
    $fdisplay(phy_log_file_desc, "================ PHY Module  Testbench access log ================");
    $fdisplay(phy_log_file_desc, " ");
`ifdef VCD
    $dumpfile("iob_ethmac.vcd");
    $dumpvars(0, iob_ethmac_sim_wrapper);
`endif
  end

  localparam SRAM_ADDR_W = 13;

  // ETH interface
  wire       mii_rx_clk;
  wire [3:0] mii_rxd;
  wire       mii_rx_dv;
  wire       mii_rx_er;
  wire       mii_rx_ctrl;
  wire       mii_tx_clk;
  wire [3:0] mii_txd;
  wire       mii_tx_en;
  wire       mii_tx_er;
  wire       mii_mdc;
  wire       mii_mdio;
  wire       mii_coll;
  wire       mii_crs;

  // IOb master interface
  wire                m_valid;
  wire [31:0]         m_addr;
  wire [DATA_W/8-1:0] m_wstrb;
  wire [DATA_W-1:0]   m_wdata;
  wire [DATA_W-1:0]   m_rdata;
  wire                m_ready;

  assign mii_rx_ctrl = 1'b0;

  iob_ethmac #(
    //IOb-bus Parameters
    .ADDR_W(ADDR_W),
    .DATA_W(DATA_W),
    .TARGET("SIM")
  ) eth_0 (
    .clk(clk_i),
    .rst(arst_i),

    .s_valid(valid),
    .s_address(address),
    .s_wdata(wdata),
    .s_wstrb(wstrb),
    .s_rdata(rdata),
    .s_ready(ready),

    .m_valid(m_valid),
    .m_addr(m_addr),
    .m_wdata(m_wdata),
    .m_wstrb(m_wstrb),
    .m_rdata(m_rdata),
    .m_ready(m_ready),

    .mii_rx_clk_i(mii_rx_clk),
    .mii_rxd_i(mii_rxd),
    .mii_rx_dv_i(mii_rx_dv),
    .mii_rx_er_i(mii_rx_er),
    .mii_rx_ctrl_i(mii_rx_ctrl),
    .mii_tx_clk_i(mii_tx_clk),
    .mii_txd_o(mii_txd),
    .mii_tx_en_o(mii_tx_en),
    .mii_tx_er_o(mii_tx_er),
    .mii_mdc_o(mii_mdc),
    .mii_mdio_io(mii_mdio),
    .mii_coll_i(mii_coll),
    .mii_crs_i(mii_crs),

    .eth_int_o(ethernet_interrupt)
    );

  // Simulation memory
  iob_ram_sp_be #(
    .HEXFILE("test"),
    .ADDR_W(SRAM_ADDR_W-2),
    .DATA_W(DATA_W)
  ) main_mem_byte (
    .clk   (clk_i),

    // data port
    .en   (m_valid),
    .addr (m_addr[SRAM_ADDR_W-1:2]),
    .we   (m_wstrb),
    .din  (m_wdata),
    .dout (m_rdata)
    );
  
  iob_reg #(1,0) iob_reg_s_ready (clk_i, arst_i, 1'b0, 1'b1, m_valid, m_ready);

  eth_phy eth_phy (
    // WISHBONE reset
    .m_rst_n_i(~arst_i),

    // MAC TX
    .mtx_clk_o(mii_tx_clk),    .mtxd_i(mii_txd),    .mtxen_i(mii_tx_en),    .mtxerr_i(mii_tx_er),

    // MAC RX
    .mrx_clk_o(mii_rx_clk),    .mrxd_o(mii_rxd),    .mrxdv_o(mii_rx_dv),    .mrxerr_o(mii_rx_er),
    .mcoll_o(mii_coll),        .mcrs_o(mii_crs),

    // MIIM
    .mdc_i(mii_mdc),          .md_io(mii_mdio),

    // SYSTEM
    .phy_log(phy_log_file_desc)
  );

endmodule
