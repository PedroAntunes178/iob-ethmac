//instantiate core in system

  //
  // ETHERNET
  //
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

