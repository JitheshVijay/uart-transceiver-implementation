// Copyright Refringence
// Built with Refringence IDE — https://refringence.com
`timescale 1ns/1ps

// ===================== tb_receiver.sv =====================
module tb_receiver;
  localparam CLOCKS_PER_PULSE = 16;

  logic       clk       = 0;
  logic       rstn      = 0;
  logic       ready_clr = 0;
  logic       rx        = 1;
  wire        ready;
  wire [7:0]  data_out;
  logic [7:0] tx;
  int         timeout;

  receiver #(.CLOCKS_PER_PULSE(CLOCKS_PER_PULSE)) uut (
    .clk(clk),
    .rstn(rstn),
    .ready_clr(ready_clr),
    .rx(rx),
    .ready(ready),
    .data_out(data_out)
  );

  // 1ns clock
  always #1 clk = ~clk;

  // VCD
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_receiver);
  end

  task automatic hold_bit(input logic level, input int pulses);
    begin
      rx = level;
      repeat (pulses) @(posedge clk);
    end
  endtask

  task automatic send_byte(input logic [7:0] b);
    int i;
    begin
      // start (low)
      hold_bit(1'b0, CLOCKS_PER_PULSE);
      // 8 data bits LSB-first
      for (i = 0; i < 8; i++) begin
        hold_bit(b[i], CLOCKS_PER_PULSE);
      end
      // stop (high) + one idle bit
      hold_bit(1'b1, CLOCKS_PER_PULSE);
      hold_bit(1'b1, CLOCKS_PER_PULSE);
    end
  endtask

  initial begin
    // Reset
    repeat (5) @(posedge clk);
    rstn = 1;
    repeat (2) @(posedge clk);

    // Drive 0xA5
    tx = 8'hA5;
    send_byte(tx);

    // Wait for ready with timeout
    timeout = 0;
    while (!ready && timeout < (50 * CLOCKS_PER_PULSE)) begin
      @(posedge clk);
      timeout++;
    end

    if (ready && data_out == tx)
      $display("TEST_PASSED");
    else
      $display("TEST_FAILED: data_out = %02h, ready = %0d", data_out, ready);

    // Clear ready and finish after allowing VCD to flush
    ready_clr = 1; @(posedge clk); ready_clr = 0;
    repeat (10) @(posedge clk);
    $dumpflush;
    repeat (2) @(posedge clk);
    $finish;
  end
endmodule