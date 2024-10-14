module girq_axil_wrapper (
  output wire                    usr_irq_in_vld,
  output wire             [11:0] usr_irq_in_vec,
  output wire              [7:0] usr_irq_in_fnc,
  input wire                     usr_irq_out_ack,
  input wire                     usr_irq_out_fail,

  input wire                     s_axil_girq_awvalid,
  input wire              [31:0] s_axil_girq_awaddr,
  output wire                    s_axil_girq_awready,
  input wire                     s_axil_girq_wvalid,
  input wire              [31:0] s_axil_girq_wdata,
  output wire                    s_axil_girq_wready,
  output wire                    s_axil_girq_bvalid,
  output wire             [1:0]  s_axil_girq_bresp,
  input wire                     s_axil_girq_bready,
  input wire                     s_axil_girq_arvalid,
  input wire              [31:0] s_axil_girq_araddr,
  output wire                    s_axil_girq_arready,
  output wire                    s_axil_girq_rvalid,
  output wire             [31:0] s_axil_girq_rdata,
  output wire              [1:0] s_axil_girq_rresp,
  input wire                     s_axil_girq_rready,

  input wire                     axil_aclk,
  input wire                     axil_aresetn
);

`define GIRQ_CTRL_ADDR           32'h00
`define GIRQ_TRIG_ADDR           32'h04
`define GIRQ_STAT_ADDR           32'h08
`define GIRQ_CMPT_ADDR           32'h0c
`define GIRQ_TS0_ADDR            32'h10
`define GIRQ_TS1_ADDR            32'h14
`define GIRQ_TS2_ADDR            32'h18
`define GIRQ_COUNTER_ADDR        32'h1c

reg                       [31:0] reg_girq_ctrl;
reg                       [31:0] reg_girq_trig;
reg                       [31:0] reg_girq_stat;        // driver: girq_axil_wrapper
reg                       [31:0] reg_girq_cmpt;
reg                       [31:0] reg_girq_ts0; 
reg                       [31:0] reg_girq_ts1; 
reg                       [31:0] reg_girq_ts2; 
reg                       [31:0] reg_girq_counter;  

wire                       [2:0] reg_girq_stat_shadow; // driver: gen_irq (multiple drivers error workaround)
reg                              ts1_ready;  
reg                              ts2_ready;      

wire                             reg_en;
wire                             reg_we;
wire                      [31:0] reg_addr;
wire                      [31:0] reg_din;
reg                       [31:0] reg_dout;

axi_lite_register #(
  .CLOCKING_MODE ("common_clock"),
  .ADDR_W        (32),
  .DATA_W        (32)
) girq_axil_reg_inst (
  .s_axil_awvalid               (s_axil_girq_awvalid),
  .s_axil_awaddr                (s_axil_girq_awaddr),
  .s_axil_awready               (s_axil_girq_awready),
  .s_axil_wvalid                (s_axil_girq_wvalid),
  .s_axil_wdata                 (s_axil_girq_wdata),
  .s_axil_wready                (s_axil_girq_wready),
  .s_axil_bvalid                (s_axil_girq_bvalid),
  .s_axil_bresp                 (s_axil_girq_bresp),
  .s_axil_bready                (s_axil_girq_bready),
  .s_axil_arvalid               (s_axil_girq_arvalid),
  .s_axil_araddr                (s_axil_girq_araddr),
  .s_axil_arready               (s_axil_girq_arready),
  .s_axil_rvalid                (s_axil_girq_rvalid),
  .s_axil_rdata                 (s_axil_girq_rdata),
  .s_axil_rresp                 (s_axil_girq_rresp),
  .s_axil_rready                (s_axil_girq_rready),

  .reg_en                       (reg_en),
  .reg_we                       (reg_we),
  .reg_addr                     (reg_addr),
  .reg_din                      (reg_din),
  .reg_dout                     (reg_dout),

  .axil_aclk                    (axil_aclk),
  .axil_aresetn                 (axil_aresetn),
  .reg_clk                      (axil_aclk),
  .reg_rstn                     (axil_aresetn)
);

//Read functionality
always @(posedge axil_aclk) begin
  if (~axil_aresetn) begin
    reg_dout <= 0;
  end else if (reg_en && ~reg_we) begin
    case (reg_addr)
      `GIRQ_CTRL_ADDR: begin
        reg_dout <= reg_girq_ctrl;
      end
      `GIRQ_TRIG_ADDR: begin
        reg_dout <= reg_girq_trig;
      end
      `GIRQ_STAT_ADDR: begin
        reg_dout <= reg_girq_stat;
      end
      `GIRQ_CMPT_ADDR: begin
        reg_dout <= reg_girq_cmpt;
      end
      `GIRQ_TS0_ADDR: begin
        reg_dout <= reg_girq_ts0;
      end
      `GIRQ_TS1_ADDR: begin
        reg_dout <= reg_girq_ts1;
      end
      `GIRQ_TS2_ADDR: begin
        reg_dout <= reg_girq_ts2;
      end
      `GIRQ_COUNTER_ADDR: begin
        reg_dout <= reg_girq_counter;
      end
      default: begin
        reg_dout <= 32'hDEADBEEF;
      end
    endcase
  end
end

