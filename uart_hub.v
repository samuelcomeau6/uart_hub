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
	/*inout pin4,
	inout pin5,
	inout pin6,
	inout pin7,
	inout pin8,
	inout pin9,
	inout pin10,
	inout pin11,
	inout pin12,*/
	output pin13,
	//inout pin14_sdo,
	//inout pin15_sdi,
	//inout pin16_sck,
	//inout pin17_ss,
	//inout pin18,
	//inout pin19,
	//inout pin20,
	inout pin21,
	inout pin22,
	//inout pin23,
	//inout pin24
);
	reg [23:0] counter;//Heartbeat, ignore
	reg [8:0] strobe_c;//Test fixture to isolate single byte FIXME
	reg strobe; //Test fixture FIXME
	always @(posedge pin3_clk_16mhz) counter <= counter + 1; //Heartbeat
	always @(posedge u_clk) begin //To create a single isolated byte FIXME
	       strobe_c<=strobe_c+1; 
	       if(strobe_c[8]) begin
		      strobe<=1;
		      strobe_c<=0;
	      end else strobe<=0;
        end
	wire u_clk;//UART clock, TODO: use dedicated clocking resource
	/// left side of board
	assign pin1_usb_dp = 1'b0;
	assign pin2_usb_dn = 1'b0;
	//assign pin4 = 1'bz;
	//assign pin5 = 1'bz;
	//assign pin6 = 1'bz;
	//assign pin7 = 1'bz;
	//assign pin8 = 1'bz;
	//assign pin9 = 1'bz;
	//assign pin10 = 1'bz;
	//assign pin11 = 1'bz;
	//assign pin12 = 1'bz;
	assign pin13 = counter[23];
	assign in_bus[7] = pin4;
	assign in_bus[6] = pin5;  
	assign in_bus[5] = pin6;  
	assign in_bus[4] = pin7;  
	assign in_bus[3] = pin8;  
	assign in_bus[2] = pin9;  
	assign in_bus[1] = pin10; 
	assign in_bus[0] = pin11; 
	/// right side of board
	//assign pin14_sdo = 1'bz;
	//assign pin15_sdi = 1'bz;
	//assign pin16_sck = 1'bz;
	//assign pin17_ss =  1'bz;
	//assign pin18 =     1'bz;
	//assign pin19 =     1'bz;
	//assign pin20 =     1'bz;
	//assign pin21 =     1'bz;
	//assign pin22 =     1'bz;
	//assign pin23 =     1'bz;
	//assign pin24 =     1'bz;
	
	uart_clock uart_clock( //UART Clock Module see above todo
		.clk(pin3_clk_16mhz),
		.u_clk(u_clk)
	);
	piso_shift_reg_lsb uart_shift( //Parallel in, serial out shift register fitted with start and stop bit
		.clk(u_clk), //TODO: Add rst signal
		.new_data(strobe), //Strobe is above test fixture
		.rdy(pin21), //Signals when ready to recieve new byte
		.char(8'b10110101), //Input signal
		.out_bit(pin22),  //Serial out
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
	reg [SIZE-1:0] byte; //Byte output
	wire [3:0] shift_d,shift_q; //Shift counter

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
			byte <= {{START_BITS{1'b0}},char,{STOP_BITS{1'b1}}}; //Concatenate to add start, stop bits
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
	localparam div=CLOCK_FREQ/BAUD/2; //Divider constant, Need to flip twice per bit
	reg [14:0] counter; //Clock divider

	//Combinatorial Logic
	always @(*) begin
	end
	//Sequential Logic
	always @(posedge clk) begin
		counter<=counter+1;
		if(counter>=div) begin
			counter<=0;
			u_clk<=~u_clk; //Flip the clock
		end
	end
endmodule
