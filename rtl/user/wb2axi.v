`timescale 1ns / 1ps

module wb_to_fir #(
    parameter WB_ADDR_WIDTH = 12,
    parameter WB_DATA_WIDTH = 32,
    parameter AXIS_DATA_WIDTH = 32,
    parameter AXIS_KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter Tape_Num = 11
) (
    // Wishbone Slave Interface
    input  wire                        wb_clk_i,
    input  wire                        wb_rst_i,
    input  wire                        wbs_stb_i,
    input  wire                        wbs_cyc_i,
    input  wire                        wbs_we_i,
    input  wire [3:0]                  wbs_sel_i,
    input  wire [WB_DATA_WIDTH-1:0]    wbs_dat_i,
    input  wire [WB_ADDR_WIDTH-1:0]    wbs_adr_i,
    output wire                        wbs_ack_o,
    output wire [WB_DATA_WIDTH-1:0]    wbs_dat_o,

    // BRAM for tap RAM
    output wire [3:0]                  tap_WE,
    output wire                        tap_EN,
    output wire [WB_DATA_WIDTH-1:0]    tap_Di,
    output wire [WB_ADDR_WIDTH-1:0]    tap_A,
    input  wire [WB_DATA_WIDTH-1:0]    tap_Do,

    // BRAM for data RAM
    output wire [3:0]                  data_WE,
    output wire                        data_EN,
    output wire [WB_DATA_WIDTH-1:0]    data_Di,
    output wire [WB_ADDR_WIDTH-1:0]    data_A,
    input  wire [WB_DATA_WIDTH-1:0]    data_Do
);

    // Internal signals for AXI-Lite
    wire                        awready;
    wire                        wready;
    wire                        awvalid;
    wire [WB_ADDR_WIDTH-1:0]    awaddr;
    wire                        wvalid;
    wire [WB_DATA_WIDTH-1:0]    wdata;
    wire                        arready;
    wire                        rready;
    wire                        arvalid;
    wire [WB_ADDR_WIDTH-1:0]    araddr;
    wire                        rvalid;
    wire [WB_DATA_WIDTH-1:0]    rdata;

    // Internal signals for AXI-Stream
    wire                        ss_tvalid;
    wire [AXIS_DATA_WIDTH-1:0]  ss_tdata;
    wire                        ss_tlast;
    wire                        ss_tready;
    wire                        sm_tready;
    wire                        sm_tvalid;
    wire [AXIS_DATA_WIDTH-1:0]  sm_tdata;
    wire                        sm_tlast;

    // Wishbone FSM
    parameter WB_FSM_IDLE   = 3'b000;
    parameter WB_FSM_WRITE  = 3'b001;
    parameter WB_FSM_READ   = 3'b010;
    parameter WB_FSM_STREAM = 3'b011;
    parameter WB_FSM_ACK    = 3'b100;

    reg [2:0]                   wb_fsm;
    reg [WB_ADDR_WIDTH-1:0]     wb_addr_reg;
    reg [WB_DATA_WIDTH-1:0]     wb_data_reg;
    reg                         wb_ack_reg;
    reg [WB_DATA_WIDTH-1:0]     wb_data_out;

    // Address decoding
    wire                        is_config;
    wire                        is_stream;
    assign is_config = (wbs_adr_i < 12'h100); // Config registers at 0x00 to 0xFF
    assign is_stream = (wbs_adr_i == 12'h100); // Stream data at 0x100

    // Wishbone FSM
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_fsm <= WB_FSM_IDLE;
            wb_addr_reg <= {WB_ADDR_WIDTH{1'b0}};
            wb_data_reg <= {WB_DATA_WIDTH{1'b0}};
            wb_ack_reg <= 1'b0;
            wb_data_out <= {WB_DATA_WIDTH{1'b0}};
        end else begin
            case (wb_fsm)
                WB_FSM_IDLE: begin
                    wb_ack_reg <= 1'b0;
                    if (wbs_cyc_i & wbs_stb_i) begin
                        wb_addr_reg <= wbs_adr_i;
                        wb_data_reg <= wbs_dat_i;
                        if (is_config) begin
                            if (wbs_we_i) begin
                                wb_fsm <= WB_FSM_WRITE;
                            end else begin
                                wb_fsm <= WB_FSM_READ;
                            end
                        end else if (is_stream && wbs_we_i) begin
                            wb_fsm <= WB_FSM_STREAM;
                        end else begin
                            wb_fsm <= WB_FSM_ACK; // Error case
                            wb_data_out <= {WB_DATA_WIDTH{1'b0}};
                        end
                    end
                end
                WB_FSM_WRITE: begin
                    if (awready && wready) begin
                        wb_fsm <= WB_FSM_ACK;
                        wb_ack_reg <= 1'b1;
                    end
                end
                WB_FSM_READ: begin
                    if (arready && rvalid) begin
                        wb_fsm <= WB_FSM_ACK;
                        wb_ack_reg <= 1'b1;
                        wb_data_out <= rdata;
                    end
                end
                WB_FSM_STREAM: begin
                    if (ss_tready) begin
                        wb_fsm <= WB_FSM_ACK;
                        wb_ack_reg <= 1'b1;
                    end
                end
                WB_FSM_ACK: begin
                    wb_fsm <= WB_FSM_IDLE;
                    wb_ack_reg <= 1'b0;
                    wb_addr_reg <= {WB_ADDR_WIDTH{1'b0}};
                    wb_data_reg <= {WB_DATA_WIDTH{1'b0}};
                    wb_data_out <= {WB_DATA_WIDTH{1'b0}};
                end
                default: begin
                    wb_fsm <= WB_FSM_IDLE;
                    wb_ack_reg <= 1'b0;
                end
            endcase
        end
    end

    // AXI-Lite control signals
    assign awvalid = (wb_fsm == WB_FSM_WRITE);
    assign awaddr = wb_addr_reg;
    assign wvalid = (wb_fsm == WB_FSM_WRITE);
    assign wdata = wb_data_reg;
    assign arvalid = (wb_fsm == WB_FSM_READ);
    assign araddr = wb_addr_reg;
    assign rready = (wb_fsm == WB_FSM_READ);

    // AXI-Stream control signals
    assign ss_tvalid = (wb_fsm == WB_FSM_STREAM);
    assign ss_tdata = wb_data_reg;
    assign ss_tlast = 1'b1; // Single beat per transaction
    assign sm_tready = 1'b1; // Always ready to accept output

    // Wishbone output
    assign wbs_ack_o = wb_ack_reg;
    assign wbs_dat_o = wb_data_out;

    // Instantiate FIR module
    fir #(
        .pADDR_WIDTH(WB_ADDR_WIDTH),
        .pDATA_WIDTH(WB_DATA_WIDTH),
        .Tape_Num(Tape_Num)
    ) fir_inst (
        .awready(awready),
        .wready(wready),
        .awvalid(awvalid),
        .awaddr(awaddr),
        .wvalid(wvalid),
        .wdata(wdata),
        .arready(arready),
        .rready(rready),
        .arvalid(arvalid),
        .araddr(araddr),
        .rvalid(rvalid),
        .rdata(rdata),
        .ss_tvalid(ss_tvalid),
        .ss_tdata(ss_tdata),
        .ss_tlast(ss_tlast),
        .ss_tready(ss_tready),
        .sm_tready(sm_tready),
        .sm_tvalid(sm_tvalid),
        .sm_tdata(sm_tdata),
        .sm_tlast(sm_tlast),
        .tap_WE(tap_WE),
        .tap_EN(tap_EN),
        .tap_Di(tap_Di),
        .tap_A(tap_A),
        .tap_Do(tap_Do),
        .data_WE(data_WE),
        .data_EN(data_EN),
        .data_Di(data_Di),
        .data_A(data_A),
        .data_Do(data_Do),
        .axis_clk(wb_clk_i),
        .axis_rst_n(~wb_rst_i)
    );

endmodule