// Write functionality
always @(posedge axil_aclk) begin
  if (~axil_aresetn) begin
    reg_girq_ctrl <= 32'h00;
  end else if (reg_en && reg_we) begin
    case  (reg_addr)
      `GIRQ_CTRL_ADDR: begin 
        reg_girq_ctrl <= reg_din;
      end
      default: begin
      end 
    endcase
  end
end

always @(posedge axil_aclk) begin
  if (~axil_aresetn) begin
    reg_girq_trig <= 32'h00;
    reg_girq_stat <= 32'h00;
  end else begin
    if (reg_en && reg_we && reg_addr==`GIRQ_TRIG_ADDR && reg_girq_trig != reg_din) begin
      reg_girq_trig <= reg_din;
    end else if (reg_girq_trig[0] && reg_girq_stat[0]) begin
      reg_girq_trig <= 32'h00;
    end
    reg_girq_stat <= {29'h00, reg_girq_stat_shadow};
  end 
end

gen_irq girq_inst (
  .vec                          (reg_girq_ctrl[11:0]),
  .fnc                          (reg_girq_ctrl[19:12]),

  .trig                         (reg_girq_trig[0]),

  .recv                         (reg_girq_stat_shadow[0]),
  .ack                          (reg_girq_stat_shadow[1]),
  .fail                         (reg_girq_stat_shadow[2]),

  .usr_irq_in_vec               (usr_irq_in_vec),
  .usr_irq_in_fnc               (usr_irq_in_fnc),
  .usr_irq_in_vld               (usr_irq_in_vld),
  .usr_irq_out_ack              (usr_irq_out_ack),
  .usr_irq_out_fail             (usr_irq_out_fail),

  .clk                          (axil_aclk),
  .rstn                         (axil_aresetn)
);

// free-running counter
always @(posedge axil_aclk) begin
    if (~axil_aresetn) begin
        reg_girq_counter <= 32'h00;
    end else begin
        reg_girq_counter <= reg_girq_counter + 1;
    end
end

// reset timestamping at trig
always @(posedge axil_aclk) begin
  if (~axil_aresetn) begin
    reg_girq_cmpt <= 32'h00;
    reg_girq_ts0 <= 32'h00;
  end else begin 
    if (reg_en && reg_we && reg_addr==`GIRQ_CMPT_ADDR) begin
      reg_girq_cmpt <= reg_din;
    end else if (reg_girq_trig[0] && reg_girq_cmpt[0]) begin
      reg_girq_cmpt <= 32'h00;
    end 
    if (reg_girq_trig[0]) begin 
      reg_girq_ts0 <= reg_girq_counter;
    end
  end
end

// capture ts1 and ts2
always @(posedge axil_aclk) begin
    if (~axil_aresetn) begin
        reg_girq_ts1 <= 32'h00;
        reg_girq_ts2 <= 32'h00;
        ts1_ready <= 1'b0;
        ts2_ready <= 1'b0;
    end else begin
        if (reg_girq_trig[0]) begin 
          ts1_ready <= 1'b1;
          // ts2_ready <= 1'b1; // momentarily fix for not receiving ack from qdma
        end else if (ts1_ready && (reg_girq_stat_shadow[1] || reg_girq_stat_shadow[2])) begin
            reg_girq_ts1 <= reg_girq_counter;
            ts1_ready <= 1'b0;
            ts2_ready <= 1'b1;
        end else if (ts2_ready && reg_girq_cmpt[0]) begin
            reg_girq_ts2 <= reg_girq_counter;
            ts2_ready <= 1'b0;
        end
    end
end

// ila
ila_1 ila_inst (
  .probe0                       (usr_irq_in_vld),
  .probe1                       (usr_irq_in_vec),
  .probe2                       (usr_irq_in_fnc),
  .probe3                       (usr_irq_out_ack),
  .probe4                       (usr_irq_out_fail),

  .probe5                       (s_axil_girq_awvalid),
  .probe6                       (s_axil_girq_awaddr),
  .probe7                       (s_axil_girq_awready),
  .probe8                       (s_axil_girq_wvalid),
  .probe9                       (s_axil_girq_wdata),
  .probe10                      (s_axil_girq_wready),
  .probe11                      (s_axil_girq_bvalid),
  .probe12                      (s_axil_girq_bresp),
  .probe13                      (s_axil_girq_bready),
  .probe14                      (s_axil_girq_arvalid),
  .probe15                      (s_axil_girq_araddr),
  .probe16                      (s_axil_girq_arready),
  .probe17                      (s_axil_girq_rvalid),
  .probe18                      (s_axil_girq_rdata),
  .probe19                      (s_axil_girq_rresp),
  .probe20                      (s_axil_girq_rready),

  .probe21                      (axil_aclk),
  .probe22                      (axil_aresetn),

  .probe23                      (reg_girq_ctrl),
  .probe24                      (reg_girq_trig),
  .probe25                      (reg_girq_stat),
  .probe26                      (reg_girq_cmpt),
  .probe27                      (reg_girq_ts0),
  .probe28                      (reg_girq_ts1),
  .probe29                      (reg_girq_ts2),

  .probe30                      (reg_en),
  .probe31                      (reg_we),
  .probe32                      (reg_addr),
  .probe33                      (reg_din),
  .probe34                      (reg_dout),

  .probe35                      (reg_girq_stat_shadow),

  .probe36                      (reg_girq_counter),
  .probe37                      (ts1_ready),
  .probe38                      (ts2_ready),

  .clk                          (axil_aclk)
);

endmodule
