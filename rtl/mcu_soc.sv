module mcu_soc (
  input  logic clk,
  input  logic rstn,

  output logic tx,
  input  logic rx
);
  localparam int IdLen = 4;
  localparam int AddrWidth = 32;
  localparam int DataWidth = 32;
  localparam int NBytes = (DataWidth / 8);

  logic [IdLen-1:0]     instr_req_id;
  logic [AddrWidth-1:0] instr_req_addr;
  logic [DataWidth-1:0] instr_req_data;
  logic [NBytes-1:0]    instr_req_strobe;
  logic                 instr_req_valid;
  logic                 instr_req_ready;

  logic [IdLen-1:0]     instr_rsp_id;
  logic [DataWidth-1:0] instr_rsp_data;
  logic                 instr_rsp_error;
  logic                 instr_rsp_valid;
  logic                 instr_rsp_ready;
 
  logic [IdLen-1:0]     obi_instr_aid;
  logic                 obi_instr_areq;
  logic                 obi_instr_agnt;
  logic [AddrWidth-1:0] obi_instr_aaddr;
  logic                 obi_instr_awe;
  logic [NBytes-1:0]    obi_instr_abe;
  logic [DataWidth-1:0] obi_instr_awdata;

  logic [IdLen-1:0]     obi_instr_rid;
  logic                 obi_instr_rvalid;
  logic                 obi_instr_rready;
  logic [DataWidth-1:0] obi_instr_rdata;
  logic                 obi_instr_rerr;
 
  logic [IdLen-1:0]     data_req_id;
  logic [AddrWidth-1:0] data_req_addr;
  logic [DataWidth-1:0] data_req_data;
  logic [NBytes-1:0]    data_req_strobe;
  logic                 data_req_valid;
  logic                 data_req_ready;

  logic [IdLen-1:0]     data_rsp_id;
  logic [DataWidth-1:0] data_rsp_data;
  logic                 data_rsp_error;
  logic                 data_rsp_valid;
  logic                 data_rsp_ready;
  
  logic [IdLen-1:0]     obi_data_aid;
  logic                 obi_data_areq;
  logic                 obi_data_agnt;
  logic [AddrWidth-1:0] obi_data_aaddr;
  logic                 obi_data_awe;
  logic [NBytes-1:0]    obi_data_abe;
  logic [DataWidth-1:0] obi_data_awdata;

  logic [IdLen-1:0]     obi_data_rid;
  logic                 obi_data_rvalid;
  logic                 obi_data_rready;
  logic [DataWidth-1:0] obi_data_rdata;
  logic                 obi_data_rerr;

  obi_a_if.master [1:0] obi_a_mgrs;
  obi_r_if.master [1:0] obi_r_mgrs;
  
  obi_a_if.slave [1:0] obi_a_sub;
  obi_r_if.slave [1:0] obi_r_sub;

  rvj1_top rvj1_inst (
    .clk_i              (clk),
    .rstn_i             (rstn),

    .instr_req_id_o     (instr_req_id),
    .instr_req_addr_o   (instr_req_addr),
    .instr_req_data_o   (instr_req_data),
    .instr_req_strobe_o (instr_req_strobe),
    .instr_req_valid_o  (instr_req_valid),
    .instr_req_ready_i  (instr_req_ready),

    .instr_rsp_id_i     (instr_rsp_id),
    .instr_rsp_data_i   (instr_rsp_data),
    .instr_rsp_error_i  (instr_rsp_error),
    .instr_rsp_valid_i  (instr_rsp_valid),
    .instr_rsp_ready_o  (instr_rsp_ready),

    .data_req_id_o      (data_req_id),
    .data_req_addr_o    (data_req_addr),
    .data_req_data_o    (data_req_data),
    .data_req_strobe_o  (data_req_strobe),
    .data_req_write_o   (data_req_write),
    .data_req_valid_o   (data_req_valid),
    .data_req_ready_i   (data_req_ready),

    .data_rsp_id_i      (data_rsp_id),
    .data_rsp_data_i    (data_rsp_data),
    .data_rsp_error_i   (data_rsp_error),
    .data_rsp_valid_i   (data_rsp_valid),
    .data_rsp_ready_o   (data_rsp_ready),

    .irq_external_i     (1'b0),
    .irq_timer_i        (1'b0),
    .irq_sw_i           (1'b0),
    .irq_lcofi_i        (1'b0),
    .irq_platform_i     ('0),
    .irq_nmi_i          (1'b0)
  );

  mapped2obi #(
    .ADDR_WIDTH(AddrWidth),
    .DATA_WIDTH(DataWidth),
    .IDLEN(IdLen)) m2o_instr (
    
    .clk_i  (clk),
    .rstn_i (rstn),
    
    .mapped_req_id_o     (instr_req_id),
    .mapped_req_addr_o   (instr_req_addr),
    .mapped_req_data_o   (instr_req_data),
    .mapped_req_strobe_o (instr_req_strobe),
    .mapped_req_valid_o  (instr_req_valid),
    .mapped_req_ready_i  (instr_req_ready),

    .mapped_rsp_id_i     (instr_rsp_id),
    .mapped_rsp_data_i   (instr_rsp_data),
    .mapped_rsp_error_i  (instr_rsp_error),
    .mapped_rsp_valid_i  (instr_rsp_valid),
    .mapped_rsp_ready_o  (instr_rsp_ready),

    .obi_aid_o           (obi_instr_aid),
    .obi_areq_o          (obi_instr_areq),
    .obi_agnt_i          (obi_instr_agnt),
    .obi_aaddr_o         (obi_instr_aaddr),
    .obi_awe_o           (obi_instr_awe),
    .obi_abe_o           (obi_instr_abe),
    .obi_awdata_o        (obi_instr_awdata),

    .obi_rid_i           (obi_instr_rid),
    .obi_rvalid_i        (obi_instr_rvalid),
    .obi_rready_o        (obi_instr_rready),
    .obi_rdata_i         (obi_instr_rdata),
    .obi_rerr_i          (obi_instr_rerr)
  );
  
  mapped2obi #(
    .ADDR_WIDTH(AddrWidth),
    .DATA_WIDTH(DataWidth),
    .IDLEN(IdLen)) m2o_data (
    
    .clk_i  (clk),
    .rstn_i (rstn),
    
    .mapped_req_id_o     (data_req_id),
    .mapped_req_addr_o   (data_req_addr),
    .mapped_req_data_o   (data_req_data),
    .mapped_req_strobe_o (data_req_strobe),
    .mapped_req_valid_o  (data_req_valid),
    .mapped_req_ready_i  (data_req_ready),

    .mapped_rsp_id_i     (data_rsp_id),
    .mapped_rsp_data_i   (data_rsp_data),
    .mapped_rsp_error_i  (data_rsp_error),
    .mapped_rsp_valid_i  (data_rsp_valid),
    .mapped_rsp_ready_o  (data_rsp_ready),

    .obi_aid_o           (obi_data_aid),
    .obi_areq_o          (obi_data_areq),
    .obi_agnt_i          (obi_data_agnt),
    .obi_aaddr_o         (obi_data_aaddr),
    .obi_awe_o           (obi_data_awe),
    .obi_abe_o           (obi_data_abe),
    .obi_awdata_o        (obi_data_awdata),

    .obi_rid_i           (obi_data_rid),
    .obi_rvalid_i        (obi_data_rvalid),
    .obi_rready_o        (obi_data_rready),
    .obi_rdata_i         (obi_data_rdata),
    .obi_rerr_i          (obi_data_rerr)
  );

  testing_xbar_param #(
    .ADDR_WIDTH  (AddrWidth),
    .DATA_WIDTH  (DataWidth),
    .MANAGERS    (2),
    .SUBORDINATES(2),
    .FIFO_DEPTH  (2)
  ) xbar (
    .clk_i  (clk),
    .rstn_i (rstn),

    .obi_a_chans_mgr(obi_a_mgr),
    .obi_r_chans_mgr(obi_r_mgr),
  
    .obi_a_chans_sub(obi_a_sub),
    .obi_r_chans_sub(obi_r_sub)
  );
  
  obi_ram #(
    .INIT_FILE     (),
    .MEM_SIZE_WORDS(8192)
  ) ram (
    .clk_i  (clk),
    .rstn   (rstn),
    
    .obi_req_i   (obi_a_sub[SUB_ID_RAM].obi_areq),
    .obi_gnt_o   (obi_a_sub[SUB_ID_RAM].obi_agnt),
    .obi_addr_i  (obi_a_sub[SUB_ID_RAM].obi_aadr),
    .obi_we_i    (obi_a_sub[SUB_ID_RAM].obi_awe),
    .obi_wdata_i (obi_a_sub[SUB_ID_RAM].obi_awdata),
    .obi_be_i    (obi_a_sub[SUB_ID_RAM].obi_abe),

    .obi_rvalid_o(obi_r_sub[SUB_ID_RAM].obi_rvalid),
    .obi_rready_i(obi_r_sub[SUB_ID_RAM].obi_rready),
    .obi_rdata_o (obi_r_sub[SUB_ID_RAM].obi_rdata)
  );

  obi_uart uart (
    .obi_clk_i  (clk),
    .obi_rstn_i (rstn),
    
    .obi_req_i   (obi_a_sub[SUB_ID_UART].obi_areq),
    .obi_gnt_o   (obi_a_sub[SUB_ID_UART].obi_agnt),
    .obi_addr_i  (obi_a_sub[SUB_ID_UART].obi_aadr),
    .obi_we_i    (obi_a_sub[SUB_ID_UART].obi_awe),
    .obi_wdata_i (obi_a_sub[SUB_ID_UART].obi_awdata),
    .obi_be_i    (obi_a_sub[SUB_ID_UART].obi_abe),

    .obi_rvalid_o(obi_r_sub[SUB_ID_UART].obi_rvalid),
    .obi_rready_i(obi_r_sub[SUB_ID_UART].obi_rready),
    .obi_rdata_o (obi_r_sub[SUB_ID_UART].obi_rdata)
  );



endmodule
