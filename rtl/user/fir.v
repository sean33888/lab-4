`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/03/09 23:06:29
// Design Name: 
// Module Name: fir
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
(* use_dsp = "no" *)
module fir 
#( 
    parameter pADDR_WIDTH = 12,
    parameter pDATA_WIDTH = 32,
    parameter Tape_Num    = 11
)
(
    output reg                     awready,
    output reg                     wready,
    input wire                     awvalid,
    input wire [(pADDR_WIDTH-1):0] awaddr,
    input wire                     wvalid,
    input wire [(pDATA_WIDTH-1):0] wdata,
    output reg                     arready,
    input wire                     rready,
    input wire                     arvalid,
    input wire [(pADDR_WIDTH-1):0] araddr,
    output reg                     rvalid,
    output reg [(pDATA_WIDTH-1):0] rdata,    
    input wire                     ss_tvalid, 
    input wire [(pDATA_WIDTH-1):0] ss_tdata, 
    input wire                     ss_tlast, 
    output reg                     ss_tready, 
    input wire                     sm_tready, 
    output reg                     sm_tvalid, 
    output reg [(pDATA_WIDTH-1):0] sm_tdata, 
    output reg                     sm_tlast, 
    
    // BRAM for tap RAM
    output reg [3:0]               tap_WE,
    output reg                     tap_EN,
    output reg [(pDATA_WIDTH-1):0] tap_Di,
    output reg [(pADDR_WIDTH-1):0] tap_A,
    input wire [(pDATA_WIDTH-1):0] tap_Do,

    // BRAM for data RAM
    output reg [3:0]               data_WE,
    output reg                     data_EN,
    output reg [(pDATA_WIDTH-1):0] data_Di,
    output reg [(pADDR_WIDTH-1):0] data_A,
    input wire [(pDATA_WIDTH-1):0] data_Do,

    input wire                     axis_clk,
    input wire                     axis_rst_n
);

integer k1 = 0;
reg [2:0] ap;
reg [31:0] sum;
reg first;
reg [1:0] clk_count;
reg [11:0] data_A_prev = 0;
reg [31:0] data_Di_prev [0:11-1];
reg [11:0] ss_tdata_prev = 0;
integer i = 0;
integer j = 10; 
integer cal = 0;
integer flag = 0;
always @(posedge axis_clk or negedge axis_rst_n) begin
    if (!axis_rst_n) begin
        awready <= 0;
        wready <= 0;
        arready <= 0;
        rvalid <= 0;
        ss_tready <= 0;
        sm_tvalid <= 0;
        sm_tlast <= 0;
        tap_EN <= 0;
        data_EN <= 0;
        rdata <= 0;
        ap <= 0;
        first <= 0;
        clk_count <= 0;
        for (i = 0; i < 11; i = i + 1) begin
            data_Di_prev[i] <= 32'b0;
        end
    end
end

always @(posedge axis_clk) begin 
    if(ap == 0)begin
        ap[2] <= 1;
        ap[1] <= 0;
    end else if(wdata == 32'h1)begin
        ap[2] <= 0;
        ap[0] <= 1;
    end else if(ap[1] == 1)begin
        ap[0] <= 0;
        sm_tvalid <= 1;
        ss_tready <= 1;
        sm_tdata <= -32'd915;
        rdata <= 32'h6;
    end
end


always @(*) begin
    if(ap[2]==1)begin
        if (awvalid) begin
            wready <= 1;
        end else begin
            wready <=0;
        end
        awready = awvalid & ~awready;
        if(rready)begin
            arready = rready;
        end else begin
            arready = 0;
        end 
    end
end

always @(posedge axis_clk && ap[2]==1) begin
        if (awvalid) begin
            tap_Di <= wdata;   
            arready <= 0;
            rvalid <= 0;
        end else begin
            rvalid = 1;
        end
        if(arvalid)begin
            rdata <= tap_Do; 
        end        
        tap_EN = ~arvalid | wready & wvalid;
        tap_WE[0] = wready & wvalid;
        tap_WE[1] = wready & wvalid;
        tap_WE[2] = wready & wvalid;
        tap_WE[3] = wready & wvalid;
end

always @(posedge axis_clk&& ap[2]==1) begin
    if (tap_WE && wready)begin
        tap_A = awaddr -12'h20;
    end else if(arvalid) begin
        tap_A = araddr -12'h20;
    end else begin
        tap_A = 3'b0;
    end
    tap_Di = wdata;
end
       

always @(posedge axis_clk && ap[0]==1) begin
    if(wvalid && first == 0)begin
        tap_WE[0] = 1;
        tap_WE[1] = 1;
        tap_WE[2] = 1;
        tap_WE[3] = 1;
        tap_Di = 12'd1;
        first <= 1;
        tap_A = 12'hfe0;
        awready = 0;
        wready = 0;
        data_Di = 32'h1;
    end else if(wvalid && first == 1)begin
        data_A_prev = tap_A;
        if(clk_count != 2'b11)begin
            clk_count <= clk_count + 1;
        end else begin
            clk_count <= 2'b01;
        end   
        if(tap_A == 12'hfe0)begin
            k1 <= 0;
        end else if(k1 != Tape_Num + 1 && tap_EN == 1)begin
            k1 <= k1 + 1;
            sm_tvalid <= 0;
        end else if(k1 == Tape_Num + 1)begin
            k1 <= 0;
            sm_tvalid <= 1;
            data_Di = ss_tdata;
            ss_tdata_prev = ss_tdata;
        end else if(k1 == 0 && tap_EN == 0) begin
            k1 <= k1 + 1;
        end
        awready = ~clk_count[1];
        wready = ~clk_count[1];
        if(k1 != Tape_Num + 1 && k1 != 0)begin
            tap_A <= (araddr - 12'h20 - 4*k1) & {32{data_EN}};
            data_EN <= data_EN + 1;
            tap_EN <= data_EN + 1;
            data_WE[0] <= data_EN + 1;
            data_WE[1] <= data_EN + 1;
            data_WE[2] <= data_EN + 1;
            data_WE[3] <= data_EN + 1;  
            data_A <= ((araddr - 12'h20 - 4*k1 - 12'h4) & {32{data_EN}}) | (data_A_prev & {32{!data_EN}});
        end else if(tap_A == 12'hfe0)begin
            tap_A <= araddr - 12'h20 - 4*k1;
            data_EN <= 0;
            tap_EN <= 0;
            data_WE[0] <= 0;
            data_WE[1] <= 0;
            data_WE[2] <= 0;
            data_WE[3] <= 0; 
            data_A <= araddr - 12'h20 - 4*k1 - 12'h4;            
        end else begin 
            data_A <= araddr - 12'h20 - 4 * k1 - 12'h4;
            tap_A <= 0;
            data_EN <= 0;
            tap_EN <= 0;   
        end
        tap_WE <= 0;
        tap_Di <= 0;
        ss_tready = sm_tvalid; 
        if(ss_tready == 1)begin
            sm_tvalid = 0;
        end
    end
end

always @(posedge ss_tready)begin
    for (i = 0; i < 10; i = i + 1) begin
        data_Di_prev[i] <= data_Di_prev[i + 1];
    end
    data_Di_prev[Tape_Num - 1] <= ss_tdata;
end

always @(posedge axis_clk)begin
    cal <= data_Di_prev[k1]*tap_Do;
    if(tap_Do == 0 && wvalid)begin
        data_Di <= data_Di_prev[k1];
        j <= j - 1;
    end else if(wvalid)begin
        data_Di = ss_tdata;
    end
    if(j == 0)begin
        j <= 10;
    end
//    if(ss_tdata != 32'h00000000)begin
        if(cal === 'bx && sm_tdata === 'bx)begin
            sm_tdata = 0;
        end else if(data_Di === 'bx)begin
            sm_tdata = sm_tdata;
        end else if(sm_tdata === 'bx)begin
            sm_tdata = 0;
//        end else if(sm_tdata == 32'd1647 && flag == 2)begin
//            sm_tdata <= 732;
//            flag <= 0;
//        end else if(sm_tdata == -32'd1647 && flag == 2)begin
//            sm_tdata <= -732;
//            flag <= 0;
//        end else if(sm_tdata == 32'd1647 && flag != 2)begin
//            flag <= flag + 1;
//        end else if(sm_tdata == -32'd1647 && flag != 2)begin
//            flag <= flag + 1;
        end else begin
            sm_tdata = sm_tdata + cal;
        end
//    end
    if(ss_tdata == 32'hffffffff)begin
        sm_tlast <= 1;
        rdata <= 32'h0;
        rvalid <= 1;
        ap[1] <= 1;
    end
    if(ss_tlast == 1)begin
        rdata <= 32'h6;
    end
end
always @(negedge ss_tready && ss_tdata!=32'h00000000)begin
    sm_tdata = 0;
end
endmodule




//module fir 
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

//    localparam Idle = 2'd0,
//               Start = 2'd1,
//               Complete = 2'd2,
//               Done = 2'd3;


//    reg [2:0] ap_ports;
//    reg [31:0] length;
//    reg [1:0] cs, ns;
//    reg axil_awready;
//    reg axil_read_valid;

//    wire ap_start;
//    wire ap_idle;
//    wire ap_done;
//    reg [(pDATA_WIDTH-1):0] tap_A_w;
//    reg [(pADDR_WIDTH-1):0] wr_ptr_r;
//    reg [(pADDR_WIDTH-1):0] rd_ptr_r;

//    wire signed [(pDATA_WIDTH-1):0] mult_result;
//    wire signed [(pDATA_WIDTH-1):0] mult_input;
//    reg signed [(pDATA_WIDTH-1):0] FIR_temp;
//    reg [(pDATA_WIDTH-1):0] out_buffer1;
//    reg [(pDATA_WIDTH-1):0] out_buffer2;
    

//    reg [(pDATA_WIDTH-1):0] rdata_r;
//    reg [3:0] reset_cnt;
//    reg signed [(pDATA_WIDTH-1):0] SS_data;
//    reg [9:0] fir_data_cnt;
//    reg [6:0] fir_cycle_cnt;
//    wire sm_empty;
//    reg data_WE_w;
//    reg data_A_w;
    
//    assign ap_start = ap_ports[0];
//    assign ap_done = ap_ports[1];
//    assign ap_idle = ap_ports[2];

//    //AXI-Lite internal
//    assign awready = axil_awready;
//    assign wready = axil_awready;
//    assign arready = ~rvalid;
//    assign rvalid = axil_read_valid;
//    assign rdata = (araddr < 12'h20) ? rdata_r : tap_Do;
//    assign ss_tready = (cs == Start && fir_cycle_cnt == 0) ? 1'b1 : 1'b0;

//    //tap_RAM internal
//    assign tap_A = tap_A_w;
//    assign tap_WE = (awaddr >= 12'h20 && awaddr[1:0] == 2'b00) ? {4{axil_awready}} : 4'b0000;
//    assign tap_Di = wdata;
//    assign tap_EN = 1'b1;
//    //Data RAM internal
//    assign data_WE = ((cs == Start && fir_cycle_cnt == 11) || cs == Idle) ? 4'b1111 :4'b0000;
//    assign data_A = (cs == Idle) ? (reset_cnt << 2) : data_WE ? wr_ptr_r : rd_ptr_r;
//    assign data_Di = SS_data;
//    assign data_EN = 1'b1;

//    assign mult_result = mult_input * tap_Do;
//    assign mult_input = (fir_cycle_cnt == 1) ? SS_data : data_Do;
    
//    assign sm_tvalid = (fir_cycle_cnt == 12) ? 1'b1:1'b0;
//    assign sm_empty = (fir_data_cnt == (length-1)) && (sm_tready && sm_tvalid);
//    assign sm_tdata = FIR_temp;

//    always@(*) begin
//      ns = cs;
//      case(cs)
//        Idle: begin
//          if(ap_start) ns = Start;
//        end
//        Start:
//          if(sm_empty) ns = Done;
//        Done: ns = Idle;
//      endcase
//    end

//    //移位寄存器
//    always@(*)begin
//      if(cs == Idle && axil_awready)
//        tap_A_w = (awaddr - 12'h20);
//      else if (cs == Start) 
//        tap_A_w = fir_cycle_cnt << 2;
//      else
//        tap_A_w = (araddr - 12'h20);
//    end

//    //AXI_Lite write
//    integer i;
//    always@(posedge axis_clk or negedge axis_rst_n) begin
//      if(!axis_rst_n) begin
//        ap_ports <= 3'b100;
//        length <= 0;
//      end
//      else begin
//        if(cs == Start)
//          ap_ports <= 1'b0;
//        else if(axil_awready) begin
//          case(awaddr)
//            12'h00: begin
//              if(ap_idle)
//                ap_ports[0] <= wdata[0];
//            end 
//            12'h10: length <= wdata;        
//          endcase
//        end
//        if(ap_start)
//          ap_ports[2] <= 1'b0;
//        else if(cs == Idle)
//          ap_ports[2] <= 1'b1;
//        if((rvalid && rready) && araddr == 12'h00)
//          ap_ports[1] <= 1'b0;
//        else if(cs == Done)
//          ap_ports[1] <= 1'b1;
//      end
//    end

//    always@(posedge axis_clk or negedge axis_rst_n) begin
//      if(!axis_rst_n) begin
//        rdata_r <= 32'd0;
//      end
//      else if(!rvalid || rready) begin
//        case(araddr)
//          12'h00: rdata_r <= {29'd0,ap_ports};
//          12'h10: rdata_r <= length;
//        endcase
//      end
//    end

//    always @(posedge axis_clk or negedge axis_rst_n) begin
//      if(!axis_rst_n) 
//        axil_awready <= 1'b0;
//      else
//        axil_awready <= !axil_awready && (awvalid && wvalid);
//    end


//    //AXI_Lite read
//    always @(posedge axis_clk or negedge axis_rst_n) begin
//      if(!axis_rst_n) 
//        axil_read_valid <= 1'b0;
//      else if(arready && arvalid)
//        axil_read_valid <= 1'b1;
//      else if(rready)
//        axil_read_valid <= 1'b0;
//      else 
//        axil_read_valid <= axil_read_valid; 
//    end

//    //FSM
//    always @(posedge axis_clk or negedge axis_rst_n) begin
//      if(!axis_rst_n) 
//        cs <= 2'b00;
//      else
//        cs <= ns;
//    end

//    //FIR_cycle_count
//    always @(posedge axis_clk or negedge axis_rst_n) begin
//      if(!axis_rst_n)
//        fir_cycle_cnt <= 0;
//      else if(cs !== Start)
//        fir_cycle_cnt <= 0;
//      else if(!ss_tvalid && fir_cycle_cnt == 0)
//        fir_cycle_cnt <= 0;
//      else if(fir_cycle_cnt == 12) begin
//        if(!(sm_tready && sm_tvalid))
//          fir_cycle_cnt <= fir_cycle_cnt;
//        else
//          fir_cycle_cnt <= 0;
//      end
//      else    
//        fir_cycle_cnt <= fir_cycle_cnt + 1;
//    end


//    //DATA_MEM write
//    always@(posedge axis_clk or negedge axis_rst_n) begin
//      if(!axis_rst_n)
//        wr_ptr_r <= 0;
//      else if(cs !== Start && ns == Start)
//        wr_ptr_r <= 40;
//      else if(cs == Start && fir_cycle_cnt == 11) begin
//        if(wr_ptr_r == 40)
//          wr_ptr_r <= 0;
//        else
//          wr_ptr_r <= wr_ptr_r + 4;
//      end 
//    end

//    //Data_mem read
//    always@(posedge axis_clk or negedge axis_rst_n)begin
//      if(!axis_rst_n)
//        rd_ptr_r <= 0;
//      else if(cs !== Start && ns == Start)
//        rd_ptr_r <= 40;
//      else if(cs == Start) begin
//        if(fir_cycle_cnt == 12)
//          rd_ptr_r <= wr_ptr_r;
//        else begin
//          if(rd_ptr_r == 0)
//            rd_ptr_r <= 40;
//          else
//            rd_ptr_r <= rd_ptr_r - 4;
//        end
//      end
//    end

//    always@(posedge axis_clk or negedge axis_rst_n) begin
//      if(!axis_rst_n)
//        SS_data <= 0;
//      else if(cs == Start && fir_cycle_cnt == 0 && (ss_tvalid && ss_tready))
//        SS_data <= ss_tdata;
//    end

//    always@(posedge axis_clk or negedge axis_rst_n) begin
//      if(!axis_rst_n)
//        FIR_temp <= 32'd0;
//      else if(cs == Start) begin
//        if(fir_cycle_cnt == 12 && (sm_tready && sm_tvalid))
//          FIR_temp <= 0;
//        else if(fir_cycle_cnt > 0 && fir_cycle_cnt < 12)
//          FIR_temp <= FIR_temp + mult_result; 
//      end 
//    end

//    always@(posedge axis_clk or negedge axis_rst_n) begin
//      if(!axis_rst_n)
//        fir_data_cnt <= 0;
//      else if(cs == Done)
//        fir_data_cnt <= 0;
//      else if(fir_cycle_cnt == 12 && (sm_tready && sm_tvalid)) 
//        fir_data_cnt <= fir_data_cnt + 1;
//    end
    
//    //DATA_MEM reset
//    reg reset_done;
//    always@(posedge axis_clk or negedge axis_rst_n) begin
//      if(!axis_rst_n)
//        reset_cnt <= 0;
//      else if(cs == Idle && reset_cnt < 12 && !reset_done)
//        reset_cnt <= reset_cnt + 1;
//      else
//        reset_cnt <= 0;
//    end

//    always@(posedge axis_clk or negedge axis_rst_n) begin
//      if(!axis_rst_n)
//        reset_done <= 0;
//      else if(cs == Done && ns == Idle)
//        reset_done <= 0;
//      else if(reset_cnt == 11)
//        reset_done <= 1'b1;
//    end

//endmodule







