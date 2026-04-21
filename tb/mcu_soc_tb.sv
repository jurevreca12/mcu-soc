module mcu_soc_tb #(
  parameter string INIT_FILE="",
  parameter int    INIT_FILE_BIN=0,
  parameter int    MEM_SIZE_WORDS=4096,
  parameter int    TIMEOUT=100000
) ();

  logic clk, rstn, tx, rx;
  always #1 clk = ~clk;  

  mcu_soc #(
    .INIT_FILE      (INIT_FILE),
    .INIT_FILE_BIN  (INIT_FILE_BIN),
    .MEM_SIZE_WORDS (MEM_SIZE_WORDS)
  ) mcux (
    .clk (clk),
    .rstn(rstn),
    .tx  (tx),
    .rx  (rx)
  );

  assign rx = 1'b0;

  initial begin
  $display("Starting simulation of MCU.");
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
