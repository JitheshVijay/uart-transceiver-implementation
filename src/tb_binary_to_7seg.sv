// Copyright Refringence
// Built with Refringence IDE — https://refringence.com
module tb_binary_to_7seg;
    
    // Signals
    logic [3:0] binary_in;
    logic [6:0] seg_out;
    
    // Instantiate DUT
    binary_to_7seg dut (
        .binary_in(binary_in),
        .seg_out(seg_out)
    );
    
    // Test variables
    integer test_count;
    integer pass_count;
    
    // Main test sequence
    initial begin
        $display("=== Binary-to-7-Segment Converter Testbench ===");
        $display("");
        
        test_count = 0;
        pass_count = 0;
        
        // Test all digits 0-9
        for (int i = 0; i < 10; i++) begin
            test_digit(i);
        end
        
        // Test invalid input
        test_invalid_input();
        
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
    
    // Task to test a specific digit
    task test_digit(input logic [3:0] digit);
        begin
            binary_in = digit;
            #10; // Wait for propagation
            
            $display("Testing digit %d: binary_in=%b, seg_out=%b", 
                    digit, binary_in, seg_out);
            
            // Verify the pattern
            test_count++;
            if (verify_pattern(digit, seg_out)) begin
                $display("  ✓ Pattern correct");
                pass_count++;
            end else begin
                $display("  ✗ Pattern incorrect");
            end
        end
    endtask
    
    // Task to test invalid input
    task test_invalid_input();
        begin
            binary_in = 4'b1010; // Invalid input (10)
            #10;
            
            $display("Testing invalid input: binary_in=%b, seg_out=%b", 
                    binary_in, seg_out);
            
            test_count++;
            if (seg_out == 7'b1111111) begin
                $display("  ✓ Invalid input handled correctly (all segments off)");
                pass_count++;
            end else begin
                $display("  ✗ Invalid input not handled correctly");
            end
        end
    endtask
    
    // Function to verify 7-segment pattern
    function automatic logic verify_pattern(input logic [3:0] digit, input logic [6:0] pattern);
        begin
            case (digit)
                4'd0: return (pattern == 7'b1000000);
                4'd1: return (pattern == 7'b1111001);
                4'd2: return (pattern == 7'b0100100);
                4'd3: return (pattern == 7'b0110000);
                4'd4: return (pattern == 7'b0011001);
                4'd5: return (pattern == 7'b0010010);
                4'd6: return (pattern == 7'b0000010);
                4'd7: return (pattern == 7'b1111000);
                4'd8: return (pattern == 7'b0000000);
                4'd9: return (pattern == 7'b0010000);
                default: return 0;
            endcase
        end
    endfunction

    initial begin
      $dumpfile("tb_binary_to_7seg.vcd");
      $dumpvars(0, tb_binary_to_7seg);
    end
    
endmodule

