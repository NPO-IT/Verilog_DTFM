module digitalDataOrZeroes (
	input						clk,		//240M
	input						reset,
	
	input						bitBufferEmpty,
	input						bitData,
	output reg				bitAck,
	
	input						dataRq,
	output reg	[11:0]	dataOut,
	output reg				dataReady
);

localparam		WAIT_RQ = 2'd0;
localparam		MAKE_DATA = 2'd1;
localparam		WRITE_DATA = 2'd2;
localparam		SEND_DATA = 2'd3;
localparam		POINTER_START = 4'd11;
localparam		POINTER_END = 4'd1;

reg	[2:0]		rqReg;
wire				rqFront;
always@(posedge clk or negedge reset) begin
	if (~reset) begin rqReg <= 3'b0; end
	else begin rqReg <= { rqReg[1:0],  dataRq }; end
end
assign	rqFront	=	(!rqReg[2] & rqReg[1]);

reg	[1:0]		state;
reg				bitToPut;
reg	[3:0]		pointer;
reg	[1:0]		delay;

always@(posedge clk or negedge reset) begin
	if (~reset) begin
		pointer <= POINTER_START;
		state <= 2'd0;
		bitToPut <= 1'b0;
		delay <= 2'd0;
	end else begin
		case (state)
			WAIT_RQ: if (rqFront) state <= MAKE_DATA;
			MAKE_DATA: begin
				if (!bitBufferEmpty) begin
					bitToPut <= bitData;
					bitAck <= 1'b1;
				end else begin
					bitToPut <= 1'b0;
				end
				state <= WRITE_DATA;
			end
			WRITE_DATA: begin
				bitAck <= 1'b0;
				dataOut[pointer] <= bitToPut;
				pointer <= pointer - 1'b1;
				if (pointer == POINTER_END)
					state <= SEND_DATA;
				else
					state <= MAKE_DATA;
			end
			SEND_DATA: begin
				pointer <= POINTER_START;
				dataReady <= 1'b1;
				delay <= delay + 1'b1;
				if (delay == 2'd3) begin
					state <= WAIT_RQ;
					delay <= 2'd0;
				end
			end
		endcase
	end
end
endmodule
