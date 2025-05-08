//`timescale 1ns / 1ps
////////////////////////////////////////////////////////////////////////////////////
//// Company: 
//// Engineer: 
//// 
//// Create Date: 2025/03/16 10:04:17
//// Design Name: 
//// Module Name: fir1
//// Project Name: 
//// Target Devices: 
//// Tool Versions: 
//// Description: 
//// 
//// Dependencies: 
//// 
//// Revision:
//// Revision 0.01 - File Created
//// Additional Comments:
//// 
////////////////////////////////////////////////////////////////////////////////////


//module fir1 
//#(  parameter pADDR_WIDTH = 12,
//    parameter pDATA_WIDTH = 32,
//    parameter Tape_Num    = 11
//)
//(
//    output  wire                     awready,
//    output  wire                     wready,
//    input   wire                     awvalid,
//    input   wire [(pADDR_WIDTH-1):0] awaddr,
//    input   wire                     wvalid,
//    input   wire [(pDATA_WIDTH-1):0] wdata,
//    output  wire                     arready,
//    input   wire                     rready,
//    input   wire                     arvalid,
//    input   wire [(pADDR_WIDTH-1):0] araddr,
//    output  wire                     rvalid,
//    output  wire [(pDATA_WIDTH-1):0] rdata,    
//    input   wire                     ss_tvalid, 
//    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
//    input   wire                     ss_tlast, 
//    output  wire                     ss_tready, 
//    input   wire                     sm_tready, 
//    output  wire                     sm_tvalid, 
//    output  wire [(pDATA_WIDTH-1):0] sm_tdata, 
//    output  wire                     sm_tlast, 
    
//    // bram for tap RAM
//    output  wire [3:0]               tap_WE,
//    output  wire                     tap_EN,
//    output  wire [(pDATA_WIDTH-1):0] tap_Di,
//    output  wire [(pADDR_WIDTH-1):0] tap_A,
//    input   wire [(pDATA_WIDTH-1):0] tap_Do,

//    // bram for data RAM
//    output  wire [3:0]               data_WE,
//    output  wire                     data_EN,
//    output  wire [(pDATA_WIDTH-1):0] data_Di,
//    output  wire [(pADDR_WIDTH-1):0] data_A,
//    input   wire [(pDATA_WIDTH-1):0] data_Do,

//    input   wire                     axis_clk,
//    input   wire                     axis_rst_n
//);


//reg                      tap_awready;
//reg                      tap_wready;
//reg                      tap_arready;
//reg [(pADDR_WIDTH-1):0]  tap_waddr;
//reg [(pADDR_WIDTH-1):0]  tap_raddr;
//reg [(pDATA_WIDTH-1):0]  tap_wdata;
//reg [(pDATA_WIDTH-1):0]  tap_rdata;
//reg [1:0]                tap_write_ready;
//reg                      tap_read_ready;
//reg                      tap_read_received;
//reg                      tap_read_sent;
//reg [1:0]                tap_write_resp_sent;  

//reg [(pADDR_WIDTH-1):0]  data_waddr;
//reg [(pDATA_WIDTH-1):0]  data_wdata;
//reg                      data_write_ready;

//reg [1:0]                running_fsm;
//reg [1:0]                running_fsm_xnt;
//reg                      ss_tlast_dly;

//reg                      calc_read;
//reg                      calc_read_dly;
//reg                      calc_write;
//wire                     calc_done; 
//reg  [(pADDR_WIDTH-1):0] calc_cnt;  
//wire [(pADDR_WIDTH-1):0] calc_read_addr;
//wire [(pADDR_WIDTH-1):0] calc_write_addr;
//reg  [2:0]               mem_ctrl_fsm;
//reg  [2:0]               mem_ctrl_fsm_nxt;
//reg                      first_read;
//reg                      first_around;

//reg [31:0]               ap_reg;
//reg [31:0]               data_length;
//reg [31:0]               tap_num;

//reg [(pDATA_WIDTH-1):0]  calc_data;
//reg [(pDATA_WIDTH-1):0]  multiply_data;
//reg                      result_done;
//reg                      result_done_dly;
//wire [(pDATA_WIDTH-1):0] data_Do_mod;

//assign awready          = tap_awready;
//assign wready           = tap_wready;
//assign arready          = tap_arready;

//// assuming no legacy data is allowed to read from shift register and 0 is used as default value
//assign data_Do_mod      =  first_around ? {(pDATA_WIDTH-1){1'b0}} : (calc_done ? ss_tdata : data_Do);
//assign calc_read_addr   =  first_read ? 12'd10 : (12'd10 - calc_cnt);
//assign calc_write_addr  =  (12'd10 - calc_cnt);

//assign tap_WE = {4{(&tap_write_ready && ap_reg[2])}};
//assign tap_EN = ((&tap_write_ready && ap_reg[2]) || (tap_read_received && ap_reg[2] && (tap_raddr != 12'b0) && (tap_raddr != 12'h10) && (tap_raddr != 12'h14)) || calc_read_dly);
//assign tap_A  = (&tap_write_ready && ap_reg[2]) ? (tap_waddr -12'h20) : ((tap_read_ready && ap_reg[2]) ? (tap_raddr - 12'h20)  : ((calc_read || first_read) ? (calc_read_addr << 12'd2) : 32'b0));
//assign tap_Di = (&tap_write_ready && ap_reg[2]) ? tap_wdata : 32'b0;
//assign rvalid = tap_read_sent;
//assign rdata  = tap_rdata;

//assign data_WE = {4{calc_write}};
//assign data_EN = (calc_write || calc_read_dly);
//assign data_A  = (calc_write ? (calc_write_addr << 12'd2) :  (((calc_read && (!calc_done)) || first_read) ? ((calc_read_addr - 12'd1) << 12'd2) : 32'b0));
//assign data_Di = (calc_write && (!calc_done)) ? data_Do_mod : data_wdata;

