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

  // ETH interface
  wire       mii_rx_clk;
  wire [3:0] mii_rxd_r;
  wire       mii_rx_dv;
  wire       mii_rx_er;
  wire       mii_rx_ctrl;
  wire       mii_tx_clk;
  wire [3:0] mii_txd;
  wire       mii_tx_en;
  wire       mii_tx_er;
  wire       mii_mdc;
  wire       mii_mdio;

  assign mii_rx_dv = 1'b1;
  assign mii_rx_er = 1'b0;
  iob_reg #(4,0) iob_reg_0 (clk_i, arst_i, 1'b0, 1'b1, mii_txd, mii_rxd_r);

  iob_ethoc #(
    //IOb-bus Parameters
    .ADDR_W(ADDR_W),
    .DATA_W(DATA_W),
    .TARGET("SIM")
  ) eth_0 (
    .clk(clk_i),
    .rst(arst_i),

    .valid(valid),
    .address(address),
    .wdata(wdata),
    .wstrb(wstrb),
    .rdata(rdata),
    .ready(ready),

    .mii_rx_clk_i(mii_rx_clk),
    .mii_rxd_i(mii_rxd_r),
    .mii_rx_dv_i(mii_rx_dv),
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

endmodule
