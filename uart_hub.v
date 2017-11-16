///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
///
/// Top-Level Verilog Module
///
/// Only include pins the design is actually using.  Make sure that the pin is
/// given the correct direction: input vs. output vs. inout
///
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
module uart_hub (
	output pin1_usb_dp,
	output pin2_usb_dn,
	input pin3_clk_16mhz,
	output pin13,
	output pin22,
	input pin23
);
	reg [23:0] counter;//Heartbeat, ignore
	always @(posedge pin3_clk_16mhz) counter <= counter + 1'b1; //Heartbeat
	assign pin1_usb_dp = 1'b0;
	assign pin2_usb_dn = 1'b0;
	assign pin13 = counter[23];
	
	reg rdy;
	reg rx_new_data;
	reg [7:0] rx_data;
	/*reg [8:0] msg[14:0];
	initial begin
	       msg[0]<="H";msg[1]<="e";msg[2]<="l";msg[3]<="l";msg[4]<="o";msg[5]<=" ";msg[6]<="W";msg[7]<="o";
	       msg[8]<="r";msg[9]<="l";msg[10]<="d";msg[11]<="!";msg[12]<=8'h0D;msg[13]<=8'h0A;msg[14]<=8'h00;
	end*/
	uart_tx uart_tx1 ( //Parallel in, serial out shift register fitted with start and stop bit
		.clk(pin3_clk_16mhz),
		.new_data(rx_new_data), //Keep transmitting until fifo is empty
		.char(rx_data), //Input signal
		.rdy(rdy), //Ready for new data 		
		.out_bit(pin22)  //Serial out
	);
	uart_rx uart_rx1i (
		.clk(pin3_clk_16mhz),
		.data_in(pin23),
		.data_out(rx_data),
		.new_data(rx_new_data)
	);

endmodule

