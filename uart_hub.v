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
`define CLOG2(x) \
   (x <= 2) ? 1 : \
   (x <= 4) ? 2 : \
   (x <= 8) ? 3 : \
   (x <= 16) ? 4 : \
   (x <= 32) ? 5 : \
   (x <= 64) ? 6 : \
   (x <= 128) ? 7 : \
   (x <= 256) ? 8 : \
   (x <= 512) ? 9 : \
   (x <= 1024) ? 10 : \
   (x <= 2048) ? 11 : \
   (x <= 4096) ? 12 : \
   (x <= 8192) ? 13 : \
   (x <= 16384) ? 14 : \
   (x <= 32768) ? 15 : \
   (x <= 65536) ? 16 : \
   -1
module uart_hub (
	output pin1_usb_dp,
	output pin2_usb_dn,
	input pin3_clk_16mhz,
	output pin13,
	//inout pin14_sdo,
	//inout pin15_sdi,
	//inout pin16_sck,
	//inout pin17_ss,
	inout pin22
);
	reg [23:0] counter;//Heartbeat, ignore
	always @(posedge pin3_clk_16mhz) counter <= counter + 1; //Heartbeat
	
	assign pin1_usb_dp = 1'b0;
	assign pin2_usb_dn = 1'b0;
	assign pin13 = counter[23];
	
	reg [3:0] data;
	wire full;
	wire data_strobe;
	reg [8:0] msg[14:0];
	initial begin
	       msg[0]="H";msg[1]="e";msg[2]="l";msg[3]="l";msg[4]="o";msg[5]=" ";msg[6]="W";msg[7]="o";
	       msg[8]="r";msg[9]="l";msg[10]="d";msg[11]="!";msg[12]=8'h0D;msg[13]=8'h0A;msg[14]=8'h00;
	end
	always @(posedge pin3_clk_16mhz) begin
		if(~full&~data_strobe) begin
			if(data<14) data<=data+1;
			else data<=0;
			data_strobe<=1;
		end else data_strobe<=0;
	end
	uart_tx uart_tx1(
		.clk(pin3_clk_16mhz),
		.data_in(msg[data]),
		.data_strobe(data_strobe),
		.data_out(pin22),
		.full(full)
	);

endmodule
module uart_tx(
	input clk,
	input [7:0] data_in,
	input data_strobe,
	output data_out,
	output full
);
	wire [7:0] data;
	wire rdy;
	wire empty;
		
	fifo_buff fifo_buff(
		.in_clk(data_strobe),
		.data_in(data_in),
		.out_clk(rdy),
		.data_out(data),
		.empty(empty),
		.full(full)
	);
	uart_clock uart_clock( //UART Clock Module see above todo
		.clk(clk),
		.u_clk(u_clk)
	);
	piso_shift_reg_lsb uart_shift( //Parallel in, serial out shift register fitted with start and stop bit
		.clk(u_clk),
		.new_data(~empty), //Strobe is above test fixture
		.char(data), //Input signal
		.rdy(rdy),		
		.out_bit(data_out)  //Serial out
	);
endmodule
module piso_shift_reg_lsb #(
	parameter START_BITS=1,
	parameter STOP_BITS=1,
	parameter PARITY=0,
	parameter WIDTH=8
)(
	input clk,
	input new_data,
	input [WIDTH-1:0] char,
	output rdy,
	output out_bit
);
	localparam SIZE=WIDTH+START_BITS+STOP_BITS;
	localparam MAX_COUNT=`CLOG2(SIZE);
	reg [SIZE-1:0] byte; //Byte output
	wire [MAX_COUNT:0] shift_d,shift_q; //Shift counter

	//Assignments
	assign out_bit=byte[0]|rdy; //LSB bit last, leave line high when idle

	//Combinatorial Logic
	always @* begin
		if(shift_q>=(SIZE-1)) begin //For 10 bits, only 9 shifts are needed
			rdy=1; //Finished shifting, ready for more
			shift_d=shift_q; //Stop counting shifts
		end else begin
			rdy=0; //Shifting, not ready
			shift_d=shift_q+1; //Increment shift flip flop on next clk
		end
	end

	//Sequential Logic
	always @(posedge clk) begin
		shift_q<=shift_d; //FF clock
		if(new_data&rdy) begin //If there is new data and the device is ready, bring it in
			byte <= {{STOP_BITS{1'b1}},char,{START_BITS{1'b0}}}; //Concatenate to add start, stop bits
			shift_q<=0; //Reset shift counter (was left at max)
		end else begin
		       	byte<=byte>>1; //Shift 1 bit
		end
		
	end
endmodule
module uart_clock #(
	parameter CLOCK_FREQ=16000000, //Your FPGAs clock freq B2 boards = 16MHz
	parameter BAUD=9600 //Default baudrate
)(
	input clk, //System clock
	output u_clk //Pulses one per bit
);
	localparam DIV=CLOCK_FREQ/BAUD/2; //Divider constant, Need to flip twice per bit
	localparam MAX_COUNT=`CLOG2(DIV);
	reg [MAX_COUNT:0] counter; //Clock divider


	//Combinatorial Logic
	always @(*) begin
	end
	//Sequential Logic
	always @(posedge clk) begin
		counter<=counter+1;
		if(counter>=DIV) begin
			counter<=0;
			u_clk<=~u_clk; //Flip the clock
		end
	end
endmodule
module fifo_buff #(
	parameter LENGTH=16,
	parameter WIDTH=8,
)(
	input [WIDTH-1:0] data_in,
	input in_clk,
	input out_clk,
	output [WIDTH-1:0] data_out,
	output full,
	output empty
);
	localparam ADD=1+`CLOG2(LENGTH);
	
	//Defines
	reg [WIDTH-1:0] buffer [LENGTH-1:0];
	reg [ADD:0] write_addr,read_addr;
	
	//Assignments
	assign data_out=buffer[read_addr[ADD-1:0]];
	initial begin
		//full=0;
		//empty=1;
	end	
	//Combinatorial Logic
	always @(*) begin
		if(write_addr==read_addr) empty=1;
		else empty=0;
		if((write_addr[ADD-1:0]==read_addr[ADD-1:0]) && (write_addr[ADD]!=read_addr[ADD])) full=1;
		else full=0;	
	end
	
	//Sequential Logic
	always @(posedge in_clk) begin
		if(~full) begin
			buffer[write_addr[ADD-1:0]]<=data_in;
			write_addr<=write_addr+1;
		end
	end

	always @(posedge out_clk) begin
		if(~empty) read_addr<=read_addr+1;
	end
endmodule
