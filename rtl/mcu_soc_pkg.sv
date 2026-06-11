
package mcu_soc_pkg;
  `include "obi_typedef.svh"

  localparam logic [31:0] McuBootAddr     = 32'h1000_0000;
  localparam logic [31:0] McuDmRomAddr    = 32'h0000_0800;
  localparam logic [31:0] McuDmExcAddr       = 32'h0000_0810;
  localparam logic [6:0]  MVendorIdOffset = 7'h2;
  localparam logic [24:0] MVendorIdBank   = 25'hC;
  localparam logic [31:0] McuMVendorId    = {MVendorIdBank, MVendorIdOffset};
  localparam logic [31:0] McuMArchId      = 32'hd22;
  localparam logic [31:0] McuMImpId       = '0;
  localparam int unsigned McuMHartId      = 0;
  localparam int unsigned AddrWidth       = 32;
  localparam int unsigned DataWidth       = 32;
  localparam int unsigned IdWidth         = 4;

  localparam dm::hartinfo_t HartInfo = '{
    zero0: '0,
    zero1: '0,
    nscratch: 2,
    dataaccess: 1'b1,
    datasize: dm::DataCount,
    dataaddr: dm::DataAddr
  };
  

  localparam int unsigned NumManagers     = 3;
  localparam int unsigned NumSubordinates = 7;

  typedef enum int {
    XbarSbrMem   = 0,
    XbarSbrUart  = 1,
    XbarSbrGpio  = 2,
    XbarSbrTimer = 3,
    XbarSbrSpi   = 4,
    XbarSbrBoot  = 5,
    XbarSbrDbg   = 6
  } xbar_sub_e;

  typedef enum int {
    XbarMgrLsu   = 0,
    XbarMgrIfu   = 1,
    XbarMgrDbg   = 2
  } xbar_mgr_e;


  // Xbar & Obi config
  localparam obi_pkg::xbar_cfg_t xbar_cfg = obi_pkg::xbar_default_cfg(NumManagers, NumSubordinates, AddrWidth, DataWidth, IdWidth);

  localparam bit unsigned [xbar_cfg.Subordinates-1:0] UseSrFifoMask = 7'b1111111;
  localparam int unsigned SrFifoDepth [xbar_cfg.Subordinates] = '{4, 4, 4, 4, 4, 4, 4};

  typedef struct packed {
        logic [xbar_cfg.IdWidth-1:0]          obi_aid;
        logic [$clog2(xbar_cfg.Managers)-1:0] obi_mid;
  } obi_sub_id_t;

  typedef struct packed {
        logic                               obi_areq;
        logic [xbar_cfg.AddrWidth-1:0]      obi_aadr;
        logic                               obi_awe; 
        logic [xbar_cfg.DataWidth/8-1:0]    obi_abe;
        logic [xbar_cfg.DataWidth-1:0]      obi_awdata;
        logic [xbar_cfg.IdWidth-1:0]        obi_aid;
    } mgr_obi_a_t;

  typedef struct packed {
        logic                               obi_rvalid;
        logic                               obi_rerr;
        logic [xbar_cfg.DataWidth-1:0]      obi_rdata;
        logic [xbar_cfg.IdWidth-1:0]        obi_rid;
    } mgr_obi_r_t;

  typedef struct packed {
        logic                               obi_areq;
        logic [xbar_cfg.AddrWidth-1:0]      obi_aadr;
        logic                               obi_awe; 
        logic [xbar_cfg.DataWidth/8-1:0]    obi_abe;
        logic [xbar_cfg.DataWidth-1:0]      obi_awdata;
        logic [(xbar_cfg.IdWidth+2)-1:0]    obi_aid;
    } sub_obi_a_t;

  typedef struct packed {
        logic                               obi_rvalid;
        logic                               obi_rerr;
        logic [xbar_cfg.DataWidth-1:0]      obi_rdata;
        logic [(xbar_cfg.IdWidth+2)-1:0]    obi_rid;
    } sub_obi_r_t;
  //`TYPEDEF_OBI_CHANS(mgr_obi_a_t, mgr_obi_r_t, obi_pkg::MANAGER, xbar_cfg);
  //`TYPEDEF_OBI_CHANS(sub_obi_a_t, sub_obi_r_t, obi_pkg::SUBORDINATE, xbar_cfg);

  `TYPEDEF_XBAR_ADDR_MAP(addr_map_t, AddrWidth, NumSubordinates);

  /*localparam addr_map_t Rvj1AddrMap [xbar_cfg.NoMaps] = '{
      '{idx: XbarSbrMem,   base: 32'h8000_0000, mask: 32'hffff_4000}, 
      '{idx: XbarSbrUart,  base: 32'h6000_0000, mask: 32'hffff_f200},
      '{idx: XbarSbrGpio,  base: 32'h4000_0000, mask: 32'hffff_f200},
      '{idx: XbarSbrTimer, base: 32'h3000_0000, mask: 32'hffff_f200},
      '{idx: XbarSbrDbg,   base: 32'h0000_0000, mask: 32'hfff4_0000}
  };*/

  `TYPEDEF_XBAR_CONNECTIVITY(Connectivity, NumSubordinates, NumManagers, {{7'b1111111}, {7'b1111111}, {7'b1111111}});

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
