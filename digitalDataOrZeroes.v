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

reg	[1:0]		state;
reg	[2:0]		seq;
reg				bitToWrite;
reg	[3:0]		pointer;
reg	[2:0]		cntVal;

localparam		WAIT_RQ = 2'd0;
localparam		WRITE_DATA = 2'd1;
localparam		SEND_DATA = 2'd2;

localparam		POINTER_START = 4'd11;
localparam		POINTER_END = 4'd0;

always@(posedge clk or negedge reset) begin
	if (~reset) begin
		pointer <= POINTER_START;
		state <= 2'd0;
		seq <= 3'd0;
		bitToWrite <= 1'b0;
		bitRequest = 1'b0;
		data <= 12'd0;
		dataReady <= 1'b0;
		cntVal <= 3'd0;
	end else begin
		case (state)
			WAIT_RQ: begin
				if (rqFront) state <= WRITE_DATA;
			end
			WRITE_DATA: begin
				seq <= seq + 1'b1;
				case(seq)
					0: begin
						if (!bitBufEmpty) begin
							bitToWrite <= bitData;
							bitRequest <= 1'b1;
						end else begin
							bitToWrite <= 1'b0;
						end
					end
					1: begin
						bitRequest <= 1'b0;
						data[pointer] <= bitToWrite;
						pointer <= pointer - 1'b1;
					end
					2: begin
						if (pointer == POINTER_END) begin
							pointer <= POINTER_START;
							seq <= 3'd0;
							state <= SEND_DATA;
						end else begin
							seq <= 3'd0;
						end
					end
				endcase
			end
			SEND_DATA: begin
				if (cntVal < 3'd6) begin 			//long WrEn here, even longer if needed
					dataReady <= 1'b1;
					cntVal <= cntVal + 1'b1;
				end else begin
					cntVal <= 3'd0;
					dataReady <= 1'b0;
					state <= WAIT_RQ;
				end
			end
		endcase
	end
end
endmodule
