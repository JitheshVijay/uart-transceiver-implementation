// Copyright Refringence
// Built with Refringence IDE — https://refringence.com
`timescale 1ns/1ps
module display_controller #(
  parameter bit     COMMON_ANODE = 1,     // 1=common anode, 0=common cathode
  parameter integer NUM_DIGITS   = 4,     // number of digits driven by an[*]
  parameter integer REFRESH_HZ   = 1000,  // per-digit refresh rate
  parameter integer CLOCK_HZ     = 50_000_000
)(
  input  logic        clk,
  input  logic        rstn,
  input  logic [3:0]  hex0,
  input  logic [3:0]  hex1,
  input  logic [3:0]  hex2,
  input  logic [3:0]  hex3,
  output logic [6:0]  seg,      // {g,f,e,d,c,b,a}
  output logic [3:0]  an        // digit enables (active-low for CA, active-high for CC)
);

  // Compute ticks per digit (simple round)
  localparam integer TICKS_PER_DIGIT = CLOCK_HZ / (REFRESH_HZ * (NUM_DIGITS > 0 ? NUM_DIGITS : 1));

  logic [$clog2(TICKS_PER_DIGIT+1)-1:0] tick_cnt;
  logic [1:0]                            mux_sel; // supports up to 4 digits

  always_ff @(posedge clk or negedge rstn) begin
    if (!rstn) begin
      tick_cnt <= '0;
      mux_sel  <= 2'd0;
    end else begin
      if (tick_cnt == TICKS_PER_DIGIT-1) begin
        tick_cnt <= '0;
        mux_sel  <= mux_sel + 2'd1;
      end else begin
        tick_cnt <= tick_cnt + 1'b1;
      end
    end
  end

  // Select nibble for current digit
  logic [3:0] cur_nibble;
  always_comb begin
    unique case (mux_sel)
      2'd0: cur_nibble = hex0;
      2'd1: cur_nibble = hex1;
      2'd2: cur_nibble = hex2;
      default: cur_nibble = hex3;
    endcase
  end

  // Use the existing LUT from earlier stages
  // binary_to_7seg expects ports: binary_in, seg_out
  logic [6:0] seg_raw;
  binary_to_7seg #(.COMMON_ANODE(COMMON_ANODE)) u_lut (
    .binary_in(cur_nibble),
    .seg_out(seg_raw)
  );

  // Drive segment outputs directly from LUT
  assign seg = seg_raw;

  // Digit enables (time-multiplex)
  // For common anode (active-low digit enable), drive one low at a time.
  // For common cathode (active-high digit enable), drive one high at a time.
  logic [3:0] an_raw;
  always_comb begin
    // default all off
    an_raw = 4'b0000;
    an_raw[mux_sel] = 1'b1; // select one digit
  end

  generate
    if (COMMON_ANODE) begin : gen_ca
      // Active-low enables for CA
      assign an = ~an_raw;
    end else begin : gen_cc
      // Active-high enables for CC
      assign an = an_raw;
    end
  endgenerate

endmodule