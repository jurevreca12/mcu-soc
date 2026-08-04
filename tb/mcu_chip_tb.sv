module mcu_chip_tb #(
  parameter string INIT_FILE="",
  parameter int    INIT_FILE_BIN=0,
  parameter int    MEM_SIZE_WORDS=2048,
  parameter int    TIMEOUT=50000000,
  parameter int    GPIO_NUM_IN=4,
  parameter int    GPIO_NUM_OUT=4,
  parameter int    SPI_NUM_SLAVES = 1
) (
  input  wire clk,
  input  wire rstn,
  output wire tx,
  output wire [GPIO_NUM_OUT-1:0] gpio_out,
  output wire [SPI_NUM_SLAVES-1:0] spi_ss_o,
  output wire spi_sclk_o, 
  output wire spi_mosi_o, 
  input  wire spi_miso_i
);
  /*, tx;
  logic [GPIO_NUM_OUT-1:0] gpio_out;
  logic [SPI_NUM_SLAVES-1:0] spi_ss_o;
  logic spi_sclk_o, spi_mosi_o, spi_miso_i;*/
  wire [GPIO_NUM_IN-1:0] gpio_in;
  reg jtag_trstn;

  assign gpio_in = '0;

  mcu_chip mcux (
    .clk          (clk),
    .rstn         (rstn),
    .jtag_tck_i   (1'b0),
    .jtag_tdi_i   (1'b0),
    .jtag_tdo_o   (),
    .jtag_tms_i   (1'b0),
    .jtag_trstn_i (jtag_trstn),
    .tx           (tx),
    .gpio_in_i_0  (gpio_in[0]),
    .gpio_in_i_1  (gpio_in[1]),
    .gpio_in_i_2  (gpio_in[2]),
    .gpio_in_i_3  (gpio_in[3]),
    .gpio_out_o_0 (gpio_out[0]),
    .gpio_out_o_1 (gpio_out[1]),
    .gpio_out_o_2 (gpio_out[2]),
    .gpio_out_o_3 (gpio_out[3]),
    .spi_ss_o_0   (spi_ss_o),
    .spi_sclk_o   (spi_sclk_o),
    .spi_mosi_o   (spi_mosi_o),
    .spi_miso_i   (spi_miso_i),
    .VDD          (),
    .VSS          (),
    .VDDIO        (),
    .VSSIO        ()
  );

  initial begin
  $display("Starting simulation of MCU.");
  $display("Initialiting memory with: %s", INIT_FILE);
  $display("Timeout set at: %d", TIMEOUT);
  $dumpfile("dump.fst");
  $dumpvars();
  jtag_trstn = 1'b0;
  repeat (6) @ (posedge clk);
  jtag_trstn = 1'b1;
  repeat (TIMEOUT) @ (posedge clk);
  $finish;
  end

endmodule
