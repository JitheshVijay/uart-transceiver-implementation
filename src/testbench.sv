// Copyright Refringence
// Built with Refringence IDE — https://refringence.com
`timescale 1ns/1ps
module testbench();
  localparam CLOCKS_PER_PULSE = 4;
  logic [3:0] data_in = 4'b0001;
  logic clk = 0;
  logic rstn = 0;
  logic enable = 1;
  
  logic tx_busy;
  logic ready;
  logic [7:0] data_out;
  logic [6:0] display_out;
  
  logic loopback;
  logic ready_clr = 0;  // allow ready to assert
  
  uart #(.CLOCKS_PER_PULSE(CLOCKS_PER_PULSE)) 
       test_uart(.data_in(data_in),
                 .data_en(enable),
                 .clk(clk),
                 .tx(loopback),
                 .tx_busy(tx_busy),
                 .rx(loopback),
                 .ready(ready),
                 .ready_clr(ready_clr),
                 .led_out(data_out),
                 .display_out(display_out),
                 .rstn(rstn)
                 );
  
  always begin
    #1 clk = ~clk;
  end

  // VCD
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, testbench);
  end

  // Reset + kick
  initial begin
    rstn <= 1;
    enable <= 1'b0;
    #2 rstn <= 0;
    #2 rstn <= 1;
    #5 enable <= 1'b1;
  end
    
  always @(posedge ready) begin
    // Compare the lower 4 bits of received data with sent data
    if (data_out[3:0] != data_in) begin
      $display("FAIL: rx data %x does not match tx %x", data_out[3:0], data_in);
      $finish();
    end else begin
      if (data_in == 4'b1111) begin
        $display("SUCCESS: all bytes verified");
        $display("PROJECT_COMPLETE");
        $finish();
      end
      
      #10 rstn <= 0;
      #2 rstn <= 1;
      data_in <= data_in + 1'b1;
      enable <= 1'b0;
      #2 enable <= 1'b1;
    end
  end
endmodule