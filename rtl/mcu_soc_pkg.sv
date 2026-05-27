package mcu_soc_pkg;


  localparam logic [31:0] McuBootAddr     = 32'h8000_0000;
  localparam logic [31:0] McuDmRomAddr    = 32'h0000_0800;
  localparam logic [6:0]  MVendorIdOffset = 7'h2;
  localparam logic [24:0] MVendorIdBank   = 25'hC;
  localparam logic [31:0] McuMVendorId    = {MVendorIdBank, MVendorIdOffset};
  localparam logic [31:0] McuMArchId      = 32'hd22;
  localparam logic [31:0] McuMImpId       = '0;
  localparam int unsigned McuMHartId      = 0;

  localparam obi_pkg::obi_cfg_t MgrObiCfg = '{
    UseRReady:   1'b1,
    CombGnt:     1'b0,
    AddrWidth:   32,
    DataWidth:   32,
    IdWidth:     4,
    Integrity:   1'b0,
    BeFull:      1'b1,
    OptionalCfg: '0
  };

  localparam obi_pkg::obi_cfg_t SbrObiCfg = '{
    UseRReady:   1'b1,
    CombGnt:     1'b0,
    AddrWidth:   32,
    DataWidth:   32,
    IdWidth:     6,
    Integrity:   1'b0,
    BeFull:      1'b1,
    OptionalCfg: '0
  };

  typedef struct packed {
    logic [MgrObiCfg.AddrWidth-1:0]   addr;
    logic                             we;
    logic [MgrObiCfg.DataWidth/8-1:0] be;
    logic [MgrObiCfg.DataWidth-1:0]   wdata;
    logic [MgrObiCfg.IdWidth-1:0]     aid;
    logic                             a_optional;
  } mgr_obi_a_chan_t;

  typedef struct packed {
    mgr_obi_a_chan_t a;
    logic            req;
    logic            rready;
  } mgr_obi_req_t;

  typedef struct packed {
    logic [MgrObiCfg.DataWidth-1:0] rdata;
    logic [MgrObiCfg.IdWidth-1:0]   rid;
    logic                           err;
    logic                           r_optional;
  } mgr_obi_r_chan_t;

  typedef struct packed {
    mgr_obi_r_chan_t r;
    logic            gnt;
    logic            rvalid;
  } mgr_obi_rsp_t;

  typedef struct packed {
    logic [SbrObiCfg.AddrWidth-1:0]   addr;
    logic                             we;
    logic [SbrObiCfg.DataWidth/8-1:0] be;
    logic [SbrObiCfg.DataWidth-1:0]   wdata;
    logic [SbrObiCfg.IdWidth-1:0]     aid;
    logic                             a_optional;
  } sbr_obi_a_chan_t;

  typedef struct packed {
    sbr_obi_a_chan_t a;
    logic            req;
    logic            rready;
  } sbr_obi_req_t;

  typedef struct packed {
    logic [SbrObiCfg.DataWidth-1:0] rdata;
    logic [SbrObiCfg.IdWidth-1:0]   rid;
    logic                           err;
    logic                           r_optional;
  } sbr_obi_r_chan_t;

  typedef struct packed {
    sbr_obi_r_chan_t r;
    logic            gnt;
    logic            rvalid;
  } sbr_obi_rsp_t;

  typedef struct packed {
    logic [31:0] idx;
    logic [31:0] start_addr;
    logic [31:0] end_addr;
  } addr_map_rule_t;

  localparam int unsigned NumManagers     = 3;
  localparam int unsigned NumSubordinates = 3;
  typedef enum int {
    XbarMem  = 0,
    XbarUart = 1,
    XbarDbg  = 2
  } xbar_sub_e;

  localparam addr_map_rule_t [NumSubordinates-1:0] Rvj1AddrMap = '{
      '{idx: XbarMem,  start_addr: 32'h8000_0000, end_addr: 32'h8000_4000},
      '{idx: XbarUart, start_addr: 32'h6000_0000, end_addr: 32'h6000_0200},
      '{idx: XbarDbg,  start_addr: 32'h0000_0000, end_addr: 32'h0004_0000}
  };

  typedef struct packed {
    bit [ 3:0] version;
    bit [15:0] part_num;
    bit [10:0] manufacturer;
    bit        _one;
  } jtag_idcode_t;

  localparam jtag_idcode_t Rvj1JtagIdCode = '{
    version: 4'h0,
    part_num: 16'hC0C5,
    manufacturer: 11'h6d9,
    _one: 1
  };
endpackage
