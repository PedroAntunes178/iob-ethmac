`timescale 1ns / 1ps

module iob_ethoc_sim_wrapper #(
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

`ifdef VCD
  initial begin
    $dumpfile("iob_ethoc.vcd");
    $dumpvars(0, iob_ethoc_sim_wrapper);
  end
`endif

  localparam SRAM_ADDR_W = 13;

  // ETH interface
  wire       mii_rx_clk;
  wire [3:0] mii_rxd_r;
  wire       mii_rx_dv_r;
  wire       mii_rx_er;
  wire       mii_rx_ctrl;
  wire       mii_tx_clk;
  wire [3:0] mii_txd;
  wire       mii_tx_en;
  wire       mii_tx_er;
  wire       mii_mdc;
  wire       mii_mdio;

  // IOb master interface
  wire                m_valid;
  wire [31:0]         m_addr;
  wire [DATA_W/8-1:0] m_wstrb;
  wire [DATA_W-1:0]   m_wdata;
  wire [DATA_W-1:0]   m_rdata;
  wire                m_ready;

  assign mii_rx_er = 1'b0;
  iob_reg #(4,0) iob_reg_rxd (eth_clk_i, arst_i, 1'b0, 1'b1, mii_txd, mii_rxd_r);
  iob_reg #(1,0) iob_reg_rx_dv (eth_clk_i, arst_i, 1'b0, 1'b1, mii_tx_en, mii_rx_dv_r);

  iob_ethoc #(
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
    .mii_rxd_i(mii_rxd_r),
    .mii_rx_dv_i(mii_rx_dv_r),
    .mii_rx_er_i(mii_rx_er),
    .mii_rx_ctrl_i(mii_rx_ctrl),
    .mii_tx_clk_i(mii_tx_clk),
    .mii_txd_o(mii_txd),
    .mii_tx_en_o(mii_tx_en),
    .mii_tx_er_o(mii_tx_er),
    .mii_mdc_o(mii_mdc),
    .mii_mdio_io(mii_mdio),

    .eth_int_o(ethernet_interrupt)
    );

  assign mii_tx_clk = eth_clk_i;
  assign mii_rx_clk = eth_clk_i;

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

endmodule
