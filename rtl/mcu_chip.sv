// Copyright 2024 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// mcu_chip: chip-level wrapper around mcu_soc.
//
// Pad INSTANCE names match padring.tcl (place_pad "pad_*"). Synthesize this as
// TOP_DESIGN so the pad_* instances exist.
//
// Power rails (consistent with power_connect.tcl):
//   VDD / VSS     = core 1.2V domain
//   VDDIO / VSSIO = pad-ring 3.3V domain
// The IO-cell PINS are lowercase (.vdd/.vss/.iovdd/.iovss); the NETS they
// connect to are the uppercase rails above.
//
// Supply pads carry (* dont_touch = "true" *) so synthesis opt_clean does not
// delete the pinless cells (else -> PAD-0018 in the padring). Use (* keep *)
// instead if your Yosys flow ignores dont_touch.
//
// Synthesis: leave USE_POWER_PINS UNDEFINED (croc-style); OpenROAD wires rails
// via the PDN + connect_by_abutment. Define it only for power-aware sims/LVS.

module mcu_chip (
  // ---- signal package pins ----
  input  wire clk,
  input  wire rstn,

  input  wire jtag_tck_i,
  input  wire jtag_tdi_i,
  output wire jtag_tdo_o,
  input  wire jtag_tms_i,
  input  wire jtag_trstn_i,

  output wire tx,

  input  wire gpio_in_i_0,
  input  wire gpio_in_i_1,
  input  wire gpio_in_i_2,
  input  wire gpio_in_i_3,

  output wire gpio_out_o_0,
  output wire gpio_out_o_1,
  output wire gpio_out_o_2,
  output wire gpio_out_o_3,

  output wire spi_ss_o_0,
  output wire spi_sclk_o,
  output wire spi_mosi_o,
  input  wire spi_miso_i,

  // ---- supply package pins (rails) ----
  inout wire VDD,    // core 1.2V
  inout wire VSS,    // core ground
  inout wire VDDIO,  // pad-ring 3.3V
  inout wire VSSIO   // pad-ring ground
);

  // Core-side nets
  logic       clk_c, rstn_c;
  logic       jtag_tck_c, jtag_tdi_c, jtag_tdo_c, jtag_tms_c, jtag_trstn_c;
  logic       tx_c;
  logic [3:0] gpio_in_c;
  logic [3:0] gpio_out_c;
  logic [0:0] spi_ss_c;
  logic       spi_sclk_c, spi_mosi_c, spi_miso_c;

  // Power-pin connection (only emitted with USE_POWER_PINS)
  `define IO_PWR `ifdef USE_POWER_PINS .iovdd(VDDIO), .iovss(VSSIO), .vdd(VDD), .vss(VSS), `endif
`ifdef USE_POWER_PINS
  `define SUP_CONN ( .iovdd(VDDIO), .iovss(VSSIO), .vdd(VDD), .vss(VSS) )
`else
  `define SUP_CONN ()
`endif

  // ---- Input pads (sg13g2_IOPadIn: .pad -> .p2c) ----
  sg13g2_IOPadIn pad_clk          ( `IO_PWR .pad(clk),          .p2c(clk_c)        );
  sg13g2_IOPadIn pad_rstn         ( `IO_PWR .pad(rstn),         .p2c(rstn_c)       );
  sg13g2_IOPadIn pad_jtag_tck_i   ( `IO_PWR .pad(jtag_tck_i),   .p2c(jtag_tck_c)   );
  sg13g2_IOPadIn pad_jtag_tdi_i   ( `IO_PWR .pad(jtag_tdi_i),   .p2c(jtag_tdi_c)   );
  sg13g2_IOPadIn pad_jtag_tms_i   ( `IO_PWR .pad(jtag_tms_i),   .p2c(jtag_tms_c)   );
  sg13g2_IOPadIn pad_jtag_trstn_i ( `IO_PWR .pad(jtag_trstn_i), .p2c(jtag_trstn_c) );
  sg13g2_IOPadIn pad_spi_miso_i   ( `IO_PWR .pad(spi_miso_i),   .p2c(spi_miso_c)   );
  sg13g2_IOPadIn pad_gpio_in_i_0  ( `IO_PWR .pad(gpio_in_i_0),  .p2c(gpio_in_c[0]) );
  sg13g2_IOPadIn pad_gpio_in_i_1  ( `IO_PWR .pad(gpio_in_i_1),  .p2c(gpio_in_c[1]) );
  sg13g2_IOPadIn pad_gpio_in_i_2  ( `IO_PWR .pad(gpio_in_i_2),  .p2c(gpio_in_c[2]) );
  sg13g2_IOPadIn pad_gpio_in_i_3  ( `IO_PWR .pad(gpio_in_i_3),  .p2c(gpio_in_c[3]) );

  // ---- Output pads (sg13g2_IOPadOut16mA: .c2p -> .pad) ----
  sg13g2_IOPadOut16mA pad_jtag_tdo_o   ( `IO_PWR .pad(jtag_tdo_o),   .c2p(jtag_tdo_c)    );
  sg13g2_IOPadOut16mA pad_tx           ( `IO_PWR .pad(tx),           .c2p(tx_c)          );
  sg13g2_IOPadOut16mA pad_spi_ss_o_0   ( `IO_PWR .pad(spi_ss_o_0),   .c2p(spi_ss_c[0])   );
  sg13g2_IOPadOut16mA pad_spi_sclk_o   ( `IO_PWR .pad(spi_sclk_o),   .c2p(spi_sclk_c)    );
  sg13g2_IOPadOut16mA pad_spi_mosi_o   ( `IO_PWR .pad(spi_mosi_o),   .c2p(spi_mosi_c)    );
  sg13g2_IOPadOut16mA pad_gpio_out_o_0 ( `IO_PWR .pad(gpio_out_o_0), .c2p(gpio_out_c[0]) );
  sg13g2_IOPadOut16mA pad_gpio_out_o_1 ( `IO_PWR .pad(gpio_out_o_1), .c2p(gpio_out_c[1]) );
  sg13g2_IOPadOut16mA pad_gpio_out_o_2 ( `IO_PWR .pad(gpio_out_o_2), .c2p(gpio_out_c[2]) );
  sg13g2_IOPadOut16mA pad_gpio_out_o_3 ( `IO_PWR .pad(gpio_out_o_3), .c2p(gpio_out_c[3]) );

  // ---- Supply pads (power-only; dont_touch; 4 per rail) ----
  (* dont_touch = "true" *) sg13g2_IOPadIOVdd pad_vddio0 `SUP_CONN ;
  (* dont_touch = "true" *) sg13g2_IOPadIOVdd pad_vddio1 `SUP_CONN ;
  (* dont_touch = "true" *) sg13g2_IOPadIOVdd pad_vddio2 `SUP_CONN ;
  (* dont_touch = "true" *) sg13g2_IOPadIOVdd pad_vddio3 `SUP_CONN ;

  (* dont_touch = "true" *) sg13g2_IOPadIOVss pad_vssio0 `SUP_CONN ;
  (* dont_touch = "true" *) sg13g2_IOPadIOVss pad_vssio1 `SUP_CONN ;
  (* dont_touch = "true" *) sg13g2_IOPadIOVss pad_vssio2 `SUP_CONN ;
  (* dont_touch = "true" *) sg13g2_IOPadIOVss pad_vssio3 `SUP_CONN ;

  (* dont_touch = "true" *) sg13g2_IOPadVdd   pad_vdd0   `SUP_CONN ;
  (* dont_touch = "true" *) sg13g2_IOPadVdd   pad_vdd1   `SUP_CONN ;
  (* dont_touch = "true" *) sg13g2_IOPadVdd   pad_vdd2   `SUP_CONN ;
  (* dont_touch = "true" *) sg13g2_IOPadVdd   pad_vdd3   `SUP_CONN ;

  (* dont_touch = "true" *) sg13g2_IOPadVss   pad_vss0   `SUP_CONN ;
  (* dont_touch = "true" *) sg13g2_IOPadVss   pad_vss1   `SUP_CONN ;
  (* dont_touch = "true" *) sg13g2_IOPadVss   pad_vss2   `SUP_CONN ;
  (* dont_touch = "true" *) sg13g2_IOPadVss   pad_vss3   `SUP_CONN ;

  logic synced_rst_n;           
  rstgen rstgen_i (             
    .clk_i       (clk),         
    .rst_ni      (rstn_c),        
    .test_mode_i (1'b0),        
    .rst_no      (synced_rst_n),
    .init_no     ()             
  );                            


  // ---- Core ----
  mcu_soc #(
    //.MEM_SIZE_WORDS (4096),
    .MEM_SIZE_WORDS (2048),
    .GPIO_NUM_IN    (4),
    .GPIO_NUM_OUT   (4),
    .SPI_NUM_SLAVES (1)
  ) i_mcu_soc (
    .clk          (clk_c),
    .rstn         (synced_rst_n),
    .jtag_tck_i   (jtag_tck_c),
    .jtag_tdi_i   (jtag_tdi_c),
    .jtag_tdo_o   (jtag_tdo_c),
    .jtag_tms_i   (jtag_tms_c),
    .jtag_trstn_i (jtag_trstn_c),
    .tx           (tx_c),
    .gpio_in_i    (gpio_in_c),
    .gpio_out_o   (gpio_out_c),
    .spi_ss_o     (spi_ss_c),
    .spi_sclk_o   (spi_sclk_c),
    .spi_mosi_o   (spi_mosi_c),
    .spi_miso_i   (spi_miso_c)
  );

  `undef IO_PWR
  `undef SUP_CONN

endmodule