//assign sm_tdata  = calc_data;
//assign sm_tvalid = result_done;
//assign sm_tlast  = result_done && ss_tlast_dly;
//assign ss_tready = result_done_dly;

//assign calc_done = (calc_cnt == 12'd10);

//// memory control fsm
//// contorlling the read/write operation of  tap memory and data memory 
//always @(*) begin
//    mem_ctrl_fsm_nxt    <= 3'b000;
//    first_read          <= 1'b0;
//    calc_read           <= 1'b0;
//    calc_write          <= 1'b0;
//    if ((((!ap_reg[2]) && (!ap_reg[1])) || ap_reg[0]) && (data_write_ready))  begin
//        case(mem_ctrl_fsm)
//            3'b000: begin // mem first read
//                mem_ctrl_fsm_nxt <= 3'b001;
//                first_read       <= 1'b1;
//            end
//            3'b001: begin // first read bubble
//                mem_ctrl_fsm_nxt <= 3'b010;
//            end
//            3'b010: begin // mem read
//                mem_ctrl_fsm_nxt  <= 3'b011;                
//                calc_read         <= 1'b1;
//            end
//            3'b011: begin // mem write
//                if (calc_done) begin
//                    mem_ctrl_fsm_nxt    <= 3'b100;
//                end else begin
//                    mem_ctrl_fsm_nxt    <= 3'b010;
//                end
//                calc_write              <= 1'b1;
//            end                            
//            3'b100: begin // wait for sm_tready       
//                if (sm_tready && ss_tvalid) begin
//                    mem_ctrl_fsm_nxt    <= 3'b000; 
//                end
//            end
//            default: mem_ctrl_fsm_nxt    <= 3'b000;
//        endcase
//    end else begin
//        mem_ctrl_fsm_nxt <= 2'b00;
//    end
//end

//// data multiplication   
//always @(posedge axis_clk) begin
//    if ((calc_done && (mem_ctrl_fsm == 3'b100)) || ap_reg[0]) begin
//        multiply_data <= {pDATA_WIDTH{1'b0}};
//    end else if (calc_read_dly) begin 
//        multiply_data <= (tap_Do * data_Do_mod);
//    end
//end    

//// data adding
//always @(posedge axis_clk) begin
//    if (first_read) begin
//        calc_data <= {pDATA_WIDTH{1'b0}};
//    end else if ((calc_read && (calc_cnt != 12'd0)) || ((mem_ctrl_fsm == 3'b100) && (!result_done))) begin
//        calc_data <= calc_data + multiply_data;
//    end
//end  

//// indicating if the final result is valid
//always @(posedge axis_clk or negedge axis_rst_n) begin
//    if (!axis_rst_n) begin
//        result_done <= 1'b0;
//    end else if (ap_reg[0]) begin
//        result_done <= 1'b0;
//    end else if (calc_done && (mem_ctrl_fsm == 3'b100)) begin
//        result_done <= 1'b1;
//    end else if (sm_tready) begin
//        result_done <= 1'b0;
//    end
//end  

//// tap write addr sampling
//always @(posedge axis_clk) begin
//    if (awvalid) begin
//        tap_waddr <= awaddr; // assuming no illegal addr input
//    end 
//end

//// tap write data sampling
//always @(posedge axis_clk) begin
//    if (wvalid) begin
//        tap_wdata <= wdata;
//    end 
//end

//// tap read addr sampling
//always @(posedge axis_clk) begin
//    if (arvalid) begin       
//        tap_raddr <= araddr;        
//    end 
//end

//// tap read data sampling
//always @(posedge axis_clk) begin
//    if (tap_read_received) begin  
//        if (tap_raddr == 12'h0) begin
//            tap_rdata <= ap_reg;
//        end else if (tap_raddr == 12'h10)begin
//            tap_rdata <= data_length;
//        end else if (tap_raddr == 12'h14) begin
//            tap_rdata <= tap_num;    
//        end else if (!ap_reg[2]) begin   
//            tap_rdata <= 32'hffff_ffff;                
//        end else begin            
//            tap_rdata <= tap_Do & {pDATA_WIDTH{rvalid}};
//        end 
//    end 
//end

//// tap write resp sent[0] flag setting
//always @(posedge axis_clk or negedge axis_rst_n) begin
//    if (!axis_rst_n) begin
//        tap_write_resp_sent[0] <= 1'b0;
//    end else if (&tap_write_ready) begin
//        tap_write_resp_sent[0] <= 1'b0;        
//    end else if (tap_write_ready[0]) begin
//        tap_write_resp_sent[0] <= 1'b1;
//    end
//end

//// tap write resp sent[1] flag setting
//always @(posedge axis_clk or negedge axis_rst_n) begin
//    if (!axis_rst_n) begin
//        tap_write_resp_sent[1] <= 1'b0;
//    end else if (&tap_write_ready) begin
//        tap_write_resp_sent[1] <= 1'b0;        
//    end else if (tap_write_ready[1]) begin
//        tap_write_resp_sent[1] <= 1'b1;
//    end
//end

//// tap write addr flag setting
//always @(posedge axis_clk or negedge axis_rst_n) begin
//    if (!axis_rst_n) begin
//        tap_write_ready[0] <= 1'd0;    
//    end else if (awvalid && (!tap_write_ready[0]) && (!tap_awready)) begin
//        tap_write_ready[0] <= 1'b1;
//    end else if (&tap_write_ready) begin
//        tap_write_ready[0] <= 1'b0;
//    end
//end    

//// tap write addr ready output setting
//always @(posedge axis_clk or negedge axis_rst_n) begin
//    if (!axis_rst_n) begin
//        tap_awready <= 1'b0;
//    end else if (tap_write_ready[0] && (!tap_write_resp_sent[0])) begin
//        tap_awready <= 1'b1;
//    end else if (tap_awready) begin
//        tap_awready <= 1'b0;
//    end
//end  

