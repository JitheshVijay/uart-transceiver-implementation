// Copyright Refringence
// Built with Refringence IDE — https://refringence.com
module binary_to_7seg #(
    parameter COMMON_ANODE = 1  // 1 for common anode, 0 for common cathode
)(
    input  logic [3:0] binary_in,    // 4-bit binary input (0-9)
    output logic [6:0] seg_out       // 7-segment output (a,b,c,d,e,f,g)
);

    // 7-segment patterns for digits 0-9
    // seg_out[6:0] = {g, f, e, d, c, b, a}
    always_comb begin
        case (binary_in)
            4'd0: seg_out = 7'b1000000;  // 0
            4'd1: seg_out = 7'b1111001;  // 1
            4'd2: seg_out = 7'b0100100;  // 2
            4'd3: seg_out = 7'b0110000;  // 3
            4'd4: seg_out = 7'b0011001;  // 4
            4'd5: seg_out = 7'b0010010;  // 5
            4'd6: seg_out = 7'b0000010;  // 6
            4'd7: seg_out = 7'b1111000;  // 7
            4'd8: seg_out = 7'b0000000;  // 8
            4'd9: seg_out = 7'b0010000;  // 9
            default: seg_out = 7'b1111111; // All segments off for invalid input
        endcase
        
        // Invert for common cathode displays
        if (!COMMON_ANODE) begin
            seg_out = ~seg_out;
        end
    end

endmodule