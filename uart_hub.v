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
	inout pin23,
	//inout pin24
);
	reg [23:0] counter;
	reg [8:0] strobe_c;
	reg strobe;
	always @(posedge pin3_clk_16mhz) counter <= counter + 1;
	always @(posedge u_clk) begin
	       strobe_c<=strobe_c+1; 
	       if(strobe_c[8]) begin
		      strobe<=1;
		      strobe_c<=0;
	      end else strobe<=0;
        end
	wire [7:0] in_bus;
	wire clk;
	wire u_clk;
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
	assign clk = counter[23];
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
	
	uart_clock uart_clock(
		.clk(pin3_clk_16mhz),
		.u_clk(u_clk)
	);
	shift_reg man_shift(
		.clk(u_clk),
		.new_data(strobe),
		.rdy(pin21),
		.char(8'b10110101),
		.out_bit(pin22),
		.clk_out(pin23)
	);
endmodule
module shift_reg(
	input clk,
	input new_data,
	input [7:0] char,
	output rdy,
	output out_bit,
	output clk_out
);
	reg [9:0] byte;
	wire [3:0] shift_d,shift_q;

	//Assignments
	assign out_bit=byte[9]|rdy;

	//Combinatorial Logic
	always @* begin
		if(shift_q>=9) begin
			rdy=1;
			shift_d=shift_q;
		end else begin
			rdy=0;
			shift_d=shift_q+1;
		end
	end

	//Sequential Logic
	always @(posedge clk) begin
		clk_out<=~clk_out;
		shift_q<=shift_d;
		if(new_data&rdy) begin
			byte <= (char<<1)+1'b1; //Shift right to add 1 stop bit
			shift_q<=0;
		end else begin
		       	byte<=byte<<1;
		end
		
	end
endmodule
module uart_clock #(
	parameter CLOCK_FREQ=16000000,
	parameter BAUD=9600
)(
	input clk,
	output u_clk
);
	localparam div=CLOCK_FREQ/BAUD/2;
	reg [14:0] counter;

	//Combinatorial Logic
	always @(*) begin
	end
	//Sequential Logic
	always @(posedge clk) begin
		counter<=counter+1;
		if(counter>=div) begin
			counter<=0;
			u_clk<=~u_clk;
		end
	end
endmodule
