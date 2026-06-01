module mcu_soc import mcu_soc_pkg::*; #(
  parameter  string INIT_FILE="",
  parameter  int    INIT_FILE_BIN=0,
  parameter  int    MEM_SIZE_WORDS=4096
  ) (
  input  logic clk,
  input  logic rstn,

  input  logic jtag_tck_i,
  input  logic jtag_tdi_i,
  output logic jtag_tdo_o,
  input  logic jtag_tms_i,
  input  logic jtag_trst_ni,

  output logic tx,
  input  logic rx
);
  localparam int AddrWidth = 32;
  localparam int DataWidth = 32;
  localparam int NBytes = (DataWidth / 8);

  localparam dm::hartinfo_t HartInfo = '{
    zero0: '0,
    zero1: '0,
    nscratch: 2,
    dataaccess: 1'b1,
    datasize: dm::DataCount,
    dataaddr: dm::DataAddr
  };
  dm::hartinfo_t hartinfo = HartInfo;

  logic [MgrObiCfg.IdWidth-1:0] obi_instr_aid;
  logic                         obi_instr_areq;
  logic                         obi_instr_agnt;
  logic [AddrWidth-1:0]         obi_instr_aaddr;
  logic                         obi_instr_awe;
  logic [NBytes-1:0]            obi_instr_abe;
  logic [DataWidth-1:0]         obi_instr_awdata;

  logic [MgrObiCfg.IdWidth-1:0] obi_instr_rid;
  logic                         obi_instr_rvalid;
  logic                         obi_instr_rready;
  logic [DataWidth-1:0]         obi_instr_rdata;
  logic                         obi_instr_rerr;

  logic [MgrObiCfg.IdWidth-1:0] obi_data_aid;
  logic                         obi_data_areq;
  logic                         obi_data_agnt;
  logic [AddrWidth-1:0]         obi_data_aaddr;
  logic                         obi_data_awe;
  logic [NBytes-1:0]            obi_data_abe;
  logic [DataWidth-1:0]         obi_data_awdata;

  logic [MgrObiCfg.IdWidth-1:0] obi_data_rid;
  logic                         obi_data_rvalid;
  logic                         obi_data_rready;
  logic [DataWidth-1:0]         obi_data_rdata;
  logic                         obi_data_rerr;

  logic                 debug_req;
  logic                 dmi_rst_n;
  logic                 dmi_req_valid;
  logic                 dmi_req_ready;
  dm::dmi_req_t         dmi_req;
  logic                 dmi_resp_valid;
  logic                 dmi_resp_ready;
  dm::dmi_resp_t        dmi_resp;

  mgr_obi_req_t         core_instr_obi_req;
  mgr_obi_rsp_t         core_instr_obi_rsp;
  mgr_obi_req_t         core_data_obi_req;
  mgr_obi_rsp_t         core_data_obi_rsp;
  mgr_obi_req_t         dbg_obi_man_req;
  mgr_obi_rsp_t         dbg_obi_man_rsp;
  
  sbr_obi_req_t         xbar_obi_sub_req;
  sbr_obi_rsp_t         xbar_obi_sub_rsp;
  sbr_obi_req_t         xbar_mem_obi_req;
  sbr_obi_rsp_t         xbar_mem_obi_rsp;
  sbr_obi_req_t         xbar_uart_obi_req;
  sbr_obi_rsp_t         xbar_uart_obi_rsp;
  

  rvj1_obi #(
    .BootAddr (McuBootAddr),
    .DmRomAddr(McuDmRomAddr),
    .MVendorId(McuMVendorId),
    .MArchId  (McuMArchId),
    .MImpId   (McuMImpId),
    .MHartId  (McuMHartId)
  ) rvj1_inst (
    .clk_i          (clk),
    .rstn_i         (rstn),

    .instr_aid_o    (obi_instr_aid),
    .instr_areq_o   (obi_instr_areq),
    .instr_agnt_i   (obi_instr_agnt),
    .instr_aaddr_o  (obi_instr_aaddr),
    .instr_awe_o    (obi_instr_awe),
    .instr_abe_o    (obi_instr_abe),
    .instr_awdata_o (obi_instr_awdata),

    .instr_rid_i    (obi_instr_rid),
    .instr_rvalid_i (obi_instr_rvalid),
    .instr_rready_o (obi_instr_rready),
    .instr_rdata_i  (obi_instr_rdata),
    .instr_rerr_i   (obi_instr_rerr),
    
    .data_aid_o     (obi_data_aid),
    .data_areq_o    (obi_data_areq),
    .data_agnt_i    (obi_data_agnt),
    .data_aaddr_o   (obi_data_aaddr),
    .data_awe_o     (obi_data_awe),
    .data_abe_o     (obi_data_abe),
    .data_awdata_o  (obi_data_awdata),

    .data_rid_i     (obi_data_rid),
    .data_rvalid_i  (obi_data_rvalid),
    .data_rready_o  (obi_data_rready),
    .data_rdata_i   (obi_data_rdata),
    .data_rerr_i    (obi_data_rerr),

    .irq_external_i (1'b0),
    .irq_timer_i    (1'b0),
    .irq_sw_i       (1'b0),
    .irq_lcofi_i    (1'b0),
    .irq_platform_i ('0),
    .irq_nmi_i      (1'b0),

    .debug_req_i    (debug_req)
  );

  assign core_instr_obi_req.req     = obi_instr_areq;
  assign core_instr_obi_req.rready  = obi_instr_rready;
  assign core_instr_obi_req.a.addr  = obi_instr_aaddr;
  assign core_instr_obi_req.a.we    = obi_instr_awe;
  assign core_instr_obi_req.a.be    = obi_instr_abe;
  assign core_instr_obi_req.a.wdata = obi_instr_awdata;
  assign core_instr_obi_req.a.aid   = obi_instr_aid;

  assign obi_instr_agnt   = core_instr_obi_rsp.gnt;
  assign obi_instr_rvalid = core_instr_obi_rsp.rvalid;
  assign obi_instr_rid    = core_instr_obi_rsp.r.rid;
  assign obi_instr_rdata  = core_instr_obi_rsp.r.rdata;
  assign obi_instr_rerr   = core_instr_obi_rsp.r.err;

  assign core_data_obi_req.req     = obi_data_areq;
  assign core_data_obi_req.rready  = obi_data_rready;
  assign core_data_obi_req.a.addr  = obi_data_aaddr;
  assign core_data_obi_req.a.we    = obi_data_awe;
  assign core_data_obi_req.a.be    = obi_data_abe;
  assign core_data_obi_req.a.wdata = obi_data_awdata;
  assign core_data_obi_req.a.aid   = obi_data_aid;

  assign obi_data_agnt   = core_data_obi_rsp.gnt;
  assign obi_data_rvalid = core_data_obi_rsp.rvalid;
  assign obi_data_rid    = core_data_obi_rsp.r.rid;
  assign obi_data_rdata  = core_data_obi_rsp.r.rdata;
  assign obi_data_rerr   = core_data_obi_rsp.r.err;

  obi_xbar #(
    .SbrPortObiCfg      (MgrObiCfg),
    .MgrPortObiCfg      (SbrObiCfg),
    .sbr_port_obi_req_t (mgr_obi_req_t),
    .sbr_port_a_chan_t  (mgr_obi_a_chan_t),
    .sbr_port_obi_rsp_t (mgr_obi_rsp_t),
    .sbr_port_r_chan_t  (mgr_obi_r_chan_t),
    .mgr_port_obi_req_t (sbr_obi_req_t),
    .mgr_port_obi_rsp_t (sbr_obi_rsp_t),
    .NumSbrPorts        (NumManagers),
    .NumMgrPorts        (NumSubordinates),
    .NumMaxTrans        (4),
    .NumAddrRules       (NumSubordinates),
    .addr_map_rule_t    (addr_map_rule_t),
    .UseIdForRouting    (1'b1),
    .Connectivity       ('1)
  ) xbar (
    .clk_i            (clk),
    .rst_ni           (rstn),

    .testmode_i       (1'b0),

    .sbr_ports_req_i  ({dbg_obi_man_req, core_instr_obi_req, core_data_obi_req}),
    .sbr_ports_rsp_o  ({dbg_obi_man_rsp, core_instr_obi_rsp, core_data_obi_rsp}),

    .mgr_ports_req_o  ({xbar_obi_sub_req, xbar_uart_obi_req, xbar_mem_obi_req}),
    .mgr_ports_rsp_i  ({xbar_obi_sub_rsp, xbar_uart_obi_rsp, xbar_mem_obi_rsp}),

    .addr_map_i       ( Rvj1AddrMap ),
    .en_default_idx_i ('1),
    .default_idx_i    ('0)
  );

  obi_ram #(
    .INIT_FILE     (INIT_FILE),
    .INIT_FILE_BIN (INIT_FILE_BIN),
    .MEM_SIZE_WORDS(MEM_SIZE_WORDS),
    .IDLEN         (SbrObiCfg.IdWidth)
  ) mem (
    .clk_i  (clk),
    .rstn_i (rstn),

    .obi_aid_i    (xbar_mem_obi_req.a.aid),
    .obi_areq_i   (xbar_mem_obi_req.req),
    .obi_agnt_o   (xbar_mem_obi_rsp.gnt),
    .obi_aaddr_i  (xbar_mem_obi_req.a.addr),
    .obi_awe_i    (xbar_mem_obi_req.a.we),
    .obi_awdata_i (xbar_mem_obi_req.a.wdata),
    .obi_abe_i    (xbar_mem_obi_req.a.be),

    .obi_rid_o    (xbar_mem_obi_rsp.r.rid),
    .obi_rvalid_o (xbar_mem_obi_rsp.rvalid),
    .obi_rready_i (xbar_mem_obi_req.rready),
    .obi_rdata_o  (xbar_mem_obi_rsp.r.rdata)
  );

  dmi_jtag #(
    .IdcodeValue(Rvj1JtagIdCode)
  ) dmi_jtag_inst (
    .clk_i  (clk),
    .rst_ni (rstn),
    .testmode_i (1'b0),

    .dmi_rst_no      (dmi_rst_n),
    .dmi_req_o       (dmi_req),
    .dmi_req_valid_o (dmi_req_valid),
    .dmi_req_ready_i (dmi_req_ready),

    .dmi_resp_i      (dmi_resp),
    .dmi_resp_ready_o(dmi_resp_ready),
    .dmi_resp_valid_i(dmi_resp_valid),

    .tck_i           (jtag_tck_i),
    .td_i            (jtag_tdi_i),
    .td_o            (jtag_tdo_o),
    .tms_i           (jtag_tms_i),
    .trst_ni         (jtag_trst_ni),
    .tdo_oe_o        ()
  );

  dm_obi_top #(
    .NrHarts  (1),
    .BusWidth (DataWidth),
    .IdWidth  (SbrObiCfg.IdWidth)
  ) dm_obi_top_inst (
    .clk_i       (clk),
    .rst_ni      (rstn),
    .testmode_i  (1'b0),
    .ndmreset_o  (),
    .dmactive_o  (),

    .debug_req_o   (debug_req),
    .unavailable_i (1'b0),
    .hartinfo_i    (hartinfo),

    .slave_req_i       (xbar_obi_sub_req.req),
    .slave_we_i        (xbar_obi_sub_req.a.we),
    .slave_addr_i      (xbar_obi_sub_req.a.addr),
    .slave_be_i        (xbar_obi_sub_req.a.be),
    .slave_wdata_i     (xbar_obi_sub_req.a.wdata),
    .slave_aid_i       (xbar_obi_sub_req.a.aid),
    .slave_gnt_o       (xbar_obi_sub_rsp.gnt),
    .slave_rvalid_o    (xbar_obi_sub_rsp.rvalid),
    .slave_rdata_o     (xbar_obi_sub_rsp.r.rdata),
    .slave_rid_o       (xbar_obi_sub_rsp.r.rid),

    .master_req_o      (dbg_obi_man_req.req),
    .master_addr_o     (dbg_obi_man_req.a.addr),
    .master_we_o       (dbg_obi_man_req.a.we),
    .master_be_o       (dbg_obi_man_req.a.be),
    .master_wdata_o    (dbg_obi_man_req.a.wdata),
    .master_gnt_i      (dbg_obi_man_rsp.gnt),
    .master_rvalid_i   (dbg_obi_man_rsp.rvalid),
    .master_rdata_i    (dbg_obi_man_rsp.r.rdata),
    .master_err_i      (dbg_obi_man_rsp.r.err),
    .master_other_err_i(1'b0),

    .dmi_rst_ni        (dmi_rst_n),
    .dmi_req_valid_i   (dmi_req_valid),
    .dmi_req_ready_o   (dmi_req_ready),
    .dmi_req_i         (dmi_req),

    .dmi_resp_valid_o  (dmi_resp_valid),
    .dmi_resp_ready_i  (dmi_resp_ready),
    .dmi_resp_o        (dmi_resp)
  );

  obi_uart #(
    .ObiCfg   (SbrObiCfg),
    .obi_req_t(sbr_obi_req_t),
    .obi_rsp_t(sbr_obi_rsp_t)
  ) uart (
    .clk_i  (clk),
    .rst_ni (rstn),

    .obi_req_i (xbar_uart_obi_req),
    .obi_rsp_o (xbar_uart_obi_rsp),

    .rxd_i  (rx),
    .txd_o  (tx),

    .irq_o  (),
    .irq_no (),

    .cts_ni ('1),
    .dsr_ni ('1),
    .ri_ni  ('1),
    .cd_ni  ('1),
    .rts_no (),
    .dtr_no (),
    .out1_no(),
    .out2_no()
  );

endmodule
