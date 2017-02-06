module digitalReceiver(
	input						clk240,
	input						rst,
	input 					dCLK,
	input 					dDAT,
	input 					dFM,
	output reg				bitBufferData,
	output reg				writeBuffer
);
// read data to output by the rear dClk
// clear all counters and variables by front sync
reg	[2:0]		syncReg;
reg	[2:0]		clkReg;
wire				syncFront;
wire				clkFront;
wire				clkRear;

always@(posedge clk240 or negedge rst) begin
	if (~rst) begin syncReg <= 3'b0; end
	else begin syncReg <= { syncReg[1:0],  dFM }; end

	if (~rst) begin clkReg <= 3'b0; end
	else begin clkReg <= { clkReg[1:0],  dCLK }; end
end

assign	syncFront	=	(!syncReg[2] & syncReg[1]);
assign	clkRear		=	(clkReg[2] & !clkReg[1]);

localparam		WAIT_MK = 2'd0;
localparam		WRITE_MARKER = 2'd1;
localparam		WRITE_DATA = 2'd2;
localparam		CHECK_CONDITIONS = 2'd3;

wire	[30:0]	M 	=	31'b1111100110100100001010111011000;
wire	[30:0]	nM	=	31'b0000011001011011110101000100111;
wire	[12:0]	B	=	13'b1111100110101;
wire	[12:0]	nB	=	13'b0000011001010;
wire	[43:0]	mark	[0:3];
assign	mark[0]	=	{ M,	B	};
assign	mark[1]	=	{ nM,	B	};
assign	mark[2]	=	{ M,	nB	};
assign	mark[3]	=	{ nM,	nB	};

reg	[1:0]		state;
reg	[1:0]		markerNumber;
reg	[5:0]		pMark;
reg	[2:0]		mSeq;
reg	[43:0]	marker;
reg	[14:0]	bitsWritten;
reg	[11:0]	cntMarker;

always@(posedge clk240 or negedge rst) begin
	if (~rst) begin
		writeBuffer <= 1'b0;
		state <= WAIT_MK;
		bitBufferData <= 1'b1;
		pMark <= 6'd43;
		mSeq <= 3'd0;
		markerNumber <= 2'b0;
		marker <= 44'b0;
		bitsWritten <= 15'b0;
		cntMarker <= 12'd0;
	end else begin
		case(state)
			WAIT_MK: begin
				if (syncFront) begin
					state <= WRITE_MARKER;
					markerNumber <= 2'b0;
					cntMarker <= 12'b0;
					bitsWritten <= 15'd0;
					pMark <= 6'd43;
					mSeq <= 3'd0;
				end
			end
			WRITE_MARKER: begin
				mSeq <= mSeq + 1'b1;
				case (mSeq)
					0: marker <= mark[markerNumber];
					1: begin
						if (pMark == 6'd63) begin
							pMark <= 6'd43;
							mSeq <= 3'd0;
							markerNumber <= markerNumber + 1'b1;
							state <= WRITE_DATA;
						end else begin
							bitBufferData <= marker[pMark];
							writeBuffer <= 1'b1;
						end
					end
					2: begin
						writeBuffer <= 1'b0;
						pMark <= pMark - 1'b1;
						mSeq <= 1'b1;
					end
				endcase
			end
			WRITE_DATA: begin
				if (bitsWritten == 15'd10240) begin
					state <= WAIT_MK;
					writeBuffer <= 1'b0;
				end else begin
					if (clkRear) begin
						bitsWritten <= bitsWritten + 1'b1;
						cntMarker <= cntMarker + 1'b1;
						bitBufferData <= dDAT;
						writeBuffer <= 1'b1;
					end else begin
						writeBuffer <= 1'b0;
						if(cntMarker == 12'd2816) begin
							cntMarker <= 12'b0;
							state <= WRITE_MARKER;
						end
					end
				end
			end
		endcase
	end
end

endmodule
