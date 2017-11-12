UART_HUB
UART hub project for the Tiny-FPGA-B-Series
See: 
http://tinyfpga.com/b-series-guide.html
https://github.com/tinyfpga/TinyFPGA-B-Series

This project contains some simple building block modules for creating a simple UART interface on an FPGA using verilog.

The project currently **WORKS**. However, there is some issue on the UART_TX and UART_RX modules that requires a latch. This latch causes the sythesis to state the design is not guarenteed to work at any clock freq. The project does, however, work at 16MHz on the B2 board. 
