// Copyright Refringence
// Built with Refringence IDE — https://refringence.com
# Clock definition (50 MHz example)
create_clock -name sys_clk -period 20.000 [get_ports {clk_50mhz}]

# I/O delays (tune as needed for your board)
set_input_delay  -clock [get_clocks sys_clk] 2.0  [get_ports {uart_rx}]
set_output_delay -clock [get_clocks sys_clk] 2.0  [get_ports {uart_tx}]
set_output_delay -clock [get_clocks sys_clk] 2.0  [get_ports {seg[*]}]
set_output_delay -clock [get_clocks sys_clk] 2.0  [get_ports {an[*]}]
set_output_delay -clock [get_clocks sys_clk] 2.0  [get_ports {led[*]}]

# Async reset: tell the tools it’s asynchronous to the clock
set_false_path -from [get_ports {rstn_btn}] -to [get_clocks sys_clk]

# Pin assignments are usually done in the .qsf (Quartus) or .xdc (Xilinx).
# For Quartus, put these in your .qsf (example placeholders):
# set_location_assignment PIN_<X> -to clk_50mhz
# set_location_assignment PIN_<Y> -to uart_rx
# set_location_assignment PIN_<Z> -to uart_tx
# set_location_assignment PIN_<...> -to seg[0]
# set_location_assignment PIN_<...> -to an[0]
# set_location_assignment PIN_<...> -to led[0]