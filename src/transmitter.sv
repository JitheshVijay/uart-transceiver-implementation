// Copyright Refringence
// Built with Refringence IDE — https://refringence.com
module transmitter #(
    parameter CLOCKS_PER_PULSE = 16
)(
    input  logic        clk,
    input  logic        rstn,
    input  logic [7:0]  data_in,
    input  logic        data_en,
    output logic        tx,
    output logic        tx_busy
);

    // State machine states
    typedef enum logic [2:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;
    
    state_t current_state, next_state;
    
    // Internal signals
    logic [7:0]  data_reg;
    logic [3:0]  bit_counter;
    logic [15:0] clk_counter;
    logic        bit_timer_done;
    
    // Clock counter for bit timing
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            clk_counter <= 0;
        end else begin
            if (current_state == IDLE) begin
                clk_counter <= 0;
            end else if (clk_counter == CLOCKS_PER_PULSE - 1) begin
                clk_counter <= 0;
            end else begin
                clk_counter <= clk_counter + 1;
            end
        end
    end
    
    // Bit timer done signal
    assign bit_timer_done = (clk_counter == CLOCKS_PER_PULSE - 1);
    
    // State machine
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end
    
    // Next state logic
    always_comb begin
        next_state = current_state;
        
        case (current_state)
            IDLE: begin
                if (data_en) begin
                    next_state = START;
                end
            end
            
            START: begin
                if (bit_timer_done) begin
                    next_state = DATA;
                end
            end
            
            DATA: begin
                if (bit_timer_done && bit_counter == 7) begin
                    next_state = STOP;
                end
            end
            
            STOP: begin
                if (bit_timer_done) begin
                    next_state = IDLE;
                end
            end
        endcase
    end
    
    // Data register
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            data_reg <= 0;
        end else if (data_en && current_state == IDLE) begin
            data_reg <= data_in;
        end
    end
    
    // Bit counter
    always_ff @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            bit_counter <= 0;
        end else begin
            case (current_state)
                IDLE: begin
                    bit_counter <= 0;
                end
                
                DATA: begin
                    if (bit_timer_done) begin
                        if (bit_counter == 7) begin
                            bit_counter <= 0;
                        end else begin
                            bit_counter <= bit_counter + 1;
                        end
                    end
                end
                
                default: begin
                    bit_counter <= bit_counter;
                end
            endcase
        end
    end
    
    // Output logic
    always_comb begin
        case (current_state)
            IDLE: begin
                tx = 1'b1;
            end
            
            START: begin
                tx = 1'b0;
            end
            
            DATA: begin
                tx = data_reg[bit_counter];
            end
            
            STOP: begin
                tx = 1'b1;
            end
            
            default: begin
                tx = 1'b1;
            end
        endcase
    end
    
    // Busy flag
    assign tx_busy = (current_state != IDLE);
    
endmodule