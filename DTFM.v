module DTFM (
	input clk,
	input clk80,
	input dCLK,
	input dFM,
	input dDAT,
	output IO_105,
	output FRM
);
wire 				rst, clk12, clk240;
assign 			IO_105 = 1'b0;

globalReset aCLR ( .clk(clk), .rst(rst) );
	defparam aCLR.clockFreq = 1;
	defparam aCLR.delayInSec = 20;

pllMain pll ( .inclk0(clk), .c0(clk12) );
pllRX pll80 ( .inclk0(clk80), .c0(clk240) );

wire				FF_RDEN, FF_SWCH;
wire	[9:0]		FF_RADR;
reg	[11:0]	FF_DATA;
wire	[11:0]	m0_DO, m1_DO;
reg				m0_RE, m1_RE;
reg				m0_WE, m1_WE;

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

reg				writeBuffer;
reg				bitBufferData;
wire	[14:0]	bufferUsed;
wire				bufferFull;
wire				bufferEmpty;
wire				readBuffer;
wire				bufferData;
wire	[11:0]	DW_DATA;
wire	[9:0]		DW_ADDR;
wire				DW_WREN;

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

/*
always@(posedge clk240 or negedge rst) begin	
	if (~rst) begin
		state <= WAIT_MK;
	end else begin
		case(state)
			WAIT_MK: begin
				if(syncFront) state <= WRITE_MARKER;
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
				
			end
			CHECK_CONDITIONS: begin
			end
		endcase
	end
end
*/

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


bitBuffer bitBuf ( .clock(clk240), .data(bitBufferData), .rdreq(readBuffer), .wrreq(writeBuffer), .empty(bufferEmpty), .full(bufferFull), .q(bufferData), .usedw(bufferUsed));

wire digitalDataRequest;
wire [11:0]digitalData;
wire digitalDataReady;

digitalDataOrZeroes dorz( .clk(clk240), .reset(rst), .bitData(bufferData), .bitsUsed(bufferUsed), .bitRequest(readBuffer), 
									.dataRequest(digitalDataRequest), .data(digitalData), .dataReady(digitalDataReady) );

frameFiller orbMaker( .clk(clk80), .reset(rst), .digitalData(digitalData), .digitalDataReady(digitalDataReady), .digitalDataRequest(digitalDataRequest),
								.orbSwitch(FF_SWCH), .orbData(DW_DATA), .orbAddr(DW_ADDR), .orbWrEn(DW_WREN) );

//frameFiller orbMaker( .clk(clk80), .reset(rst), .digitalData(digitalData), .digitalDataReady(digitalDataRequest), .digitalDataRequest(digitalDataRequest),
//								.orbSwitch(FF_SWCH), .orbData(DW_DATA), .orbAddr(DW_ADDR), .orbWrEn(DW_WREN) );
//
//cntFormer testCount(
//	.clock(digitalDataRequest),
//	.q(digitalData) );

always@(*) begin
	case (FF_SWCH)
		0: begin
			m0_RE = FF_RDEN;
			m1_RE = 1'b0;
			m0_WE = 1'b0;
			m1_WE = DW_WREN;
			FF_DATA = m0_DO;
		end
		1: begin
			m1_RE = FF_RDEN;
			m0_RE = 1'b0;
			m0_WE = DW_WREN;
			m1_WE = 1'b0;
			FF_DATA = m1_DO;
		end
	endcase
end

grpBuffer m0 ( .clock(clk80), .data(DW_DATA), .rdaddress(FF_RADR), .rden(m0_RE), .wraddress(DW_ADDR), .wren(m0_WE), .q(m0_DO) );
grpBuffer m1 ( .clock(clk80), .data(DW_DATA), .rdaddress(FF_RADR), .rden(m1_RE), .wraddress(DW_ADDR), .wren(m1_WE), .q(m1_DO) );
M8 frameFormer ( .reset(rst), .clk(clk12), .iData(FF_DATA), .oSwitch(FF_SWCH), .oRdEn(FF_RDEN), .oAddr(FF_RADR), .oSerial(FRM) );

endmodule
