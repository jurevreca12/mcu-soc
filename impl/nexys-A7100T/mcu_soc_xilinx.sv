module mcu_soc_xilinx import mcu_soc_pkg::*; #(
  parameter  string INIT_FILE="text.hex",
  parameter  int    INIT_FILE_BIN=0,
  parameter  int    MEM_SIZE_WORDS=2048,
  parameter  int    GPIO_NUM_IN=4,
  parameter  int    GPIO_NUM_OUT=4,
  parameter  int    SPI_NUM_SLAVES=1
  ) (
  input  logic clk,
  input  logic rst,

  output logic tx,

  input  logic [GPIO_NUM_IN-1:0]  gpio_in_i,
  output logic [GPIO_NUM_OUT-1:0] gpio_out_o,


  output  logic [SPI_NUM_SLAVES-1 : 0]  spi_ss_o,
  output  logic                         spi_sclk_o,
  output  logic                         spi_mosi_o,
  input   logic                         spi_miso_i,

  output  logic                         spi_rstn_o,
  output  logic                         spi_wpn_o,
  output  logic                         spi_hldn_o,

  output  logic                         test_o
);

  logic synced_rst_n;
  rstgen rstgen_inst (
    .clk_i       (clk),
    .rst_ni      (~rst),
    .test_mode_i (1'b0),
    .rst_no      (synced_rst_n;
    .init_no     ()
  );

  mcu_soc #(
    .INIT_FILE     (INIT_FILE),
    .INIT_FILE_BIN (INIT_FILE_BIN),
    .MEM_SIZE_WORDS(MEM_SIZE_WORDS),
    .GPIO_NUM_IN   (GPIO_NUM_IN),
    .GPIO_NUM_OUT  (GPIO_NUM_OUT),
    .SPI_NUM_SLAVES(SPI_NUM_SLAVES)
  ) mcu1 (
    .clk         (clk),
    .rstn        (synced_rst_n),
    .jtag_tck_i  (),
    .jtag_tdi_i  (),
    .jtag_tdo_o  (),
    .jtag_tms_i  (1'b0),
    .jtag_trstn_i(1'b1),
    .tx          (tx),
    .gpio_in_i   (gpio_in_i),
    .gpio_out_o  (gpio_out_o),
    .spi_ss_o    (spi_ss_o),
    .spi_sclk_o  (spi_sclk_o),
    .spi_mosi_o  (spi_mosi_o),
    .spi_miso_i  (spi_miso_i)
  );

  assign spi_rstn_o = 1'b1;
  assign spi_wpn_o  = 1'b1;
  assign spi_hldn_o = 1'b1;



endmodule
