module mcu_soc import mcu_soc_pkg::*; #(
  parameter  string INIT_FILE="",
  parameter  int    INIT_FILE_BIN=0,
  parameter  int    MEM_SIZE_WORDS=2048,
  parameter  int    GPIO_NUM_IN=4,
  parameter  int    GPIO_NUM_OUT=4,
  parameter  int    SPI_NUM_SLAVES=1
  ) (
  input  logic                    clk,
  input  logic                    rstn,

  input  logic                    jtag_tck_i,
  input  logic                    jtag_tdi_i,
  output logic                    jtag_tdo_o,
  input  logic                    jtag_tms_i,
  input  logic                    jtag_trstn_i,

  output logic                    tx,

  input  logic [GPIO_NUM_IN-1:0]  gpio_in_i,
  output logic [GPIO_NUM_OUT-1:0] gpio_out_o,


  output  logic [SPI_NUM_SLAVES-1 : 0]  spi_ss_o,
  output  logic                         spi_sclk_o,
  output  logic                         spi_mosi_o,
  input   logic                         spi_miso_i
);
  localparam int IdWidth = 4;
  localparam int AddrWidth = 32;
  localparam int DataWidth = 32;
  localparam int NBytes = (DataWidth / 8);

  logic [IdWidth-1:0]   obi_instr_aid;
  logic                 obi_instr_areq;
  logic                 obi_instr_agnt;
  logic [AddrWidth-1:0] obi_instr_aaddr;
  logic                 obi_instr_awe;
  logic [NBytes-1:0]    obi_instr_abe;
  logic [DataWidth-1:0] obi_instr_awdata;

  logic [IdWidth-1:0]   obi_instr_rid;
  logic                 obi_instr_rvalid;
  logic                 obi_instr_rready;
  logic [DataWidth-1:0] obi_instr_rdata;
  logic                 obi_instr_rerr;

  logic [IdWidth-1:0]   obi_data_aid;
  logic                 obi_data_areq;
  logic                 obi_data_agnt;
  logic [AddrWidth-1:0] obi_data_aaddr;
  logic                 obi_data_awe;
  logic [NBytes-1:0]    obi_data_abe;
  logic [DataWidth-1:0] obi_data_awdata;

  logic [IdWidth-1:0]   obi_data_rid;
  logic                 obi_data_rvalid;
  logic                 obi_data_rready;
  logic [DataWidth-1:0] obi_data_rdata;
  logic                 obi_data_rerr;

  logic                 debug_req;
  logic                 ndmreset;
  logic                 hwsw_rstn;

  logic                 tim_irq;

  logic                 dmi_rst_n;
  logic                 dmi_req_valid;
  logic                 dmi_req_ready;
  dm::dmi_req_t         dmi_req;
  logic                 dmi_resp_valid;
  logic                 dmi_resp_ready;
  dm::dmi_resp_t        dmi_resp;

  dm::hartinfo_t hartinfo = HartInfo;

  assign hwsw_rstn = rstn; // && ~ndmreset;

  mgr_obi_a_t obi_a_chans_mgr        [NumManagers];
  logic       obi_agnt_signals_mgr   [NumManagers];
  mgr_obi_r_t obi_r_chans_mgr        [NumManagers];
  logic       obi_rready_signals_mgr [NumManagers];

  sub_obi_a_t obi_a_chans_sub        [NumSubordinates];
  logic       obi_agnt_signals_sub   [NumSubordinates];
  sub_obi_r_t obi_r_chans_sub        [NumSubordinates];
  logic       obi_rready_signals_sub [NumSubordinates];

  addr_map_t address_map [xbar_cfg.NoMaps];
  assign address_map[0] = '{idx: 0,   base: 32'h8000_0000, mask: 32'hffff_2000}; 
  assign address_map[1] = '{idx: 1,   base: 32'h6000_0000, mask: 32'hffff_f200};
  assign address_map[2] = '{idx: 2,   base: 32'h4000_0000, mask: 32'hffff_f200};
  assign address_map[3] = '{idx: 3,   base: 32'h3000_0000, mask: 32'hffff_f200};
  assign address_map[4] = '{idx: 4,   base: 32'h2000_0000, mask: 32'hffff_f200};
  assign address_map[5] = '{idx: 5,   base: McuBootAddr,   mask: 32'hffff_f000};
  assign address_map[6] = '{idx: 6,   base: 32'h0000_0000, mask: 32'hfff4_0000};

  rvj1_obi #(
    .BootAddr (McuBootAddr),
    .DmRomAddr(McuDmRomAddr),
    .MVendorId(McuMVendorId),
    .MArchId  (McuMArchId),
    .MImpId   (McuMImpId),
    .MHartId  (McuMHartId)
  ) rvj1_inst (
    .clk_i          (clk),
    .rstn_i         (hwsw_rstn),

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
    .irq_timer_i    (tim_irq),
    .irq_sw_i       (1'b0),
    .irq_lcofi_i    (1'b0),
    .irq_platform_i ('0),
    .irq_nmi_i      (1'b0),

    .ext_dbg_req_i  (debug_req)
  );
  assign obi_instr_agnt                          = obi_agnt_signals_mgr[XbarMgrIfu];
  assign obi_a_chans_mgr[XbarMgrIfu].obi_areq    = obi_instr_areq;
  assign obi_a_chans_mgr[XbarMgrIfu].obi_aadr    = obi_instr_aaddr;
  assign obi_a_chans_mgr[XbarMgrIfu].obi_awe     = obi_instr_awe;
  assign obi_a_chans_mgr[XbarMgrIfu].obi_abe     = obi_instr_abe;
  assign obi_a_chans_mgr[XbarMgrIfu].obi_awdata  = obi_instr_awdata;
  assign obi_a_chans_mgr[XbarMgrIfu].obi_aid     = obi_instr_aid;

  assign obi_rready_signals_mgr[XbarMgrIfu]  = obi_instr_rready;
  assign obi_instr_rvalid                    = obi_r_chans_mgr[XbarMgrIfu].obi_rvalid;
  assign obi_instr_rdata                     = obi_r_chans_mgr[XbarMgrIfu].obi_rdata;
  assign obi_instr_rerr                      = obi_r_chans_mgr[XbarMgrIfu].obi_rerr;
  assign obi_instr_rid                       = obi_r_chans_mgr[XbarMgrIfu].obi_rid;

  assign obi_data_agnt                          = obi_agnt_signals_mgr[XbarMgrLsu];
  assign obi_a_chans_mgr[XbarMgrLsu].obi_areq   = obi_data_areq;
  assign obi_a_chans_mgr[XbarMgrLsu].obi_aadr   = obi_data_aaddr;
  assign obi_a_chans_mgr[XbarMgrLsu].obi_awe    = obi_data_awe;
  assign obi_a_chans_mgr[XbarMgrLsu].obi_abe    = obi_data_abe;
  assign obi_a_chans_mgr[XbarMgrLsu].obi_awdata = obi_data_awdata;
  assign obi_a_chans_mgr[XbarMgrLsu].obi_aid    = obi_data_aid;

  assign obi_rready_signals_mgr[XbarMgrLsu]  = obi_data_rready;
  assign obi_data_rvalid                     = obi_r_chans_mgr[XbarMgrLsu].obi_rvalid;
  assign obi_data_rdata                      = obi_r_chans_mgr[XbarMgrLsu].obi_rdata;
  assign obi_data_rerr                       = obi_r_chans_mgr[XbarMgrLsu].obi_rerr;
  assign obi_data_rid                        = obi_r_chans_mgr[XbarMgrLsu].obi_rid;

  obi_xbar #(
    .XbarCfg(xbar_cfg),
    .mgr_obi_a_t(mgr_obi_a_t),
    .mgr_obi_r_t(mgr_obi_r_t),
    .sub_obi_a_t(sub_obi_a_t),
    .sub_obi_r_t(sub_obi_r_t),
    .addr_map_t(addr_map_t),

    .USE_SR_FIFO_MASK(UseSrFifoMask),
    .SR_FIFO_DEPTHS(SrFifoDepth),

    .CONNECTIVITY(Connectivity)
  ) xbar (
    .clk_i            (clk),
    .rstn_i           (hwsw_rstn),

    .mgr_obi_a_chans       (obi_a_chans_mgr),
    .mgr_obi_agnt_signals  (obi_agnt_signals_mgr),
    .mgr_obi_r_chans       (obi_r_chans_mgr),
    .mgr_obi_rready_signals(obi_rready_signals_mgr),

    .sub_obi_a_chans       (obi_a_chans_sub),
    .sub_obi_agnt_signals  (obi_agnt_signals_sub),
    .sub_obi_r_chans       (obi_r_chans_sub),
    .sub_obi_rready_signals(obi_rready_signals_sub),

    .addr_map_i            ( address_map )
  );

  assign obi_r_chans_sub[XbarSbrMem].obi_rerr = 1'b0;
  obi_ram #(
    .INIT_FILE     (INIT_FILE),
    .INIT_FILE_BIN (INIT_FILE_BIN),
    .MEM_SIZE_WORDS(MEM_SIZE_WORDS),
    .IDLEN         (xbar_cfg.IdWidth + 2)
  ) mem (
    .clk_i  (clk),
    .rstn_i (hwsw_rstn),

    .obi_aid_i    (obi_a_chans_sub[XbarSbrMem].obi_aid),
    .obi_areq_i   (obi_a_chans_sub[XbarSbrMem].obi_areq),
    .obi_agnt_o   (obi_agnt_signals_sub[XbarSbrMem]),
    .obi_aaddr_i  (obi_a_chans_sub[XbarSbrMem].obi_aadr),
    .obi_awe_i    (obi_a_chans_sub[XbarSbrMem].obi_awe),
    .obi_awdata_i (obi_a_chans_sub[XbarSbrMem].obi_awdata),
    .obi_abe_i    (obi_a_chans_sub[XbarSbrMem].obi_abe),

    .obi_rid_o    (obi_r_chans_sub[XbarSbrMem].obi_rid),
    .obi_rvalid_o (obi_r_chans_sub[XbarSbrMem].obi_rvalid),
    .obi_rready_i (obi_rready_signals_sub[XbarSbrMem]),
    .obi_rdata_o  (obi_r_chans_sub[XbarSbrMem].obi_rdata)
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
    .trst_ni         (jtag_trstn_i),
    .tdo_oe_o        ()
  );

  assign obi_a_chans_mgr[XbarMgrDbg].obi_aid = '0;
  assign obi_rready_signals_mgr[XbarMgrDbg]  = 1'b1;
  assign obi_r_chans_sub[XbarSbrDbg].obi_rerr = 1'b0;
  dm_obi_top #(
    .NrHarts  (1),
    .BusWidth (DataWidth),
    .IdWidth  (xbar_cfg.IdWidth + 2),
    .DmBaseAddress('0)
  ) dm_obi_top_inst (
    .clk_i       (clk),
    .rst_ni      (rstn),
    .testmode_i  (1'b0),
    .ndmreset_o  (ndmreset),
    .dmactive_o  (),

    .debug_req_o   (debug_req),
    .unavailable_i (1'b0),
    .hartinfo_i    (hartinfo),

    .slave_req_i       (obi_a_chans_sub[XbarSbrDbg].obi_areq),
    .slave_we_i        (obi_a_chans_sub[XbarSbrDbg].obi_awe),
    .slave_addr_i      (obi_a_chans_sub[XbarSbrDbg].obi_aadr),
    .slave_be_i        (obi_a_chans_sub[XbarSbrDbg].obi_abe),
    .slave_wdata_i     (obi_a_chans_sub[XbarSbrDbg].obi_awdata),
    .slave_aid_i       (obi_a_chans_sub[XbarSbrDbg].obi_aid),
    .slave_gnt_o       (obi_agnt_signals_sub[XbarSbrDbg]),
    .slave_rvalid_o    (obi_r_chans_sub[XbarSbrDbg].obi_rvalid),
    .slave_rdata_o     (obi_r_chans_sub[XbarSbrDbg].obi_rdata),
    .slave_rid_o       (obi_r_chans_sub[XbarSbrDbg].obi_rid),

    .master_req_o      (obi_a_chans_mgr[XbarMgrDbg].obi_areq),
    .master_addr_o     (obi_a_chans_mgr[XbarMgrDbg].obi_aadr),
    .master_we_o       (obi_a_chans_mgr[XbarMgrDbg].obi_awe),
    .master_be_o       (obi_a_chans_mgr[XbarMgrDbg].obi_abe),
    .master_wdata_o    (obi_a_chans_mgr[XbarMgrDbg].obi_awdata),
    .master_gnt_i      (obi_agnt_signals_mgr[XbarMgrDbg]),
    .master_rvalid_i   (obi_r_chans_mgr[XbarMgrDbg].obi_rvalid),
    .master_rdata_i    (obi_r_chans_mgr[XbarMgrDbg].obi_rdata),
    .master_err_i      (obi_r_chans_mgr[XbarMgrDbg].obi_rerr),
    .master_other_err_i(1'b0),

    .dmi_rst_ni        (dmi_rst_n),
    .dmi_req_valid_i   (dmi_req_valid),
    .dmi_req_ready_o   (dmi_req_ready),
    .dmi_req_i         (dmi_req),

    .dmi_resp_valid_o  (dmi_resp_valid),
    .dmi_resp_ready_i  (dmi_resp_ready),
    .dmi_resp_o        (dmi_resp)
  );

  assign obi_r_chans_sub[XbarSbrUart].obi_rid = '0;
  obi_uart obi_uart_inst (
    .clk_i  (clk),
    .rstn_i (hwsw_rstn),

    .obi_areq_i  (obi_a_chans_sub[XbarSbrUart].obi_areq),
    .obi_agnt_o  (obi_agnt_signals_sub[XbarSbrUart]),
    .obi_aaddr_i (obi_a_chans_sub[XbarSbrUart].obi_aadr),
    .obi_awdata_i(obi_a_chans_sub[XbarSbrUart].obi_awdata),
    .obi_awe_i   (obi_a_chans_sub[XbarSbrUart].obi_awe) ,
    .obi_abe_i   (obi_a_chans_sub[XbarSbrUart].obi_abe),

    .obi_rvalid_o(obi_r_chans_sub[XbarSbrUart].obi_rvalid),
    .obi_rready_i(obi_rready_signals_sub[XbarSbrUart]),
    .obi_rdata_o (obi_r_chans_sub[XbarSbrUart].obi_rdata),
    .obi_rerr_o  (obi_r_chans_sub[XbarSbrUart].obi_rerr),

    .tx_o        (tx)
  );

   assign obi_r_chans_sub[XbarSbrGpio].obi_rid = '0;
   obi_gpio #(
       .ADDR_WIDTH(32),
       .DATA_WIDTH(32),
       .NUM_IN(GPIO_NUM_IN),
       .NUM_OUT(GPIO_NUM_OUT)
   ) obi_gpio_inst (
       .clk_i       (clk),
       .rstn_i      (hwsw_rstn),
       .obi_areq_i  (obi_a_chans_sub[XbarSbrGpio].obi_areq),
       .obi_agnt_o  (obi_agnt_signals_sub[XbarSbrGpio]),
       .obi_aaddr_i (obi_a_chans_sub[XbarSbrGpio].obi_aadr),
       .obi_awdata_i(obi_a_chans_sub[XbarSbrGpio].obi_awdata),
       .obi_awe_i   (obi_a_chans_sub[XbarSbrGpio].obi_awe) ,
       .obi_abe_i   (obi_a_chans_sub[XbarSbrGpio].obi_abe),

       .obi_rvalid_o(obi_r_chans_sub[XbarSbrGpio].obi_rvalid),
       .obi_rready_i(obi_rready_signals_sub[XbarSbrGpio]),
       .obi_rdata_o (obi_r_chans_sub[XbarSbrGpio].obi_rdata),
       .obi_rerr_o  (obi_r_chans_sub[XbarSbrGpio].obi_rerr),
       .gpio_in_i   (gpio_in_i),
       .gpio_out_o  (gpio_out_o)
   );

   assign obi_r_chans_sub[XbarSbrTimer].obi_rid = '0;
   obi_timer #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32)
   ) obi_timer_inst (
    .clk_i       (clk),
    .rstn_i      (hwsw_rstn),
    .obi_areq_i  (obi_a_chans_sub[XbarSbrTimer].obi_areq),
    .obi_agnt_o  (obi_agnt_signals_sub[XbarSbrTimer]),
    .obi_aaddr_i (obi_a_chans_sub[XbarSbrTimer].obi_aadr),
    .obi_awdata_i(obi_a_chans_sub[XbarSbrTimer].obi_awdata),
    .obi_awe_i   (obi_a_chans_sub[XbarSbrTimer].obi_awe) ,
    .obi_abe_i   (obi_a_chans_sub[XbarSbrTimer].obi_abe),

    .obi_rvalid_o(obi_r_chans_sub[XbarSbrTimer].obi_rvalid),
    .obi_rready_i(obi_rready_signals_sub[XbarSbrTimer]),
    .obi_rdata_o (obi_r_chans_sub[XbarSbrTimer].obi_rdata),
    .obi_rerr_o  (obi_r_chans_sub[XbarSbrTimer].obi_rerr),
    .overflow_o  (tim_irq)
);

assign obi_r_chans_sub[XbarSbrSpi].obi_rid = '0;
obi_spi #(
  .NUM_SLAVES (SPI_NUM_SLAVES)
) obi_spi_inst (
  .clk_i        (clk),
  .rstn_i       (hwsw_rstn),

  .obi_areq_i   (obi_a_chans_sub[XbarSbrSpi].obi_areq),
  .obi_agnt_o   (obi_agnt_signals_sub[XbarSbrSpi]),
  .obi_aaddr_i  (obi_a_chans_sub[XbarSbrSpi].obi_aadr),
  .obi_awdata_i (obi_a_chans_sub[XbarSbrSpi].obi_awdata),
  .obi_awe_i    (obi_a_chans_sub[XbarSbrSpi].obi_awe),
  .obi_abe_i    (obi_a_chans_sub[XbarSbrSpi].obi_abe),

  .obi_rvalid_o (obi_r_chans_sub[XbarSbrSpi].obi_rvalid),
  .obi_rready_i (obi_rready_signals_sub[XbarSbrSpi]),
  .obi_rdata_o  (obi_r_chans_sub[XbarSbrSpi].obi_rdata),
  .obi_rerr_o   (obi_r_chans_sub[XbarSbrSpi].obi_rerr),  

  .spi_ss_o     (spi_ss_o),
  .spi_sclk_o   (spi_sclk_o),
  .spi_mosi_o   (spi_mosi_o),
  .spi_miso_i   (spi_miso_i),

  .complete_o   ()
);

assign obi_r_chans_sub[XbarSbrBoot].obi_rid = '0;
obi_rom obi_rom_inst (
  .clk_i        (clk),
  .rstn_i       (hwsw_rstn),

  .obi_areq_i   (obi_a_chans_sub[XbarSbrBoot].obi_areq),
  .obi_agnt_o   (obi_agnt_signals_sub[XbarSbrBoot]),
  .obi_aaddr_i  (obi_a_chans_sub[XbarSbrBoot].obi_aadr),
  .obi_awdata_i (obi_a_chans_sub[XbarSbrBoot].obi_awdata),
  .obi_awe_i    (obi_a_chans_sub[XbarSbrBoot].obi_awe),
  .obi_abe_i    (obi_a_chans_sub[XbarSbrBoot].obi_abe),

  .obi_rvalid_o (obi_r_chans_sub[XbarSbrBoot].obi_rvalid),
  .obi_rready_i (obi_rready_signals_sub[XbarSbrBoot]),
  .obi_rdata_o  (obi_r_chans_sub[XbarSbrBoot].obi_rdata),
  .obi_err_o    (obi_r_chans_sub[XbarSbrBoot].obi_rerr)
);

endmodule