//// tap write data flag setting
//always @(posedge axis_clk or negedge axis_rst_n) begin  
//    if (!axis_rst_n) begin
//        tap_write_ready[1] <= 1'd0;
//    end else if (wvalid && (!tap_write_ready[1]) && (!tap_wready)) begin     
//        tap_write_ready[1] <= 1'b1;
//    end else if (&tap_write_ready) begin
//        tap_write_ready[1] <= 1'b0;
//    end
//end

//// tap write data ready output setting
//always @(posedge axis_clk or negedge axis_rst_n) begin
//    if (!axis_rst_n) begin
//        tap_wready <= 1'b0;
//    end else if (tap_write_ready[1] && (!tap_write_resp_sent[1])) begin
//        tap_wready <= 1'b1;
//    end else if (tap_wready)begin
//        tap_wready <= 1'b0;
//    end
//end  

//// tap read addr flag setting
//always @(posedge axis_clk or negedge axis_rst_n) begin    
//    if (!axis_rst_n) begin
//        tap_read_ready <= 1'd0;
//    end else if (arvalid && (!tap_read_received) && (!tap_read_sent) && (!tap_read_ready)) begin     
//        tap_read_ready <= 1'b1;
//    end else if (tap_read_ready) begin
//        tap_read_ready <= 1'b0;
//    end
//end

//// tap read addr ready output setting
//always @(posedge axis_clk or negedge axis_rst_n) begin
//    if (!axis_rst_n) begin
//        tap_arready <= 1'b0;
//    end else if (tap_read_ready) begin     
//        tap_arready <= 1'b1;
//    end else begin
//        tap_arready <= 1'b0;
//    end
//end

//// misc flip flop
//always @(posedge axis_clk) begin    
//    tap_read_received <= tap_read_ready;
//    ss_tlast_dly      <= ss_tlast;
//    calc_read_dly     <= calc_read || first_read;    
//end

//// misc reset flip flop 0
//always @(posedge axis_clk or negedge axis_rst_n) begin    
//    if (!axis_rst_n) begin
//        result_done_dly   <= 1'b0;        
//    end else begin
//        result_done_dly   <= result_done;
//    end
//end

//// misc rest flip flop 1
//always @(posedge axis_clk or negedge axis_rst_n) begin  
//    if (!axis_rst_n) begin
//        tap_read_sent       <= 1'b0;     
//    end else if (tap_read_received) begin
//        tap_read_sent       <= 1'b1;
//    end else if (rready) begin
//        tap_read_sent       <= 1'b0;    
//    end
//end

//// ap_start flip flop
//always @(posedge axis_clk or negedge axis_rst_n) begin   
//    if (!axis_rst_n) begin        
//        ap_reg[0] <= 0;
//    end else if ((ap_reg[2]) && ((&tap_write_ready) && (tap_waddr == 12'h000))) begin
//        ap_reg[0] <= 1;
//    end else if (ap_reg[0] && data_write_ready) begin
//        ap_reg[0] <= 0;
//    end
//end

//// ap_done flip flop
//always @(posedge axis_clk or negedge axis_rst_n) begin    
//    if (!axis_rst_n) begin
//        ap_reg[1] <= 1'b0;
//    end else if (ss_tlast && sm_tready && result_done) begin
//        ap_reg[1] <= 1'b1;
//    end else if (tap_read_received) begin // read to clear
//        ap_reg[1] <= 1'b0;
//    end
//end

//// ap_idle flip flop
//// according to lecture notes, idle and done are set when last data is tranfered, but fir_tb assumed idle set after done deassert
//always @(posedge axis_clk or negedge axis_rst_n) begin   
//    if (!axis_rst_n) begin
//        ap_reg[2] <= 1'b1;
//    end else if (ap_reg[0] && data_write_ready) begin
//        ap_reg[2] <= 1'b0;
//    end else if (ap_reg[1] && tap_read_received) begin 
//        ap_reg[2] <= 1'b1;
//    end
//end

//// misc ap_reg flip flop
//always @(posedge axis_clk or negedge axis_rst_n) begin   
//    if (!axis_rst_n) begin        
//        ap_reg[31:3] <= 0;
//    end
//end

//// data_length flip flop
//always @(posedge axis_clk or negedge axis_rst_n) begin   
//    if (!axis_rst_n) begin
//        data_length <= tap_wdata;
//    end else if ((&tap_write_ready) && (tap_waddr == 12'h10) && (ap_reg[2])) begin
//        data_length <= tap_wdata;
//    end
//end

//// tap_num flip flop
//always @(posedge axis_clk or negedge axis_rst_n) begin   
//    if (!axis_rst_n) begin
//        tap_num <= tap_wdata;
//    end else if ((&tap_write_ready) && (tap_waddr == 12'h14) && (ap_reg[2])) begin
//        tap_num <= tap_wdata;
//    end
//end

//// data write flag setting
//always @(posedge axis_clk or negedge axis_rst_n) begin    
//    if (!axis_rst_n) begin
//        data_write_ready <= 1'd0;    
//    end else if (ss_tvalid) begin
//        data_write_ready <= 1'b1;        
//    end else if (ss_tlast && calc_done) begin
//        data_write_ready <= 1'b0;
//    end
//end

//// data wdata sampling
//always @(posedge axis_clk) begin    
//    if (ss_tvalid) begin
//        data_wdata <= ss_tdata;        
//    end
//end

//// fsm flip flop
//always @(posedge axis_clk) begin    
//    mem_ctrl_fsm <= mem_ctrl_fsm_nxt;    
//end

//// calc_cnt flip flop
//always @(posedge axis_clk or negedge axis_rst_n) begin    
//    if (!axis_rst_n) begin
//        calc_cnt <= 12'd0;
//    end else if ((calc_done && (mem_ctrl_fsm == 3'b100) && ss_tvalid && sm_tready) || ((&tap_write_ready) && (tap_waddr == 12'h000) && ap_reg[2])) begin
//        calc_cnt <= 12'b0;
//    end else if ((!calc_done) && (first_read || calc_write)) begin
//        calc_cnt <= calc_cnt + 12'b1;
//    end
//end

