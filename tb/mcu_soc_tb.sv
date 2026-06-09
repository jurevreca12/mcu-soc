module mcu_soc_tb #(
  parameter string INIT_FILE="",
  parameter int    INIT_FILE_BIN=0,
  parameter int    MEM_SIZE_WORDS=4096,
  parameter int    TIMEOUT=100000,
  parameter int    GPIO_NUM_IN=4,
  parameter int    GPIO_NUM_OUT=4,
  parameter int    SPI_NUM_SLAVES = 1
) ();

  logic clk, rstn, tx;
  logic [GPIO_NUM_OUT-1:0] gpio_out;
  logic [SPI_NUM_SLAVES-1:0] spi_ss_o;
  logic spi_sclk_o, spi_mosi_o, spi_miso_i;

  always #5 clk = ~clk;

  mcu_soc #(
    .INIT_FILE      (INIT_FILE),
    .INIT_FILE_BIN  (INIT_FILE_BIN),
    .MEM_SIZE_WORDS (MEM_SIZE_WORDS),
    .GPIO_NUM_IN    (GPIO_NUM_IN),
    .GPIO_NUM_OUT   (GPIO_NUM_OUT),
    .SPI_NUM_SLAVES (SPI_NUM_SLAVES)
  ) mcux (
    .clk          (clk),
    .rstn         (rstn),
    .jtag_tck_i   (1'b0),
    .jtag_tdi_i   (1'b0),
    .jtag_tdo_o   (),
    .jtag_tms_i   (1'b0),
    .jtag_trstn_i (1'b1),
    .tx           (tx),
    .gpio_in_i    (4'b0000),
    .gpio_out_o   (gpio_out),
    .spi_ss_o     (spi_ss_o),
    .spi_sclk_o   (spi_sclk_o),
    .spi_mosi_o   (spi_mosi_o),
    .spi_miso_i   (spi_miso_i)
  );

  initial begin
  $display("Starting simulation of MCU.");
  $display("Initialiting memory with: %s", INIT_FILE);
  $dumpfile("dump.fst");
  $dumpvars();
  clk = 1'b0;
  rstn = 1'b0;
  repeat (3) @ (posedge clk);
  rstn = 1'b1;
  repeat (TIMEOUT) @ (posedge clk);
  $finish;
  end

endmodule
