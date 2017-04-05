module digitalDataOrZeroes (
	input						clk,		//240M
	input						reset,
	
	input						bitData,
	input						bitBufEmpty,
	output reg				bitRequest,
	
	input						dataRequest,
	output reg	[11:0]	data,
	output reg				dataReady
);

reg	[2:0]		rqReg;
wire				rqFront;
always@(posedge clk or negedge reset) begin
	if (~reset) begin rqReg <= 3'b0; end
	else begin rqReg <= { rqReg[1:0],  dataRequest }; end
end
assign	rqFront	=	(!rqReg[2] & rqReg[1]);

localparam		POINTER_START = 4'd11;
localparam		POINTER_END = 4'd1;

reg	[2:0]		state;
reg	[2:0]		seq;
reg				bitToWrite;
reg	[3:0]		pointer;
reg	[2:0]		cntVal;
reg				isZeros;

localparam		WAIT_RQ = 3'd0;
localparam		PICK_BUFFER = 3'd1;
localparam		PICK_ZEROS = 3'd2;
localparam		WRITE_DATA = 3'd3;
localparam		GIVE_WORD = 3'd4;
localparam		CHECK_ZEROS = 3'd5;


always@(posedge clk or negedge reset) begin
	if (~reset) begin
		pointer <= POINTER_START;
		state <= WAIT_RQ;
		seq <= 3'd0;
		bitToWrite <= 1'b0;
		bitRequest = 1'b0;
		data <= 12'd0;
		dataReady <= 1'b0;
		cntVal <= 3'd0;
		isZeros <= 1'b0;
	end else begin
		case (state)
			WAIT_RQ: begin
				isZeros <= 1'b0;
				pointer <= POINTER_START;
				cntVal <= 3'd0;
				dataReady <= 1'b0;
				if (rqFront) begin
					bitToWrite <= 1'b0;
					state <= PICK_BUFFER;
				end
			end
			PICK_BUFFER: begin
				if (bitBufEmpty)begin
					state <= PICK_ZEROS;
				end else begin
					bitToWrite <= bitData;
					bitRequest <= 1'b1;
					state <= WRITE_DATA;
				end
			end
			PICK_ZEROS: begin
				bitToWrite <= 1'b0;
				isZeros <= 1'b1;
				state <= WRITE_DATA;
			end
			WRITE_DATA: begin
				bitRequest <= 1'b0;
				data[pointer] <= bitToWrite;
				pointer <= pointer - 1'b1;
				if (pointer == POINTER_END) begin
					state <= GIVE_WORD;
				end else begin
					state <= CHECK_ZEROS;
				end
			end
			GIVE_WORD: begin
				pointer <= POINTER_START;
				if (cntVal < 3'd4) begin
					dataReady <= 1'b1;
					cntVal <= cntVal + 1'b1;
				end else begin
					cntVal <= 3'd0;
					dataReady <= 1'b0;
					state <= WAIT_RQ;
				end
			end
			CHECK_ZEROS: begin
				if(isZeros == 1'b1) begin
					state <= PICK_ZEROS;
				end else begin
					state <= PICK_BUFFER;
				end
			end
		endcase
	end
end
endmodule
