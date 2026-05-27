module mcu_soc_jtag_tb #(
  parameter string       INIT_FILE="",
  parameter int unsigned INIT_FILE_BIN=0,
  parameter int unsigned MEM_SIZE_WORDS=4096,
  parameter int unsigned TIMEOUT=100000,
  parameter int unsigned OPENOCD_PORT=9999
) ();

  logic clk, rstn, tx, rx;
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
    .MEM_SIZE_WORDS (MEM_SIZE_WORDS)
  ) mcux (
    .clk         (clk),
    .rstn        (rstn),
  
    .jtag_tck_i  (sim_jtag_tck),
    .jtag_tdi_i  (sim_jtag_tdi),
    .jtag_tdo_o  (sim_jtag_tdo),
    .jtag_tms_i  (sim_jtag_tms),
    .jtag_trst_ni(sim_jtag_trstn),

    .tx          (tx),
    .rx          (rx)
  );
  assign rx = 1'b0;

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
      $finish(2);
    end
  end

  initial begin
  $display("Starting simulation of MCU with JTAG and debug module.");
  $display("Initialiting memory with: %s", INIT_FILE);
  $dumpfile("dump_debug.fst");
  $dumpvars();
  clk = 1'b0;
  rstn = 1'b0;
  repeat (3) @ (posedge clk);
  rstn = 1'b1;
  repeat (TIMEOUT) @ (posedge clk);
  $finish;
  end

endmodule
