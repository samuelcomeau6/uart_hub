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
	output [7:0] d_out,
	output pin13,
	//inout pin14_sdo,
	//inout pin15_sdi,
	//inout pin16_sck,
	//inout pin17_ss,
	//output pin21,
	output pin22,
	input pin23
);
	reg [23:0] counter;//Heartbeat, ignore
	always @(posedge pin3_clk_16mhz) counter <= counter + 1'b1; //Heartbeat
	//assign d_out="S";
	assign pin1_usb_dp = 1'b0;
	assign pin2_usb_dn = 1'b0;
	assign pin13 = counter[23];
	
	wire full,empty,rdy;
	wire rx_new_data;
	wire [7:0] rx_data;
	wire [7:0] tx_data;
	/*reg [8:0] msg[14:0];
	initial begin
	       msg[0]<="H";msg[1]<="e";msg[2]<="l";msg[3]<="l";msg[4]<="o";msg[5]<=" ";msg[6]<="W";msg[7]<="o";
	       msg[8]<="r";msg[9]<="l";msg[10]<="d";msg[11]<="!";msg[12]<=8'h0D;msg[13]<=8'h0A;msg[14]<=8'h00;
	end*/
	uart_tx uart_tx1( //Parallel in, serial out shift register fitted with start and stop bit
		.clk(pin3_clk_16mhz),
		.new_data(rx_new_data), //Keep transmitting until fifo is empty
		.char(rx_data), //Input signal
		.rdy(rdy), //Ready for new data 		
		.out_bit(pin22),  //Serial out
		.debug(d_out)
	);
/*	fifo_buff fifo_buff(
		.clk(pin3_clk_16mhz),
		.in_clk(rx_new_data),
		.data_in(rx_data),
		.out_clk(rdy),
		.data_out(tx_data),
		.empty(empty),
		.full(full)
	);*/
	uart_rx uart_rx1(
		.clk(pin3_clk_16mhz),
		.data_in(pin23),
		.data_out(rx_data),
		.new_data(rx_new_data)
	);

endmodule

