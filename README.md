<h1>UART_HUB</h1>
UART hub project for the Tiny-FPGA-B-Series
See: 
http://tinyfpga.com/b-series-guide.html
https://github.com/tinyfpga/TinyFPGA-B-Series

This project contains some simple building block modules for creating a simple UART interface on an FPGA using verilog.

The project currently **WORKS**. However, there is some issue on the UART_TX and UART_RX modules that requires a latch. This latch causes the sythesis to state the design is not guarenteed to work at any clock freq. The project does, however, work at 16MHz on the B2 board. 

<h2>uart.v</h2>
<h3>uart_tx</h3>
<h4>Parameters</h4>
<h6>CLOCK_FREQ</h6>
<p>
Default=16000000 (16MHz)
<p>
The input clock frequency. Used to generate the selected baud rate.
<h6>BAUD</h6>
<p>
Default=9600
<p>
Sets the UART baud rate.
<h6>START_BITS</h6>
<p>
Default=1
<p>
Start bits are the low bits at the beginning of the data frame and when 
combined with stop bits guarentee at least one transition to signal a new bit.
<h6>STOP_BITS</h6>
<p>
Default=1
<p>
Stop bits are the amount of high bits at the end of the data frame.
<h6>PARITY</h6>
<p>
Default=0
<p>
Parity bits are located at the end of the data, before the stop bits. They are
a form of checksum. Not currently implemented in any form.
<h6>WIDTH</h6>
<p>
Default=8
<p>
Width defines the length of the data to be transmitted. It defines the size of
the transmit buffer.
<h4>Ports</h4>
<h5>Inputs</h5>
<h6>clk</h6>
<p>
Size=1 bit
<p>
Input clock signal. Used as clock for flip-flops and for generating the UART's
baud.
<h6>new_data</h6>
<p>
Size=1 bit
<p>
This is a strobe that informs the module that data has been written to the input buffer
and is ready to be sent. This signal should be high for at least one full
clock cycle and must be low before the module is ready to send the next byte to
prevent sending a duplicate byte.
<h6>char</h6>
<p>
Size=WIDTH
<p>
This is the tranmit input buffer. It is of length WIDTH. It must be set to
the correct value before the new_data strobe.
<h5>Outputs</h5>
<h6>rdy</h6>
<p>
Size=1 bit
<p>
This signal is high when the module is ready to recieve new data. This signal
also "or"s with the output to make it high when the module is not active.
<h6>out_bit</h6>
<p>
Size=1 bit
<p>
This is the serial output (TX) of the module.
<h3>uart_rx</h3>
<h4>Parameters</h4>
<h6>CLOCK_FREQ</h6>
<p>
Default=16000000 (16MHz)
<p>
This is the modules clock frequency and is used to determine the speed based on
the baud of the module.
<h6>BAUD</h6>
<p>
Default=9600
<p>
Sets the UART baud rate.
<h6>START_BITS</h6>
<p>
Default=1
<p>
Start bits are the low bits at the beginning of the data frame and when 
combined with stop bits guarentee at least one transition to signal a new bit.
<h6>STOP_BITS</h6>
<p>
Default=1
<p>
Stop bits are the amount of high bits at the end of the data frame.
<h6>PARITY</h6>
<p>
Default=0
<p>
Parity bits are located at the end of the data, before the stop bits. They are
a form of checksum. Not currently implemented in any form.
<h6>WIDTH</h6>
<p>
Default=8
<p>
Width defines the length of the data to be transmitted. It defines the size of
the transmit buffer.
<h4>Ports</h4>
<h5>Inputs</h5>
<h6>clk</h6>
<p>
Size=1 bit
<p>
Input clock signal. Used as clock for flip-flops and for generating the UART's
baud.
<h6>data_in</h6>
<p>
Size=1 bit
<p>
This is the serial data in (RX) for the module.
<h5>Outputs</h5>
<h6>data_out</h6>
<p>
Size=WIDTH
<p>
This is the output register for recieved serial data. This register is 
undefined until the new_data strobe is high.
<h6>new_data</h6>
<p>
Size=1 bit
<p>
This is the output strobe of the module. When it is high, data is ready
to be read from the data_out port. This signal is high for one complete clock
cycle and is directly compatible with the uart_tx module.
<h2>uart_hub.v</h2>
This is the top level module. It is a simple uart passthrough module. Pin13 
serves as a heartbeat to verify the part is working correctly and is not in
bootloader mode. The serial in (RX) is on pin23. Serial out (TX) is on pin22.
<h3>uart_hub</h3>
<h4>Ports</h4>
<h5>Inputs</h5>
<h6>pin3_clk_16mhz</h6>
This signal comes from the resonator on the B2 board and generates the logic
clock.
<h6>pin23</h6>
This pin is the serial in port (RX) for the passthrough.
<h5>Outputs</h5>
<h6>pin1_usb_dp</h6>
Signal not used.
<h6>pin2_usb_dn</h6>
Signal not used.
<h6>pin13</h6>
This pin is the heartbeat for the board. It cycles about once every 1s.
<h6>pin22</h6>
This pin is the serial out port (TX) for the passthrough.

