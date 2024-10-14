// *************************************************************************
//
// Copyright 2020 Xilinx, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// *************************************************************************
wire    [NUM_CMAC_PORT*2-1:0] axil_p2p_awvalid;
wire [32*NUM_CMAC_PORT*2-1:0] axil_p2p_awaddr;
wire    [NUM_CMAC_PORT*2-1:0] axil_p2p_awready;
wire    [NUM_CMAC_PORT*2-1:0] axil_p2p_wvalid;
wire [32*NUM_CMAC_PORT*2-1:0] axil_p2p_wdata;
wire    [NUM_CMAC_PORT*2-1:0] axil_p2p_wready;
wire    [NUM_CMAC_PORT*2-1:0] axil_p2p_bvalid;
wire  [2*NUM_CMAC_PORT*2-1:0] axil_p2p_bresp;
wire    [NUM_CMAC_PORT*2-1:0] axil_p2p_bready;
wire    [NUM_CMAC_PORT*2-1:0] axil_p2p_arvalid;
wire [32*NUM_CMAC_PORT*2-1:0] axil_p2p_araddr;
wire    [NUM_CMAC_PORT*2-1:0] axil_p2p_arready;
wire    [NUM_CMAC_PORT*2-1:0] axil_p2p_rvalid;
wire [32*NUM_CMAC_PORT*2-1:0] axil_p2p_rdata;
wire  [2*NUM_CMAC_PORT*2-1:0] axil_p2p_rresp;
wire    [NUM_CMAC_PORT*2-1:0] axil_p2p_rready;

wire        axil_girq_awvalid;
wire [31:0] axil_girq_awaddr;
wire        axil_girq_awready;
wire        axil_girq_wvalid;
wire [31:0] axil_girq_wdata;
wire        axil_girq_wready;
wire        axil_girq_bvalid;
wire  [1:0] axil_girq_bresp;
wire        axil_girq_bready;
wire        axil_girq_arvalid;
wire [31:0] axil_girq_araddr;
wire        axil_girq_arready;
wire        axil_girq_rvalid;
wire [31:0] axil_girq_rdata;
wire  [1:0] axil_girq_rresp;
wire        axil_girq_rready;

box_250mhz_address_map #(
  .NUM_INTF          (NUM_PHYS_FUNC)
) address_map_inst (
  .s_axil_awvalid       (s_axil_awvalid),
  .s_axil_awaddr        (s_axil_awaddr),
  .s_axil_awready       (s_axil_awready),
  .s_axil_wvalid        (s_axil_wvalid),
  .s_axil_wdata         (s_axil_wdata),
  .s_axil_wready        (s_axil_wready),
  .s_axil_bvalid        (s_axil_bvalid),
  .s_axil_bresp         (s_axil_bresp),
  .s_axil_bready        (s_axil_bready),
  .s_axil_arvalid       (s_axil_arvalid),
  .s_axil_araddr        (s_axil_araddr),
  .s_axil_arready       (s_axil_arready),
  .s_axil_rvalid        (s_axil_rvalid),
  .s_axil_rdata         (s_axil_rdata),
  .s_axil_rresp         (s_axil_rresp),
  .s_axil_rready        (s_axil_rready),

  .m_axil_p2p_awvalid   (axil_p2p_awvalid),
  .m_axil_p2p_awaddr    (axil_p2p_awaddr),
  .m_axil_p2p_awready   (axil_p2p_awready),
  .m_axil_p2p_wvalid    (axil_p2p_wvalid),
  .m_axil_p2p_wdata     (axil_p2p_wdata),
  .m_axil_p2p_wready    (axil_p2p_wready),
  .m_axil_p2p_bvalid    (axil_p2p_bvalid),
  .m_axil_p2p_bresp     (axil_p2p_bresp),
  .m_axil_p2p_bready    (axil_p2p_bready),
  .m_axil_p2p_arvalid   (axil_p2p_arvalid),
  .m_axil_p2p_araddr    (axil_p2p_araddr),
  .m_axil_p2p_arready   (axil_p2p_arready),
  .m_axil_p2p_rvalid    (axil_p2p_rvalid),
  .m_axil_p2p_rdata     (axil_p2p_rdata),
  .m_axil_p2p_rresp     (axil_p2p_rresp),
  .m_axil_p2p_rready    (axil_p2p_rready),

  .m_axil_girq_awvalid (axil_girq_awvalid),
  .m_axil_girq_awaddr  (axil_girq_awaddr),
  .m_axil_girq_awready (axil_girq_awready),
  .m_axil_girq_wvalid  (axil_girq_wvalid),
  .m_axil_girq_wdata   (axil_girq_wdata),
  .m_axil_girq_wready  (axil_girq_wready),
  .m_axil_girq_bvalid  (axil_girq_bvalid),
  .m_axil_girq_bresp   (axil_girq_bresp),
  .m_axil_girq_bready  (axil_girq_bready),
  .m_axil_girq_arvalid (axil_girq_arvalid),
  .m_axil_girq_araddr  (axil_girq_araddr),
  .m_axil_girq_arready (axil_girq_arready),
  .m_axil_girq_rvalid  (axil_girq_rvalid),
  .m_axil_girq_rdata   (axil_girq_rdata),
  .m_axil_girq_rresp   (axil_girq_rresp),
  .m_axil_girq_rready  (axil_girq_rready),

  .aclk                 (axil_aclk),
  .aresetn              (internal_box_rstn)
);

