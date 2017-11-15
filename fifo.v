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

module fifo_buff #(
	parameter LENGTH=16,
	parameter WIDTH=8
)(
	input clk,
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
	reg full_r,empty_r;
	
	assign empty=empty_r;
	assign full=full_r;
	assign data_out=buffer[read_addr[ADD-1:0]];
	//Combinatorial Logic
	always @(*) begin
		if(write_addr==read_addr) empty_r=1;
		else empty_r=0;
		if((write_addr[ADD-1:0]==read_addr[ADD-1:0]) && (write_addr[ADD]!=read_addr[ADD])) full_r=1;
		else full_r=0;	
	end
	
	//Sequential Logic
	always @(negedge clk) begin
		if((~full_r)&&(in_clk)) begin
			buffer[write_addr[ADD-1:0]]<=data_in;
			write_addr<=write_addr+1;
		end
	end

	always @(negedge clk) begin
		if((~empty_r)&&(out_clk)) begin
			
			read_addr<=read_addr+1;
		end
	end
endmodule
