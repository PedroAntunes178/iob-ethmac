`include "timescale.v"

module iob_iob2wishbone #(
    parameter ADDR_W = 32,
    parameter DATA_W = 32,
    parameter READ_BYTES = 4
) (
    input wire clk_i,
    input wire arst_i,

    // IOb interface
    input  wire                valid_i,
    input  wire [ADDR_W-1:0]   address_i,
    input  wire [DATA_W-1:0]   wdata_i,
    input  wire [DATA_W/8-1:0] wstrb_i,
    output  reg [DATA_W-1:0]   rdata_o,
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
    
    localparam AXIL_ADDR_W = ADDR_W;
    localparam AXIL_DATA_W = DATA_W;
    localparam AXI_ID_W = 1;
    localparam AXI_RESP_W = 2;
    localparam AXI_QOS_W = 4;
    localparam RB_MASK = {1'b0, {READ_BYTES{1'b1}}};

    // IOb auxiliar wires
    wire                valid_r;
    wire [ADDR_W-1:0]   address_r;
    wire [DATA_W-1:0]   wdata_r;
    wire                ready;
    wire                ready_r;
    // Wishbone auxiliar wire
    wire wb_reset;
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
    wire                     wr = valid_i & |wstrb_i;
    wire                     rd = valid_i & ~|wstrb_i;
    reg                      wr_reg, rd_reg;
    reg                      wvalid_ack;
    reg                      axil_rvalid_reg;
    reg                      rready_ack;

    // Logic

    assign axil_awaddr  = address_i;
    assign axil_araddr  = address_i;
    assign axil_wdata   = wdata_i;
    assign axil_wstrb   = wstrb_i;

    // AXI IDs
    assign axil_awid = {AXI_ID_W{1'b0}};
    assign axil_wid  = {AXI_ID_W{1'b0}};
    assign axil_arid = {AXI_ID_W{1'b0}};

    // Protection types
    assign axil_awprot = 3'd2;
    assign axil_arprot = 3'd2;

    // Quality of services
    assign axil_awqos = {AXI_QOS_W{1'b0}};
    assign axil_arqos = {AXI_QOS_W{1'b0}};

    always @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            rdata_o <= {AXIL_DATA_W{1'b0}};
        end else begin
            rdata_o <= axil_rdata;
        end
    end

    always @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            wr_reg <= 1'b0;
            rd_reg <= 1'b0;
        end else begin
            wr_reg <= wr;
            rd_reg <= rd;
        end
    end

    assign axil_awvalid = (wr | wr_reg) & ~awvalid_ack;
    always @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            awvalid_ack <= 1'b0;
        end else if (axil_awvalid & axil_awready) begin
            awvalid_ack <= 1'b1;
        end else if (axil_bvalid) begin
            awvalid_ack <= 1'b0;
        end
    end

    assign axil_wvalid = (wr | wr_reg)  & ~wvalid_ack;
    always @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            wvalid_ack <= 1'b0;
        end else if (axil_wvalid & axil_wready) begin
            wvalid_ack <= 1'b1;
        end else begin
            wvalid_ack <= 1'b0;
        end
    end

    assign axil_bready = 1'b1;

    always @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            axil_rvalid_reg <= 1'b0;
        end else begin
            axil_rvalid_reg <= axil_rvalid;
        end
    end

    assign axil_arvalid = (rd | rd_reg) & ~arvalid_ack;
    always @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            arvalid_ack <= 1'b0;
        end else if (axil_arvalid & axil_arready) begin
            arvalid_ack <= 1'b1;
        end else if (axil_rvalid | axil_rvalid_reg) begin
            arvalid_ack <= 1'b0;
        end
    end

    assign axil_rready = (rd | rd_reg) & ~rready_ack;
    always @(posedge clk_i, posedge arst_i) begin
        if (arst_i) begin
            rready_ack <= 1'b0;
        end else if (axil_rvalid & axil_rready) begin
            rready_ack <= 1'b1;
        end else begin
            rready_ack <= 1'b0;
        end
    end

    assign ready = axil_bvalid | rready_ack;


    assign wb_addr_o[1:0] = 2'b00;
    axlite2wbsp #(
        .C_AXI_DATA_WIDTH(DATA_W),// Width of the AXI R&W data
        .C_AXI_ADDR_WIDTH(ADDR_W),	// AXI Address width
        .LGFIFO(4),
        .OPT_READONLY(1'b0),
        .OPT_WRITEONLY(1'b0)
    ) axlite2wbsp (
        .i_clk(clk_i),	// System clock
        .i_axi_reset_n(arst_i),

        // AXI write address channel signals
        .i_axi_awvalid(axil_awvalid),
        .o_axi_awready(axil_awready),
        .i_axi_awaddr(axil_awaddr),
        .i_axi_awprot(axil_awprot),
        // AXI write data channel signals
        .i_axi_wvalid(axil_wvalid),
        .o_axi_wready(axil_wready), 
        .i_axi_wdata(axil_wdata),
        .i_axi_wstrb(axil_wstrb),
        // AXI write response channel signals
        .o_axi_bvalid(axil_bvalid),
        .i_axi_bready(axil_bready),
        .o_axi_bresp(axil_bresp),
        // AXI read address channel signals
        .i_axi_arvalid(axil_arvalid),
        .o_axi_arready(axil_arready),
        .i_axi_araddr(axil_araddr),
        .i_axi_arprot(axil_arprot),
        // AXI read data channel signals
        .o_axi_rvalid(axil_rvalid),
        .i_axi_rready(axil_rready),
        .o_axi_rdata(axil_rdata),
        .o_axi_rresp(axil_rresp),
        // Wishbone signals
        // We'll share the clock and the reset
        .o_reset(wb_reset),
        .o_wb_cyc(wb_cyc_o),
        .o_wb_stb(wb_stb_o),
        .o_wb_we(wb_we_o),
        .o_wb_addr(wb_addr_o[ADDR_W-1:2]),
        .o_wb_data(wb_data_o),
        .o_wb_sel(wb_select_o),
        .i_wb_stall(1'b0),
        .i_wb_ack(wb_ack_i),
        .i_wb_data(wb_data_i),
        .i_wb_err(wb_error_i)
    );

    

endmodule