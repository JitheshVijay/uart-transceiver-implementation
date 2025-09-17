// Copyright Refringence
// Built with Refringence IDE — https://refringence.com
`timescale 1ns/1ps
module fpga_top #(
  parameter integer CLOCK_FREQ_HZ      = 50_000_000,
  parameter integer BAUD_RATE          = 115200,
  parameter integer CLOCKS_PER_PULSE   = CLOCK_FREQ_HZ / BAUD_RATE, // e.g., 50e6/115200 ≈ 434
  parameter bit     COMMON_ANODE       = 1                          // 1 = common anode, 0 = common cathode
)(
  input  logic        clk_50mhz,
  input  logic        rstn_btn,         // active-low reset button
  input  logic        uart_rx,          // from USB-UART
  output logic        uart_tx,          // to USB-UART
  output logic [6:0]  seg,              // 7-seg segments {g,f,e,d,c,b,a}
  output logic [3:0]  an,               // digit enables (active depends on board wiring)
  output logic [7:0]  led               // LEDs show received byte
);

  // Global reset (debounced/synced simple form)
  logic rstn_sync_d, rstn_sync_q;
  always_ff @(posedge clk_50mhz or negedge rstn_btn) begin
    if (!rstn_btn) begin
      rstn_sync_d <= 1'b0;
      rstn_sync_q <= 1'b0;
    end else begin
      rstn_sync_d <= 1'b1;
      rstn_sync_q <= rstn_sync_d;
    end
  end
  wire rstn = rstn_sync_q;

  // UART
  logic        ready;
  logic        ready_clr;
  logic        tx_busy;
  logic [7:0]  rx_byte;
  logic [3:0]  nibble_in = 4'h0;
  logic        tx_en     = 1'b0; // not used (echo TX idle). Tie low.

  // Top-level UART uses the same timing for TX/RX
  // If your transmitter module uses CLK_FREQ/BAUD_RATE instead of CLOCKS_PER_PULSE,
  // adapt parameterization accordingly.
  uart #(.CLOCKS_PER_PULSE(CLOCKS_PER_PULSE)) u_uart (
    .data_in(nibble_in),
    .data_en(tx_en),
    .clk(clk_50mhz),
    .rstn(rstn),
    .tx(uart_tx),
    .tx_busy(tx_busy),
    .ready_clr(ready_clr),
    .rx(uart_rx),
    .ready(ready),
    .led_out(led),            // will mirror internal rx data
    .display_out()            // unused at top; we drive display via controller below
  );

  // Latch the received byte whenever ready pulses
  logic [7:0] latched_rx_byte;
  always_ff @(posedge clk_50mhz or negedge rstn) begin
    if (!rstn) begin
      latched_rx_byte <= 8'h00;
    end else if (ready) begin
      latched_rx_byte <= led; // uart maps internal rx data to led_out
    end
  end

  // Clear 'ready' as a one-shot after latching
  // Hold clear for one cycle to acknowledge
  always_ff @(posedge clk_50mhz or negedge rstn) begin
    if (!rstn) begin
      ready_clr <= 1'b0;
    end else begin
      ready_clr <= ready; // single-cycle clear pulse after ready
    end
  end

  // LEDs also reflect the last received byte
  assign led = latched_rx_byte;

  // Display controller: show 8-bit RX as two hex digits
  display_controller #(
    .COMMON_ANODE(COMMON_ANODE),
    .NUM_DIGITS(4),               // drive 4 digits; we’ll place data on lowest 2
    .REFRESH_HZ(1000)
  ) u_disp (
    .clk(clk_50mhz),
    .rstn(rstn),
    .hex0(latched_rx_byte[3:0]),   // least significant nibble
    .hex1(latched_rx_byte[7:4]),   // most significant nibble
    .hex2(4'h0),
    .hex3(4'h0),
    .seg(seg),
    .an(an)
  );

endmodule