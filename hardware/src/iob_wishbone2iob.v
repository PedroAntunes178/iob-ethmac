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

    localparam AXIL_ADDR_W = ADDR_W;
    localparam AXIL_DATA_W = DATA_W;
    localparam AXI_ID_W = 1;
    localparam AXI_RESP_W = 2;
    
    // IOb auxiliar wires
    wire valid_r;
    wire ready_r;
    wire [DATA_W/8-1:0] wstrb_r;
    wire [DATA_W-1:0] rdata_r;
    // Wishbone auxiliar wire
    wire [ADDR_W-1:0] wb_addr_r;
    wire [DATA_W-1:0] wb_data_r;
    // AXIL auxiliar wire
    wire [AXI_ID_W-1:0]      axil_awid; //Address write channel ID
    wire [AXIL_ADDR_W-1:0]   axil_awaddr; //Address write channel address
    wire [3-1:0]             axil_awprot; //Address write channel protection type. Transactions set with Normal, Secure, and Data attributes (000).
    wire [4-1:0]             axil_awqos; //Address write channel quality of service
    wire [1-1:0]             axil_awvalid; //Address write channel valid
    wire [1-1:0]             axil_awready; //Address write channel ready
    wire [AXIL_DATA_W-1:0]   axil_wdata; //Write channel data
    wire [AXIL_DATA_W/8-1:0] axil_wstrb; //Write channel write strobe
    wire [1-1:0]             axil_wvalid; //Write channel valid
    wire [1-1:0]             axil_wready; //Write channel ready
    wire [AXI_ID_W-1:0]      axil_bid; //Write response channel ID
    wire [2-1:0]             axil_bresp; //Write response channel response
    wire [1-1:0]             axil_bvalid; //Write response channel valid
    wire [1-1:0]             axil_bready; //Write response channel ready
    wire [AXI_ID_W-1:0]      axil_arid; //Address read channel ID
    wire [AXIL_ADDR_W-1:0]   axil_araddr; //Address read channel address
    wire [3-1:0]             axil_arprot; //Address read channel protection type. Transactions set with Normal, Secure, and Data attributes (000).
    wire [4-1:0]             axil_arqos; //Address read channel quality of service
    wire [1-1:0]             axil_arvalid; //Address read channel valid
    wire [1-1:0]             axil_arready; //Address read channel ready
    wire [AXI_ID_W-1:0]      axil_rid; //Read channel ID
    wire [AXIL_DATA_W-1:0]   axil_rdata; //Read channel data
    wire [2-1:0]             axil_rresp; //Read channel response
    wire [1-1:0]             axil_rvalid; //Read channel valid
    wire [1-1:0]             axil_rready; //Read channel ready
    reg                      axil_bvalid_int;
    reg                      awvalid_ack;
    reg                      arvalid_ack;

    // Logic
    // // AXIL to IOb
    assign axil_rdata = rdata_i;

    // AXI IDs
    assign axil_bid = {AXI_ID_W{1'b0}};
    assign axil_rid = {AXI_ID_W{1'b0}};

    // Response is always OK
    assign axil_bresp = {AXI_RESP_W{1'b0}};
    assign axil_rresp = {AXI_RESP_W{1'b0}};

    assign valid_o   = (axil_wvalid | axil_arvalid) & ~ready_i;
    assign address_o = axil_wvalid? axil_awaddr: axil_araddr;
    assign wstrb_o   = axil_wvalid? axil_wstrb: {(AXIL_DATA_W/8){1'b0}};
    assign wdata_o   = axil_wdata;

    assign axil_awready = awvalid_ack & ready_i;
    assign axil_wready  = awvalid_ack & ready_i;
    assign axil_arready = arvalid_ack & ready_i;
    assign axil_rvalid  = arvalid_ack & ready_i;

    assign axil_bvalid = axil_bvalid_int;
    always @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            axil_bvalid_int <= 1'b0;
        end else begin
            axil_bvalid_int <= axil_wready;
        end
    end

    always @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            awvalid_ack <= 1'b0;
        end else if (axil_awvalid & ~awvalid_ack) begin
            awvalid_ack <= 1'b1;
        end else if (ready_i) begin
            awvalid_ack <= 1'b0;
        end
    end

    always @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            arvalid_ack <= 1'b0;
        end else if (axil_arvalid & ~arvalid_ack) begin
            arvalid_ack <= 1'b1;
        end else if (ready_i) begin
            arvalid_ack <= 1'b0;
        end
    end

    wbm2axilite #(
        .C_AXI_ADDR_WIDTH(ADDR_W) 
    ) wbm2axilite (
        // We'll share the clock and the reset
        .i_clk(clk_i),
        .i_reset(arst_i),
        // Wishbone
        .i_wb_cyc(wb_cyc_i),
        .i_wb_stb(wb_stb_i),
        .i_wb_we(wb_we_i),
        .i_wb_addr(wb_addr_i[ADDR_W-1:2]),
        .i_wb_data(wb_data_i),
        .i_wb_sel(wb_select_i),
        .o_wb_stall(),
        .o_wb_ack(wb_ack_o),
        .o_wb_data(wb_data_o),
        .o_wb_err(wb_error_o),
        // AXI-Lite
        // AXI write address channel signals
        .o_axi_awvalid(axil_awvalid),
        .i_axi_awready(axil_awready),
        .o_axi_awaddr(axil_awaddr),
        .o_axi_awprot(axil_awprot),
        //
        // AXI write data channel signals
        .o_axi_wvalid(axil_wvalid),
        .i_axi_wready(axil_wready),
        .o_axi_wdata(axil_wdata),
        .o_axi_wstrb(axil_wstrb),
        //
        // AXI write response channel signals
        .i_axi_bvalid(axil_bvalid),
        .o_axi_bready(axil_bready),
        .i_axi_bresp(axil_bresp),
        //
        // AXI read address channel signals
        .o_axi_arvalid(axil_arvalid),
        .i_axi_arready(axil_arready),
        .o_axi_araddr(axil_araddr),
        .o_axi_arprot(axil_arprot),
        //
        // AXI read data channel signals
        .i_axi_rvalid(axil_rvalid),
        .o_axi_rready(axil_rready),
        .i_axi_rdata(axil_rdata),
        .i_axi_rresp(axil_rresp)
    );


endmodule