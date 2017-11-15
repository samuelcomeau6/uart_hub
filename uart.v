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
	parameter START_BITS=1,
	parameter STOP_BITS=1,
	parameter PARITY=0,
	parameter WIDTH=8
)(
	input clk,
	input new_data,
	input [WIDTH-1:0] char,
	output rdy,
	output out_bit,
	output debug
);
	localparam SIZE=WIDTH+START_BITS+STOP_BITS;
	localparam MAX_ADDR=`CLOG2(SIZE)+1;
	localparam DIV=CLOCK_FREQ/BAUD; //Divider constant, Need to flip twice per bit
	localparam MAX_COUNT=`CLOG2(DIV)+1;
	reg [MAX_COUNT:0] counter; //Clock divider


	reg [SIZE-1:0] byte_d,byte_q; //Byte output
	reg [MAX_ADDR:0] shift_d,shift_q; //Shift counter
	reg rdy_d,rdy_q=1;
	reg [1:0] state_q,state_d;

	localparam READY=2'd0;
	localparam LOAD=2'd1;
	localparam SHIFT=2'd2;

	//Assignments
	assign rdy=rdy_q;
	assign debug=state_q[0]; //FIXME Heisenbug. Don't alter this statement.
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
				if(shift_q>=SIZE) state_d=READY;
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
		if(state_q==LOAD) begin
		       	byte_q<=byte_d;
			counter<=0;
		end
		if(counter>=DIV) begin
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
	parameter PARITY=0,
	parameter WIDTH=8

)(
	input clk,
	input data_in,
	output [WIDTH-1:0] data_out,
	output new_data
);
	localparam CLK_PER_BIT=16000000/9600;
	localparam HCLK_PER_BIT=CLK_PER_BIT/2;
  	localparam MAX_COUNT=`CLOG2(CLK_PER_BIT);
	localparam MAX_ADD=`CLOG2(WIDTH);

	reg new_data_d, new_data_q=1;
	reg data_in_r_d, data_in_r_q=0;
	reg [1:0] state_d, state_q=0;
	reg [MAX_COUNT:0] ctr_d, ctr_q=0;
	reg [MAX_ADD:0] bit_ctr_d, bit_ctr_q=0;
	reg [WIDTH-1:0] data_d, data_q=0;

	assign data_out=data_q;
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
					data_d={data_in_r_q, data_q[1+6-:7]};
					bit_ctr_d=bit_ctr_q + 1;
					ctr_d=0;
					if (bit_ctr_q==7) begin
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
