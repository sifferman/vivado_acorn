
module axi_mm2s_test #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter ID_WIDTH   = 8
) (
    input  wire                  axi_clk,
    input  wire                  axi_resetn,

    // AXI4 Read Address Interface Signals
    input  wire [ID_WIDTH-1:0]   s_axi_arid,
    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire [7:0]            s_axi_arlen,
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,

    // AXI4 Read Interface Signals
    output reg  [ID_WIDTH-1:0]   s_axi_rid,
    output reg  [DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0]            s_axi_rresp,
    output reg                   s_axi_rlast,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready,

    // Write Interface
    input  wire                    s_axis_aclk,
    input  wire                    s_axis_aresetn,
    output wire                    s_axis_tready,
    input  wire                    s_axis_tvalid,
    input  wire [DATA_WIDTH-1:0]   s_axis_tdata,
    input  wire                    s_axis_tlast,
    input  wire [DATA_WIDTH/8-1:0] s_axis_tkeep
);

    reg [8:0]          burst_countdown_q, burst_countdown_d;
    reg [ID_WIDTH-1:0] arid_q, arid_d;

    always @(posedge s_axis_aclk) begin
        if (s_axis_tready && s_axis_tvalid)
            s_axi_rdata <= s_axis_tdata;
    end
    assign s_axis_tready = 1;

    always @(posedge axi_clk) begin
        if (!axi_resetn) begin
            burst_countdown_q <= 9'd0;
            arid_q <= {ID_WIDTH{1'bx}};
        end else begin
            burst_countdown_q <= burst_countdown_d;
            arid_q <= arid_d;
        end
    end

    always @* begin
        s_axi_arready = 0;
        burst_countdown_d = burst_countdown_q;
        arid_d = arid_q;

        s_axi_rid    = {ID_WIDTH{1'bx}};
        s_axi_rresp  = 2'bxx;
        s_axi_rlast  = 1'bx;
        s_axi_rvalid = 0;

        if (burst_countdown_q == 0) begin
            s_axi_arready = 1;
            if (s_axi_arvalid && s_axi_arready) begin
                burst_countdown_d = s_axi_arlen + 1;
                arid_d            = s_axi_arid;
            end
        end else begin
            s_axi_rid    = arid_q;
            s_axi_rresp  = 2'b00;
            s_axi_rlast  = (burst_countdown_q == 1);
            s_axi_rvalid = 1;

            if (s_axi_rvalid && s_axi_rready) begin
                burst_countdown_d = burst_countdown_q - 1;
            end
        end
    end

endmodule
