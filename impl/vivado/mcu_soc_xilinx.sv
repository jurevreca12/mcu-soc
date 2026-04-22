module mcu_soc_xilinx import mcu_soc_pkg::*; #(
  parameter  string INIT_FILE="",
  parameter  int    INIT_FILE_BIN=0,
  parameter  int    MEM_SIZE_WORDS=4096
  ) (
  input  logic clk,
  input  logic rst,

  output logic tx,
  input  logic rx
);
  mcu_soc #(
    .INIT_FILE     (INIT_FILE),
    .INIT_FILE_BIN (INIT_FILE_BIN),
    .MEM_SIZE_WORDS(MEM_SIZE_WORDS)
  ) mcu1 (
    .clk (clk),
    .rstn(~rst),
    .tx  (tx),
    .rx  (rx)
  );
endmodule