//// first around flip flop
//always @(posedge axis_clk or negedge axis_rst_n) begin    
//    if (!axis_rst_n) begin
//        first_around <= 1'd0;
//    end else if ((&tap_write_ready) && (tap_waddr == 12'h000) && ap_reg[2]) begin
//        first_around <= 1'b1;
//    end else if (calc_cnt == 12'd10) begin
//        first_around <= 1'b0;
//    end
//end

//endmodule


(* use_dsp = "no" *)
module fir1 
#(  parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)
(
    output  wire                     awready,
    output  wire                     wready,
    input   wire                     awvalid,
    input   wire [(pADDR_WIDTH-1):0] awaddr,
    input   wire                     wvalid,
    input   wire [(pDATA_WIDTH-1):0] wdata,
    output  wire                     arready,
    input   wire                     rready,
    input   wire                     arvalid,
    input   wire [(pADDR_WIDTH-1):0] araddr,
    output  wire                     rvalid,
    output  wire [(pDATA_WIDTH-1):0] rdata,    
    input   wire                     ss_tvalid, 
    input   wire [(pDATA_WIDTH-1):0] ss_tdata, 
    input   wire                     ss_tlast, 
    output  wire                     ss_tready, 
    input   wire                     sm_tready, 
    output  wire                     sm_tvalid, 
    output  wire [(pDATA_WIDTH-1):0] sm_tdata, 
    output  wire                     sm_tlast, 
    
    // bram for tap RAM
    output  wire [3:0]               tap_WE,
    output  wire                     tap_EN,
    output  wire [(pDATA_WIDTH-1):0] tap_Di,
    output  wire [(pADDR_WIDTH-1):0] tap_A,
    input   wire [(pDATA_WIDTH-1):0] tap_Do,

    // bram for data RAM
    output  wire [3:0]               data_WE,
    output  wire                     data_EN,
    output  wire [(pDATA_WIDTH-1):0] data_Di,
    output  wire [(pADDR_WIDTH-1):0] data_A,
    input   wire [(pDATA_WIDTH-1):0] data_Do,

    input   wire                     axis_clk,
    input   wire                     axis_rst_n
);

    // write your code here!
    // WE based on data width
    wire [3:0]                       we_sel;

    assign we_sel[0]   = (pDATA_WIDTH >= 1);
    assign we_sel[1]   = (pDATA_WIDTH >= 9);
    assign we_sel[2]   = (pDATA_WIDTH >= 17);
    assign we_sel[3]   = (pDATA_WIDTH >= 25);


    // AP Configuration Register
    wire                             ap_WE;
    wire                             ap_EN;
    wire [2:0]                       ap_Di;
    wire [(pDATA_WIDTH-1):0]         ap_Do;
    reg  [2:0]                       ap_reg;

    assign ap_Do = {pDATA_WIDTH{ap_EN}} & {{pDATA_WIDTH-3{1'b0}}, ap_reg};

    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (~axis_rst_n) begin
            ap_reg <= 3'b100;
        end else begin
            if (ap_reg[1]) begin
                if (ap_EN) begin
                    if (ap_WE) begin
                        ap_reg <= {ap_Di[2], 1'b0, ap_Di[0]};
                    end else begin
                        ap_reg <= {ap_reg[2], 1'b0, ap_reg[0]};
                    end
                end else begin
                    ap_reg <= ap_reg;
                end
            end else begin
                if (ap_WE & ap_EN) begin
                    ap_reg <= ap_Di;
                end else begin
                    ap_reg <= ap_reg;
                end
            end
        end
    end


    // Length Configuration Register
    wire [3:0]                       len_WE;
    wire                             len_EN;
    wire [(pDATA_WIDTH-1):0]         len_Di;
    wire [(pDATA_WIDTH-1):0]         len_Do;
    reg  [(pDATA_WIDTH-1):0]         len_reg;

    assign len_Do = {pDATA_WIDTH{len_EN}} & len_reg;

    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (~axis_rst_n) begin
            len_reg <= 3'b000;
        end else begin
            if (len_EN) begin
	            if (len_WE[0]) begin
                    len_reg[7:0]   <= len_Di[7:0];
                end
                if (len_WE[1]) begin
                    len_reg[15:8]  <= len_Di[15:8];
                end
                if (len_WE[2]) begin
                    len_reg[23:16] <= len_Di[23:16];
                end
                if (len_WE[3]) begin
                    len_reg[31:24] <= len_Di[31:24];
                end
            end
        end
    end


    // Tap Number Configuration Register
    wire [3:0]                       num_WE;
    wire                             num_EN;
    wire [(pDATA_WIDTH-1):0]         num_Di;
    wire [(pDATA_WIDTH-1):0]         num_Do;
    reg  [(pDATA_WIDTH-1):0]         num_reg;

    assign num_Do = {pDATA_WIDTH{num_EN}} & num_reg;

    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (~axis_rst_n) begin
            num_reg <= 3'b000;
        end else begin
            if (num_EN) begin
	            if (num_WE[0]) begin
                    num_reg[7:0]   <= num_Di[7:0];
                end
                if (num_WE[1]) begin
                    num_reg[15:8]  <= num_Di[15:8];
                end
                if (num_WE[2]) begin
                    num_reg[23:16] <= num_Di[23:16];
                end
                if (num_WE[3]) begin
                    num_reg[31:24] <= num_Di[31:24];
                end
            end
        end
    end


    // AXI-Lite and AXI-Stream FSM
    parameter AXILITE_FSM_RESET    = 3'b000;
    parameter AXILITE_FSM_IDLE     = 3'b001;
    parameter AXILITE_FSM_AWREADY  = 3'b010;
    parameter AXILITE_FSM_WREADY   = 3'b011;
    parameter AXILITE_FSM_ARREADY  = 3'b100;
    parameter AXILITE_FSM_RREADY   = 3'b101;
    parameter AXISTREAM_FSM_RESET  = 3'b000;
    parameter AXISTREAM_FSM_IDLE   = 3'b001;
    parameter AXISTREAM_FSM_INIT   = 3'b010;
    parameter AXISTREAM_FSM_UPDATE = 3'b011;
    parameter AXISTREAM_FSM_MULT   = 3'b100;
    parameter AXISTREAM_FSM_SUM    = 3'b101;
    parameter AXISTREAM_FSM_OUT    = 3'b110;

    reg  [2:0]                       axilite_fsm;
    reg  [(pADDR_WIDTH-1):0]         axilite_A_pre;
    reg  [(pDATA_WIDTH-1):0]         axilite_Di_pre;
    reg                              axilite_rr;
    wire                             axilite_active;
    wire                             axilite_ap;
    wire                             axilite_len;
    wire                             axilite_num;
    wire                             axilite_tap;
    wire [(pDATA_WIDTH-1):0]         axilite_Do;
    wire [(pADDR_WIDTH-1):0]         axilite_A;
    wire [(pDATA_WIDTH-1):0]         axilite_Di;

    reg  [2:0]                       axistream_fsm;
    reg  [(pADDR_WIDTH-1):0]         axistream_A;
    reg  [(pDATA_WIDTH-1):0]         axistream_data_Di;
    reg  [(pDATA_WIDTH-1):0]         axistream_data_Do;
    reg  [(pDATA_WIDTH-1):0]         axistream_mult;
    reg  [(pDATA_WIDTH-1):0]         axistream_sum;
    reg                              axistream_sent;
    reg                              axistream_last;
    wire                             axistream_active;
    wire                             axistream_ap;
    wire                             axistream_tap;
    wire [(pADDR_WIDTH-1):0]         axistream_tap_A;


    // AXI-Lite
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (~axis_rst_n) begin
            axilite_fsm    <= AXILITE_FSM_RESET;
            axilite_A_pre  <= {pADDR_WIDTH{1'b0}};
            axilite_Di_pre <= {pDATA_WIDTH{1'b0}};
            axilite_rr     <= 1'b0;
        end else begin
            case (axilite_fsm)
                AXILITE_FSM_RESET: begin
                    axilite_fsm    <= AXILITE_FSM_IDLE;
                    axilite_A_pre  <= {pADDR_WIDTH{1'b0}};
                    axilite_Di_pre <= {pDATA_WIDTH{1'b0}};
                    axilite_rr     <= 1'b0;
                end
                AXILITE_FSM_IDLE: begin
                    if (awvalid & ~(arvalid & axilite_rr)) begin
                        axilite_fsm    <= AXILITE_FSM_AWREADY;
                        axilite_A_pre  <= awaddr;
                        axilite_Di_pre <= {pDATA_WIDTH{1'b0}};
                        axilite_rr     <= 1'b1;
                    end else if (wvalid & ~(arvalid & axilite_rr)) begin
                        axilite_fsm    <= AXILITE_FSM_WREADY;
                        axilite_A_pre  <= {pADDR_WIDTH{1'b0}};
                        axilite_Di_pre <= wdata;
                        axilite_rr     <= 1'b1;
                    end else if (arvalid) begin
                        axilite_fsm    <= AXILITE_FSM_ARREADY;
                        axilite_A_pre  <= araddr;
                        axilite_Di_pre <= {pDATA_WIDTH{1'b0}};
                        axilite_rr     <= 1'b0;
                    end else begin
                        axilite_fsm    <= AXILITE_FSM_IDLE;
                        axilite_A_pre  <= {pADDR_WIDTH{1'b0}};
                        axilite_Di_pre <= {pDATA_WIDTH{1'b0}};
                        axilite_rr     <= axilite_rr;
                    end
                end
                AXILITE_FSM_AWREADY: begin
                    if (wvalid) begin
                        axilite_fsm    <= AXILITE_FSM_IDLE;
                        axilite_A_pre  <= {pADDR_WIDTH{1'b0}};
                        axilite_Di_pre <= {pDATA_WIDTH{1'b0}};
                        axilite_rr     <= axilite_rr;
                    end else begin
                        axilite_fsm    <= AXILITE_FSM_AWREADY;
                        axilite_A_pre  <= axilite_A;
                        axilite_Di_pre <= {pDATA_WIDTH{1'b0}};
                        axilite_rr     <= axilite_rr;
                    end
                end
                AXILITE_FSM_WREADY: begin
                    if (awvalid) begin
                        axilite_fsm    <= AXILITE_FSM_IDLE;
                        axilite_A_pre  <= {pADDR_WIDTH{1'b0}};
                        axilite_Di_pre <= {pDATA_WIDTH{1'b0}};
                        axilite_rr     <= axilite_rr;
                    end else begin
                        axilite_fsm    <= AXILITE_FSM_WREADY;
                        axilite_A_pre  <= {pADDR_WIDTH{1'b0}};
                        axilite_Di_pre <= axilite_Di;
                        axilite_rr     <= axilite_rr;
                    end
                end                    
                AXILITE_FSM_ARREADY: begin
                    if (rready) begin
                        axilite_fsm    <= AXILITE_FSM_RREADY;
                        axilite_A_pre  <= axilite_A;
                        axilite_Di_pre <= {pDATA_WIDTH{1'b0}};
                        axilite_rr     <= axilite_rr;
                    end else begin
                        axilite_fsm    <= AXILITE_FSM_ARREADY;
                        axilite_A_pre  <= axilite_A;
                        axilite_Di_pre <= {pDATA_WIDTH{1'b0}};
                        axilite_rr     <= axilite_rr;
                    end
                end
                AXILITE_FSM_RREADY: begin
                    axilite_fsm    <= AXILITE_FSM_IDLE;
                    axilite_A_pre  <= {pADDR_WIDTH{1'b0}};
                    axilite_Di_pre <= {pDATA_WIDTH{1'b0}};
                    axilite_rr     <= axilite_rr;
                end
                default: begin
                    axilite_fsm    <= AXILITE_FSM_IDLE;
                    axilite_A_pre  <= {pADDR_WIDTH{1'b0}};
                    axilite_Di_pre <= {pDATA_WIDTH{1'b0}};
                    axilite_rr     <= 1'b0;
                end
            endcase
        end
    end

    // AXI-Stream
    always @(posedge axis_clk or negedge axis_rst_n) begin
        if (~axis_rst_n) begin
            axistream_fsm     <= AXISTREAM_FSM_RESET;
            axistream_A       <= {pADDR_WIDTH{1'b0}};
            axistream_data_Di <= {pDATA_WIDTH{1'b0}};
            axistream_data_Do <= {pDATA_WIDTH{1'b0}};
            axistream_mult    <= {pDATA_WIDTH{1'b0}};
            axistream_sum     <= {pDATA_WIDTH{1'b0}};
            axistream_sent    <= 1'b0;
            axistream_last    <= 1'b0;
        end else begin
            case (axistream_fsm)
                AXISTREAM_FSM_RESET: begin
                    axistream_fsm     <= AXISTREAM_FSM_IDLE;
                    axistream_A       <= {pADDR_WIDTH{1'b0}};
                    axistream_data_Di <= {pDATA_WIDTH{1'b0}};
                    axistream_data_Do <= {pDATA_WIDTH{1'b0}};
                    axistream_mult    <= {pDATA_WIDTH{1'b0}};
                    axistream_sum     <= {pDATA_WIDTH{1'b0}};
                    axistream_sent    <= 1'b0;    
                    axistream_last    <= 1'b0;
                end
                AXISTREAM_FSM_IDLE: begin
                    if (~axilite_ap & ap_reg[0] & ss_tvalid) begin
                        axistream_fsm     <= AXISTREAM_FSM_INIT;
                        axistream_A       <= Tape_Num - 1;
                        axistream_data_Di <= {pDATA_WIDTH{1'b0}};
                        axistream_data_Do <= {pDATA_WIDTH{1'b0}};
                        axistream_mult    <= {pDATA_WIDTH{1'b0}};
                        axistream_sum     <= {pDATA_WIDTH{1'b0}};
                        axistream_sent    <= 1'b0;
                        axistream_last    <= ss_tlast;
                    end else begin
                        axistream_fsm     <= AXISTREAM_FSM_IDLE;
                        axistream_A       <= {pADDR_WIDTH{1'b0}};
                        axistream_data_Di <= {pDATA_WIDTH{1'b0}};
                        axistream_data_Do <= {pDATA_WIDTH{1'b0}};
                        axistream_mult    <= {pDATA_WIDTH{1'b0}};
                        axistream_sum     <= {pDATA_WIDTH{1'b0}};
                        axistream_sent    <= 1'b0;
                        axistream_last    <= 1'b0;
                    end
                end
                AXISTREAM_FSM_INIT: begin
                    if (axistream_A != {pADDR_WIDTH{1'b0}}) begin
                        axistream_fsm     <= AXISTREAM_FSM_INIT;
                        axistream_A       <= axistream_A - {{pADDR_WIDTH-1{1'b0}}, 1'b1};
                        axistream_data_Di <= {pDATA_WIDTH{1'b0}};
                        axistream_data_Do <= {pDATA_WIDTH{1'b0}};
                        axistream_mult    <= {pDATA_WIDTH{1'b0}};
                        axistream_sum     <= {pDATA_WIDTH{1'b0}};
                        axistream_sent    <= 1'b0;
                        axistream_last    <= axistream_last;
                    end else begin
                        axistream_fsm     <= AXISTREAM_FSM_UPDATE;
                        axistream_A       <= {pADDR_WIDTH{1'b0}};
                        axistream_data_Di <= {pDATA_WIDTH{1'b0}};
                        axistream_data_Do <= {pDATA_WIDTH{1'b0}};
                        axistream_mult    <= {pDATA_WIDTH{1'b0}};
                        axistream_sum     <= {pDATA_WIDTH{1'b0}};
                        axistream_sent    <= 1'b0;
                        axistream_last    <= axistream_last;
                    end
                end
                AXISTREAM_FSM_UPDATE: begin
                    if (axistream_A == {pADDR_WIDTH{1'b0}}) begin
                        axistream_fsm     <= AXISTREAM_FSM_MULT;
                        axistream_A       <= {pADDR_WIDTH{1'b0}};
                        axistream_data_Di <= {pDATA_WIDTH{1'b0}};
                        axistream_data_Do <= ss_tdata;
                        axistream_mult    <= tap_Do;
                        axistream_sum     <= {pDATA_WIDTH{1'b0}};
                        axistream_sent    <= 1'b0;
                        axistream_last    <= axistream_last;
                    end else begin
                        axistream_fsm     <= AXISTREAM_FSM_MULT;
                        axistream_A       <= axistream_A;
                        axistream_data_Di <= axistream_data_Do;
                        axistream_data_Do <= data_Do;
                        axistream_mult    <= tap_Do;
                        axistream_sum     <= axistream_sum;
                        axistream_sent    <= 1'b0;
                        axistream_last    <= axistream_last;
                    end
                end
                AXISTREAM_FSM_MULT: begin
                    axistream_fsm     <= AXISTREAM_FSM_SUM;
                    axistream_A       <= axistream_A + {{pADDR_WIDTH-1{1'b0}}, 1'b1};
                    axistream_data_Di <= {pDATA_WIDTH{1'b0}};
                    axistream_data_Do <= axistream_data_Do;
                    axistream_mult    <= axistream_mult * axistream_data_Do;
                    axistream_sum     <= axistream_sum;
                    axistream_sent    <= 1'b0;
                    axistream_last    <= axistream_last;
                end
                AXISTREAM_FSM_SUM: begin
                    if (axistream_A == Tape_Num) begin
                        axistream_fsm     <= AXISTREAM_FSM_OUT;
                        axistream_A       <= {pADDR_WIDTH{1'b0}};
                        axistream_data_Di <= {pDATA_WIDTH{1'b0}};
                        axistream_data_Do <= {pDATA_WIDTH{1'b0}};
                        axistream_mult    <= {pDATA_WIDTH{1'b0}};
                        axistream_sum     <= axistream_sum + axistream_mult;
                        axistream_sent    <= 1'b0;
                        axistream_last    <= axistream_last;
                    end else begin
                        axistream_fsm     <= AXISTREAM_FSM_UPDATE;
                        axistream_A       <= axistream_A;
                        axistream_data_Di <= {pDATA_WIDTH{1'b0}};
                        axistream_data_Do <= axistream_data_Do;
                        axistream_mult    <= {pDATA_WIDTH{1'b0}};
                        axistream_sum     <= axistream_sum + axistream_mult;
                        axistream_sent    <= 1'b0;
                        axistream_last    <= axistream_last;
                    end
                end
                AXISTREAM_FSM_OUT: begin
                    if (axistream_last) begin
                        if (sm_tready) begin
                            axistream_fsm     <= AXISTREAM_FSM_IDLE;
                            axistream_A       <= {pADDR_WIDTH{1'b0}};
                            axistream_data_Di <= {pDATA_WIDTH{1'b0}};
                            axistream_data_Do <= {pDATA_WIDTH{1'b0}};
                            axistream_mult    <= {pDATA_WIDTH{1'b0}};
                            axistream_sum     <= {pDATA_WIDTH{1'b0}};
                            axistream_sent    <= sm_tready;
                            axistream_last    <= 1'b0;
                        end else begin
                            axistream_fsm     <= AXISTREAM_FSM_OUT;
                            axistream_A       <= {pADDR_WIDTH{1'b0}};
                            axistream_data_Di <= {pDATA_WIDTH{1'b0}};
                            axistream_data_Do <= {pDATA_WIDTH{1'b0}};
                            axistream_mult    <= {pDATA_WIDTH{1'b0}};
                            axistream_sum     <= axistream_sum;
                            axistream_sent    <= axistream_sent;
                            axistream_last    <= axistream_last;
                        end
                    end else begin
                        if (ss_tvalid & (sm_tready | axistream_sent)) begin
                            axistream_fsm     <= AXISTREAM_FSM_UPDATE;
                            axistream_A       <= {pADDR_WIDTH{1'b0}};
                            axistream_data_Di <= {pDATA_WIDTH{1'b0}};
                            axistream_data_Do <= {pDATA_WIDTH{1'b0}};
                            axistream_mult    <= {pDATA_WIDTH{1'b0}};
                            axistream_sum     <= {pDATA_WIDTH{1'b0}};
                            axistream_sent    <= sm_tready;
                            axistream_last    <= ss_tlast;
                        end else begin
                            axistream_fsm     <= AXISTREAM_FSM_OUT;
                            axistream_A       <= {pADDR_WIDTH{1'b0}};
                            axistream_data_Di <= {pDATA_WIDTH{1'b0}};
                            axistream_data_Do <= {pDATA_WIDTH{1'b0}};
                            axistream_mult    <= {pDATA_WIDTH{1'b0}};
                            axistream_sum     <= axistream_sum;
                            axistream_sent    <= axistream_sent | sm_tready;
                            axistream_last    <= axistream_last;
                        end
                    end
                end
                default: begin
                    axistream_fsm     <= AXISTREAM_FSM_IDLE;
                    axistream_A       <= {pADDR_WIDTH{1'b0}};
                    axistream_data_Di <= {pDATA_WIDTH{1'b0}};
                    axistream_data_Do <= {pDATA_WIDTH{1'b0}};
                    axistream_mult    <= {pDATA_WIDTH{1'b0}};
                    axistream_sum     <= {pDATA_WIDTH{1'b0}};
                    axistream_sent    <= 1'b0;
                    axistream_last    <= 1'b0;
               end
            endcase
        end
    end

    assign axilite_active   = (axilite_fsm != AXILITE_FSM_RESET) & (axilite_fsm != AXILITE_FSM_IDLE);
    assign axilite_ap       = axilite_active & (axilite_A == {pADDR_WIDTH{1'b0}});
    assign axilite_len      = axilite_active & (axilite_A >= {{pADDR_WIDTH-5{1'b0}},5'h10}) & (axilite_A <= {{pADDR_WIDTH-5{1'b0}},5'h13});
    assign axilite_num      = axilite_active & (axilite_A >= {{pADDR_WIDTH-5{1'b0}},5'h14}) & (axilite_A <= {{pADDR_WIDTH-5{1'b0}},5'h18});
    assign axilite_tap      = axilite_active & (axilite_A >= {{pADDR_WIDTH-8{1'b0}},8'h40}) & (axilite_A <= {{pADDR_WIDTH-8{1'b0}},8'hFF});
    assign axilite_Do       = {pDATA_WIDTH{axilite_ap  & ~axistream_ap                }} & ap_Do               |
                              {pDATA_WIDTH{axilite_ap  &  axistream_ap                }} & 3'b000              |
                              {pDATA_WIDTH{axilite_len                                }} & len_Do              |
                              {pDATA_WIDTH{axilite_num                                }} & num_Do              |                          
                              {pDATA_WIDTH{axilite_tap & (~ap_reg[0] & ~axistream_tap)}} & tap_Do              |
                              {pDATA_WIDTH{axilite_tap & ( ap_reg[0] |  axistream_tap)}} & {pDATA_WIDTH{1'b1}};
    assign axilite_A        = (axilite_fsm == AXILITE_FSM_WREADY) ? awaddr         : axilite_A_pre;
    assign axilite_Di       = (axilite_fsm == AXILITE_FSM_WREADY) ? axilite_Di_pre : wdata;

    assign axistream_active = (axistream_fsm != AXISTREAM_FSM_RESET) & (axistream_fsm != AXISTREAM_FSM_IDLE);
    assign axistream_ap     = (axistream_fsm == AXISTREAM_FSM_IDLE ) & ~axilite_ap & ap_reg[0] & ss_tvalid | (axistream_fsm == AXISTREAM_FSM_OUT) & axistream_last & sm_tready;
    assign axistream_tap    = (axistream_fsm == AXISTREAM_FSM_IDLE ) & ~axilite_ap & ap_reg[0] & ss_tvalid | axistream_active;
    assign axistream_tap_A  = (axistream_fsm == AXISTREAM_FSM_IDLE | axistream_fsm == AXISTREAM_FSM_INIT) ? {pADDR_WIDTH{1'b0}} : (axistream_A << 2);

    assign awready          = (axilite_fsm == AXILITE_FSM_IDLE   ) &  awvalid &          ~(arvalid & axilite_rr) | (axilite_fsm == AXILITE_FSM_WREADY );
    assign wready           = (axilite_fsm == AXILITE_FSM_IDLE   ) & ~awvalid & wvalid & ~(arvalid & axilite_rr) | (axilite_fsm == AXILITE_FSM_AWREADY);
    assign arready          = (axilite_fsm == AXILITE_FSM_IDLE   ) &  arvalid & ~((awvalid | wvalid) & ~axilite_rr);
    assign rvalid           = (axilite_fsm == AXILITE_FSM_RREADY );
    assign rdata            = {pDATA_WIDTH{rvalid}} & axilite_Do;

    assign ap_WE            = axilite_ap & ((axilite_fsm == AXILITE_FSM_AWREADY) & wvalid | (axilite_fsm == AXILITE_FSM_WREADY) & awvalid         ) | axistream_ap;
    assign ap_EN            = axilite_ap & ((axilite_fsm == AXILITE_FSM_AWREADY) & wvalid | (axilite_fsm == AXILITE_FSM_WREADY) & awvalid | rvalid) | axistream_ap;
    assign ap_Di            = {3{axilite_ap & ~axistream_ap}} & {(ap_reg[2] & ~axilite_Di[0]), 1'b0, (ap_reg[2] & axilite_Di[0])} | 
                              {3{              axistream_ap}} & {{2{sm_tlast}}, 1'b0};

    assign len_WE           = {4{axilite_len & ((axilite_fsm == AXILITE_FSM_AWREADY) & wvalid | (axilite_fsm == AXILITE_FSM_WREADY) & awvalid)}} & we_sel;
    assign len_EN           = axilite_len    & ((axilite_fsm == AXILITE_FSM_AWREADY) & wvalid | (axilite_fsm == AXILITE_FSM_WREADY) & awvalid | rvalid);
    assign len_Di           = axilite_Di;

    assign num_WE           = {4{axilite_num & ((axilite_fsm == AXILITE_FSM_AWREADY) & wvalid | (axilite_fsm == AXILITE_FSM_WREADY) & awvalid)}} & we_sel;
    assign num_EN           = axilite_num    & ((axilite_fsm == AXILITE_FSM_AWREADY) & wvalid | (axilite_fsm == AXILITE_FSM_WREADY) & awvalid | rvalid);
    assign num_Di           = axilite_Di;

    assign tap_WE           = {4{axilite_tap & ((axilite_fsm == AXILITE_FSM_AWREADY) & wvalid | (axilite_fsm == AXILITE_FSM_WREADY) & awvalid) & (~ap_reg[0] & ~axistream_tap)}} & we_sel;
    assign tap_EN           = axilite_tap    & ((axilite_fsm == AXILITE_FSM_AWREADY) & wvalid | (axilite_fsm == AXILITE_FSM_WREADY) & awvalid | rvalid) | axistream_tap;
    assign tap_Di           = axilite_Di;
    assign tap_A            = {pADDR_WIDTH{axilite_tap & (~ap_reg[0] & ~axistream_tap)}} & (axilite_A - {{pADDR_WIDTH-8{1'b0}},8'h40}) |
                              {pADDR_WIDTH{axistream_tap                              }} & axistream_tap_A;

    assign data_WE          = {4{(axistream_fsm == AXISTREAM_FSM_INIT) | (axistream_fsm == AXISTREAM_FSM_MULT) & (axistream_A != {pADDR_WIDTH{1'b0}})}} & we_sel;
    assign data_EN          = (axistream_fsm == AXISTREAM_FSM_INIT  )                                        | 
                              (axistream_fsm == AXISTREAM_FSM_UPDATE) & (axistream_A != {pADDR_WIDTH{1'b0}}) | 
                              (axistream_fsm == AXISTREAM_FSM_MULT  ) & (axistream_A != {pADDR_WIDTH{1'b0}}) ;
    assign data_Di          = axistream_data_Di;
    assign data_A           = {pADDR_WIDTH{(axistream_fsm == AXISTREAM_FSM_INIT)}} & (axistream_A << 2) |
                              {pADDR_WIDTH{(axistream_active & (axistream_fsm != AXISTREAM_FSM_INIT))}} & ((axistream_A - {{pADDR_WIDTH-1{1'b0}}, 1'b1}) << 2);

    assign ss_tready        = (axistream_fsm == AXISTREAM_FSM_UPDATE) & (axistream_A == {pADDR_WIDTH{1'b0}});
    assign sm_tvalid        = (axistream_fsm == AXISTREAM_FSM_OUT) & ~axistream_sent;
    assign sm_tdata         = axistream_sum;
    assign sm_tlast         = (axistream_fsm == AXISTREAM_FSM_OUT) & axistream_last;

endmodule