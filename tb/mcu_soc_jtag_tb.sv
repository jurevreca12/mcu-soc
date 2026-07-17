module mcu_soc_jtag_tb #(
  parameter string       INIT_FILE="",
  parameter int unsigned INIT_FILE_BIN=0,
  parameter int unsigned MEM_SIZE_WORDS=2048,
  parameter int unsigned TIMEOUT=2000000,
  parameter int unsigned GPIO_NUM_IN=4,
  parameter int unsigned GPIO_NUM_OUT=4,
  parameter int unsigned SPI_NUM_SLAVES = 1,
  parameter int unsigned OPENOCD_PORT=9999,
  parameter string       DUMP_FILE="dump_debug.fst"
) ();

  logic clk, rstn, tx;
  logic [GPIO_NUM_OUT-1:0] gpio_out;
  logic [SPI_NUM_SLAVES-1:0] spi_ss_o;
  logic spi_sclk_o, spi_mosi_o, spi_miso_i;
  logic sim_jtag_tck;
  logic sim_jtag_tms;
  logic sim_jtag_tdi;
  logic sim_jtag_trstn;
  logic sim_jtag_tdo;
  logic sim_jtag_exit;
  always #5 clk = ~clk;

  mcu_soc #(
    .INIT_FILE      (INIT_FILE),
    .INIT_FILE_BIN  (INIT_FILE_BIN),
    .MEM_SIZE_WORDS (MEM_SIZE_WORDS),
    .GPIO_NUM_IN    (GPIO_NUM_IN),
    .GPIO_NUM_OUT   (GPIO_NUM_OUT),
    .SPI_NUM_SLAVES (SPI_NUM_SLAVES)
  ) mcux (
    .clk         (clk),
    .rstn        (rstn),
  
    .jtag_tck_i  (sim_jtag_tck),
    .jtag_tdi_i  (sim_jtag_tdi),
    .jtag_tdo_o  (sim_jtag_tdo),
    .jtag_tms_i  (sim_jtag_tms),
    .jtag_trstn_i(sim_jtag_trstn),
    .tx          (tx),
    .gpio_in_i   (4'b0000),
    .gpio_out_o  (gpio_out),
    .spi_ss_o    (spi_ss_o),
    .spi_sclk_o  (spi_sclk_o),
    .spi_mosi_o  (spi_mosi_o),
    .spi_miso_i  (spi_miso_i)
  );

  SimJTAG #(
    .TICK_DELAY(5),
    .PORT(OPENOCD_PORT)
  ) sim_jtag_inst (
    .clock          (clk),
    .reset          (~rstn),
    .enable         (1'b1),
    .init_done      (rstn),
    .jtag_TCK       (sim_jtag_tck),
    .jtag_TMS       (sim_jtag_tms),
    .jtag_TDI       (sim_jtag_tdi),
    .jtag_TRSTn     (sim_jtag_trstn),
    .jtag_TDO_data  (sim_jtag_tdo),
    .jtag_TDO_driven(1'b1),
    .exit           (sim_jtag_exit)
  );


  always_comb begin: jtag_exit_handler
    if (sim_jtag_exit) begin
      $display("SimJTAG requested exit. Ending simulation.");
      $finish(20);
    end
  end

  initial begin
    $display("Starting simulation of MCU with JTAG and debug module.");
    $display("Initialiting memory with: %s", INIT_FILE);
    $dumpfile(DUMP_FILE);
    $dumpvars();
    clk = 1'b0;
    rstn = 1'b0;
    repeat (3) @ (posedge clk);
    rstn = 1'b1;
    repeat (TIMEOUT) @ (posedge clk);
    $display("SIMULATION TIMED OUT!");
    $finish(20);
  end

endmodule
