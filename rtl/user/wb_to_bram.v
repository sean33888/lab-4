`timescale 1ns / 1ps

module wb_to_bram #(
    parameter WB_ADDR_WIDTH = 12,
    parameter WB_DATA_WIDTH = 32,
    parameter BRAM_ADDR_WIDTH = 20 // Matches N in bram module
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
    output wire [WB_DATA_WIDTH-1:0]    wbs_dat_o
);

    // BRAM interface signals
    wire [3:0]                  bram_WE0;
    wire                        bram_EN0;
    wire [31:0]                 bram_Di0;
    wire [31:0]                 bram_Do0;
    wire [31:0]                 bram_A0;

    // Wishbone FSM
    parameter WB_FSM_IDLE   = 2'b00;
    parameter WB_FSM_ACCESS = 2'b01;
    parameter WB_FSM_ACK    = 2'b10;

    reg [1:0]                   wb_fsm;
    reg                         wb_ack_reg;
    reg [WB_DATA_WIDTH-1:0]     wb_data_out;

    // Wishbone transaction handling
    wire                        wb_transaction_valid;
    assign wb_transaction_valid = wbs_cyc_i & wbs_stb_i;

    // BRAM control signals
    assign bram_EN0 = (wb_fsm == WB_FSM_ACCESS);
    assign bram_WE0 = {4{wbs_we_i & (wb_fsm == WB_FSM_ACCESS)}} & wbs_sel_i;
    assign bram_Di0 = wbs_dat_i;
    assign bram_A0  = {{(32-WB_ADDR_WIDTH){1'b0}}, wbs_adr_i}; // Zero-extend 12-bit address to 32 bits
    assign wbs_dat_o = wb_data_out;
    assign wbs_ack_o = wb_ack_reg;

    // Wishbone FSM
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i) begin
            wb_fsm <= WB_FSM_IDLE;
            wb_ack_reg <= 1'b0;
            wb_data_out <= {WB_DATA_WIDTH{1'b0}};
        end else begin
            case (wb_fsm)
                WB_FSM_IDLE: begin
                    wb_ack_reg <= 1'b0;
                    if (wb_transaction_valid) begin
                        wb_fsm <= WB_FSM_ACCESS;
                    end
                end
                WB_FSM_ACCESS: begin
                    wb_fsm <= WB_FSM_ACK;
                    wb_data_out <= bram_Do0; // Capture read data
                end
                WB_FSM_ACK: begin
                    wb_fsm <= WB_FSM_IDLE;
                    wb_ack_reg <= 1'b1;
                end
                default: begin
                    wb_fsm <= WB_FSM_IDLE;
                    wb_ack_reg <= 1'b0;
                end
            endcase
        end
    end

    // Instantiate BRAM module
    bram bram_inst (
        .CLK(wb_clk_i),
        .WE0(bram_WE0),
        .EN0(bram_EN0),
        .Di0(bram_Di0),
        .Do0(bram_Do0),
        .A0(bram_A0)
    );

endmodule
