// Copyright Refringence
// Built with Refringence IDE — https://refringence.com
module uart #(
  parameter CLOCKS_PER_PULSE = 5208
)(
  input logic [3:0] data_in,
  input logic data_en,
  input logic clk,
  input logic rstn,
  output logic tx,
  output logic tx_busy,
  input logic ready_clr,
  input logic rx,
  output logic ready,
  output logic [7:0] led_out,
  output logic [6:0] display_out
);
  
  logic [7:0] data_input; 
  logic [7:0] data_output;
  
  // Fix: Use CLOCKS_PER_PULSE for both transmitter and receiver
  transmitter #(.CLOCKS_PER_PULSE(CLOCKS_PER_PULSE)) uart_tx (
    .data_in(data_input),
    .data_en(data_en),
    .clk(clk),
    .rstn(rstn),
    .tx(tx),
    .tx_busy(tx_busy)
  );
  
  receiver #(.CLOCKS_PER_PULSE(CLOCKS_PER_PULSE)) uart_rx (
    .clk(clk),
    .rstn(rstn),
    .ready_clr(ready_clr),
    .rx(rx),
    .ready(ready),
    .data_out(data_output)
  );
  
  binary_to_7seg converter (
    .binary_in(data_output[3:0]),
    .seg_out(display_out)
  );
  
  assign data_input = {4'b0, data_in};
  assign led_out = data_output[7:0];
endmodule