// Copyright Refringence
// Built with Refringence IDE — https://refringence.com
module tb_transmitter;
    
    // Parameters
    parameter CLK_FREQ = 100_000_000;
    parameter BAUD_RATE = 115200;
    parameter BIT_PERIOD = CLK_FREQ / BAUD_RATE;
    
    // Signals
    logic        clk;
    logic        rstn;
    logic [7:0]  data_in;
    logic        data_en;
    logic        tx;
    logic        tx_busy;
    
    // Instantiate DUT
    transmitter #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) dut (
        .clk(clk),
        .rstn(rstn),
        .data_in(data_in),
        .data_en(data_en),
        .tx(tx),
        .tx_busy(tx_busy)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock (10ns period)
    end
    
    // Test variables
    logic [7:0] test_data;
    logic [7:0] received_data;
    integer     bit_count;
    integer     test_count;
    integer     pass_count;
    
    // Main test sequence
    initial begin
        $display("=== UART Transmitter Testbench ===");
        $display("Clock Frequency: %d Hz", CLK_FREQ);
        $display("Baud Rate: %d", BAUD_RATE);
        $display("Bit Period: %d clock cycles", BIT_PERIOD);
        $display("");
        
        // Initialize
        rstn = 0;
        data_in = 0;
        data_en = 0;
        test_count = 0;
        pass_count = 0;
        
        // Reset
        repeat(10) @(posedge clk);
        rstn = 1;
        repeat(10) @(posedge clk);
        
        // Test 1: Basic transmission
        $display("Test 1: Basic transmission (0x55)");
        test_data = 8'h55;
        transmit_data(test_data);
        verify_transmission(test_data);
        
        // Test 2: Different data patterns
        $display("Test 2: Various data patterns");
        test_data = 8'hAA;
        transmit_data(test_data);
        verify_transmission(test_data);
        
        test_data = 8'h00;
        transmit_data(test_data);
        verify_transmission(test_data);
        
        test_data = 8'hFF;
        transmit_data(test_data);
        verify_transmission(test_data);
        
        // Test 3: Sequential transmission
        $display("Test 3: Sequential transmission");
        for (int i = 0; i < 10; i++) begin
            test_data = $random;
            transmit_data(test_data);
            verify_transmission(test_data);
        end
        
        // Test 4: Busy signal verification
        $display("Test 4: Busy signal verification");
        verify_busy_signal();
        
        // Test 5: Reset functionality
        $display("Test 5: Reset functionality");
        verify_reset();
        
        // Summary
        $display("");
        $display("=== Test Summary ===");
        $display("Total tests: %d", test_count);
        $display("Passed: %d", pass_count);
        $display("Failed: %d", test_count - pass_count);
        
        if (pass_count == test_count) begin
            $display("TEST_PASSED");
        end else begin
            $display("TEST_FAILED");
        end
        
        $finish;
    end
    
    // Task to transmit data
    task transmit_data(input logic [7:0] data);
        begin
            $display("  Transmitting data: 0x%02h (%b)", data, data);
            
            // Wait for transmitter to be idle
            wait(tx_busy == 0);
            @(posedge clk);
            
            // Apply data and enable
            data_in = data;
            data_en = 1;
            @(posedge clk);
            data_en = 0;
            
            // Wait for transmission to complete
            wait(tx_busy == 0);
            @(posedge clk);
        end
    endtask
    
    // Task to verify transmission - FIXED VERSION
    task verify_transmission(input logic [7:0] expected_data);
        begin
            received_data = 0;

            // Wait for start bit (falling edge)
            wait(tx == 0);
            $display("    Start bit detected");

            // Move to middle of start bit, then to middle of bit 0
            repeat(BIT_PERIOD/2) @(posedge clk);  // Half bit - FIXED
            repeat(BIT_PERIOD) @(posedge clk);    // Full bit

            // Sample 8 data bits in the middle of each bit
            for (int i = 0; i < 8; i++) begin
                received_data[i] = tx;  // LSB-first
                $display("    Data bit %0d: %b", i, tx);
                repeat(BIT_PERIOD) @(posedge clk);
            end

            // Sample stop bit mid-bit (optional check)
            $display("    Stop bit: %b", tx);

            // Verify data
            test_count++;
            if (received_data == expected_data) begin
                $display("    ✓ Data verified: 0x%02h", received_data);
                pass_count++;
            end else begin
                $display("    ✗ Data mismatch: expected 0x%02h, got 0x%02h",
                        expected_data, received_data);
            end
            $display("");
        end
    endtask
    
    // Task to verify busy signal
    task verify_busy_signal();
    begin
        $display("  Verifying busy signal behavior");

        // Idle check
        wait (tx_busy == 0);
        if (tx == 1'b1) begin
        $display("    ✓ Idle state correct (tx=1, busy=0)");
        pass_count++;
        end else begin
        $display("    ✗ Idle state incorrect");
        end
        test_count++;

        // Kick a transfer
        data_in = 8'h42;
        data_en = 1;
        @(posedge clk);
        data_en = 0;

        // Wait for transmitter to leave IDLE and assert busy
        @(posedge clk);
        wait (tx_busy == 1);

        if (tx_busy) begin
        $display("    ✓ Busy signal active during transmission");
        pass_count++;
        end else begin
        $display("    ✗ Busy signal not active during transmission");
        end
        test_count++;

        wait (tx_busy == 0);
        $display("");
    end
    endtask

    // Task to verify reset functionality
    task verify_reset();
        begin
            $display("  Verifying reset functionality");
            
            // Start a transmission
            data_in = 8'h33;
            data_en = 1;
            @(posedge clk);
            data_en = 0;
            
            // Apply reset during transmission
            @(posedge clk);
            rstn = 0;
            @(posedge clk);
            
            // Check that transmitter is reset
            if (tx == 1'b1 && tx_busy == 1'b0) begin
                $display("    ✓ Reset successful (tx=1, busy=0)");
                pass_count++;
            end else begin
                $display("    ✗ Reset failed");
            end
            test_count++;
            
            // Release reset
            rstn = 1;
            @(posedge clk);
            $display("");
        end
    endtask

    initial begin
      $dumpfile("tb_transmitter.vcd");
      $dumpvars(0, tb_transmitter);
    end
    
endmodule