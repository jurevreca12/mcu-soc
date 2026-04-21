package mcu_soc_pkg;

  localparam obi_pkg::obi_cfg_t ManObiCfg = '{
    UseRReady:   1'b1,
    CombGnt:     1'b0,
    AddrWidth:   32,
    DataWidth:   32,
    IdWidth:     4,
    Integrity:   1'b0,
    BeFull:      1'b1,
    OptionalCfg: '0
  };
  
  localparam obi_pkg::obi_cfg_t SubObiCfg = '{
    UseRReady:   1'b1,
    CombGnt:     1'b0,
    AddrWidth:   32,
    DataWidth:   32,
    IdWidth:     0,
    Integrity:   1'b0,
    BeFull:      1'b1,
    OptionalCfg: '0
  };

  typedef struct packed {
    logic [ManObiCfg.AddrWidth-1:0]   addr;
    logic                             we;
    logic [ManObiCfg.DataWidth/8-1:0] be;
    logic [ManObiCfg.DataWidth-1:0]   wdata;
    logic [ManObiCfg.IdWidth-1:0]     aid;
    logic                             a_optional;
  } man_obi_a_chan_t;

  typedef struct packed {
    man_obi_a_chan_t a;
    logic            req;
    logic            rready;
  } man_obi_req_t;

  typedef struct packed {
    logic [ManObiCfg.DataWidth-1:0] rdata;
    logic [ManObiCfg.IdWidth-1:0]   rid;
    logic                           err;
    logic                           r_optional;
  } man_obi_r_chan_t;

  typedef struct packed {
    man_obi_r_chan_t r;
    logic            gnt;
    logic            rvalid;
  } man_obi_rsp_t;
  
  typedef struct packed {
    logic [ManObiCfg.AddrWidth-1:0]   addr;
    logic                             we;
    logic [ManObiCfg.DataWidth/8-1:0] be;
    logic [ManObiCfg.DataWidth-1:0]   wdata;
    logic [ManObiCfg.IdWidth-1:0]     aid;
    logic                             a_optional;
  } man_obi_a_chan_t;

  typedef struct packed {
    man_obi_a_chan_t a;
    logic            req;
    logic            rready;
  } man_obi_req_t;

  typedef struct packed {
    logic [ManObiCfg.DataWidth-1:0] rdata;
    logic [ManObiCfg.IdWidth-1:0]   rid;
    logic                           err;
    logic                           r_optional;
  } man_obi_r_chan_t;

  typedef struct packed {
    man_obi_r_chan_t r;
    logic            gnt;
    logic            rvalid;
  } man_obi_rsp_t;

  typedef struct packed {
    logic [31:0] idx;
    logic [31:0] start_addr;
    logic [31:0] end_addr;
  } addr_map_rule_t;

  localparam int unsigned NumManagers     = 2;
  localparam int unsigned NumSubordinates = 2;
  typedef enum int {
    XbarMem  = 0,
    XbarUart = 1
  } xbar_sub_e;

  localparam addr_map_rule_t [NumSubordinates-1:0] Rvj1AddrMap = '{
      '{idx: XbarMem,  start_addr: 32'h8000_0000, end_addr: 32'h8000_4000},
      '{idx: XbarUart, start_addr: 32'h6000_0000, end_addr: 32'h6000_0200}
  };
endpackage
