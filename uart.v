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
module uart_tx #(
	parameter CLOCK_FREQ=16000000, //Your FPGAs clock freq B2 boards = 16MHz
	parameter BAUD=9600, //Default baudrate
	parameter START_BITS=1, //Start bits(initial 0)
	parameter STOP_BITS=1, //Stop bits (ending high)
	parameter PARITY=0, //Parity, not yet implemented
	parameter WIDTH=8 //Data width
)(
	input clk, //16MHz clock
	input new_data, //New data strobe, must be high for at least one clk
	input [WIDTH-1:0] char, //Input data to be sent
	output rdy, //High when module is not busy
	output out_bit //serial out
);
	//Definitions
	localparam SIZE=WIDTH+START_BITS+STOP_BITS; //Combined width with start,stop and parity
	localparam MAX_ADDR=`CLOG2(SIZE)+1;
	localparam DIV=CLOCK_FREQ/BAUD; //Divider constant
	localparam MAX_COUNT=`CLOG2(DIV)+1;

	reg [MAX_COUNT:0] counter; //Clock divider
	reg [SIZE-1:0] byte_d,byte_q=8'd0; //Byte output
	reg [MAX_ADDR-1:0] shift_d,shift_q=0; //Shift counter
	reg rdy_d,rdy_q=1; 
	reg [1:0] state_d,state_q=0; //FSM register

	localparam READY=2'd0; 
	localparam LOAD=2'd1;
	localparam SHIFT=2'd2;

	//Assignments
	assign rdy=rdy_q;
	assign out_bit=byte_q[0]|rdy;

	//Combinatorial Logic
	always @* begin
		state_d=state_q;
		shift_d=shift_q;
		byte_d=byte_q;
		rdy_d=rdy_q;
		case(state_q)
			READY: begin
				rdy_d=1;
				shift_d=0;
				if(new_data) begin
					rdy_d=0;
					state_d=LOAD;
				end else state_d=READY;
			end
			LOAD: begin
				rdy_d=0;
				byte_d={{STOP_BITS{1'b1}},char,{START_BITS{1'b0}}};
				shift_d=0;
				state_d=SHIFT;
			end
			SHIFT: begin
				shift_d=shift_q+1;
				byte_d=byte_q>>1;
				if(shift_q>=SIZE-1) state_d=READY;
				else state_d=SHIFT;
			end
			default:begin
				state_d=READY;
			end
		endcase
	end

	//Sequential Logic
	always @(posedge clk) begin
		rdy_q<=rdy_d;
		state_q<=state_d;
		counter<=counter+1;
		if(state_q==LOAD) begin //only do once per transmission
		       	byte_q<=byte_d;
			counter<=0;
		end
		if(counter>=DIV) begin //Shift
			counter<=0;
			byte_q<=byte_d;
			shift_q<=shift_d;
		end
	end
endmodule

module uart_rx #(
	parameter CLOCK_FREQ=16000000, //Your FPGAs clock freq B2 boards = 16MHz
	parameter BAUD=9600, //Default baudrate
	parameter START_BITS=1,
	parameter STOP_BITS=1,
	parameter PARITY=0, //TODO Not yet implemented
	parameter WIDTH=8 //Data width

)(
	input clk,
	input data_in, //Serial in
	output [WIDTH-1:0] data_out,
	output new_data  //High for one full clock cycle when new data is available
);
	localparam CLK_PER_BIT=16000000/9600;
	localparam HCLK_PER_BIT=CLK_PER_BIT/2;
  	localparam MAX_COUNT=`CLOG2(CLK_PER_BIT);
	localparam MAX_ADD=`CLOG2(WIDTH);

	reg new_data_d, new_data_q=0;
	reg data_in_r_d, data_in_r_q=1; //Must be one on start 
	reg [1:0] state_d, state_q=0;
	reg [MAX_COUNT:0] ctr_d, ctr_q=0;
	reg [MAX_ADD:0] bit_ctr_d, bit_ctr_q=0;
	reg [WIDTH:0] data_d, data_q;

	assign data_out=data_q[WIDTH-1:0];
	assign new_data=new_data_q;
	
	always @* begin
	    state_d=state_q;
	    new_data_d=new_data_q;
	    bit_ctr_d=bit_ctr_q;
	    data_d=data_q;
	    data_in_r_d=data_in_r_q;
	    ctr_d=ctr_q;
	    data_in_r_d=data_in;
	    new_data_d=0;
		case (state_q)
			0: begin
				bit_ctr_d=0;
				ctr_d=0;
				if (data_in_r_q==0) begin
					state_d=1;
				end
			end
			1: begin
				ctr_d=ctr_q + 1;
				if (ctr_q==HCLK_PER_BIT) begin
					ctr_d=0;
					state_d=2;
				end
			end
			2: begin
				ctr_d=ctr_q + 1;
				if (ctr_q==CLK_PER_BIT) begin
					if(bit_ctr_q<8) data_d={data_in_r_q, data_q[7-:7]};
					bit_ctr_d=bit_ctr_q + 1;
					ctr_d=0;
					if (bit_ctr_q==8) begin
						state_d=3;
						new_data_d=1;
					end
				end
			end
			3: begin
				if (data_in_r_q==1) begin
					state_d=0;
				end
			end
			default: begin
				state_d=0;
			end
		endcase
	end

	always @(posedge clk) begin
		ctr_q<=ctr_d;
		bit_ctr_q<=bit_ctr_d;
		data_q<=data_d;
		new_data_q<=new_data_d;
		data_in_r_q<=data_in_r_d;
		state_q<=state_d;
	end
endmodule
