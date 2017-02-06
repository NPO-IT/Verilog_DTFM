module DTFM (
	input		clk,
	input		clk80,
	input		dCLK,
	input		dFM,
	input		dDAT,
	output	IO_105,
	output	FRM
);
wire 				rst, clk12, clk240, clkPWM;
assign 			IO_105 = 1'b0;

globalReset aCLR ( .clk(clk), .rst(rst) );
	defparam aCLR.clockFreq = 1;
	defparam aCLR.delayInSec = 20;

pllMain pll ( .inclk0(clk), .c0(clk12) );
pllRX pll80 ( .inclk0(clk80), .c0(clk240), .c1(clkPWM) );

wire				writeBuffer;
wire				bitBufferData;
wire	[14:0]	bufferUsed;
wire				bufferFull;
wire				bufferEmpty;
wire				readBuffer;
wire				bufferData;
wire				digitalDataRequest;
wire	[11:0]	digitalData;
wire				digitalDataReady;

wire				FF_RDEN, FF_SWCH;
wire	[9:0]		FF_RADR;
reg	[11:0]	FF_DATA;
wire	[11:0]	m0_DO, m1_DO;
reg				m0_RE, m1_RE;
reg				m0_WE, m1_WE;
wire	[11:0]	DW_DATA;
wire	[9:0]		DW_ADDR;
wire				DW_WREN;


digitalReceiver dRX( .clk240(clk240), .rst(rst), .dCLK(dCLK), .dDAT(dDAT), .dFM(dFM),
							.bitBufferData(bitBufferData), .writeBuffer(writeBuffer) );

bitBuffer bitBuf ( .clock(clk240), .data(bitBufferData), .rdreq(readBuffer), .wrreq(writeBuffer), 
							.empty(bufferEmpty), .full(bufferFull), .q(bufferData), .usedw(bufferUsed) );

digitalDataOrZeroes dorz( .clk(clk240), .reset(rst), .bitData(bufferData), .bitsUsed(bufferUsed), .bitRequest(readBuffer), 
									.dataRequest(digitalDataRequest), .data(digitalData), .dataReady(digitalDataReady) );

frameFiller orbMaker( .clk(clk80), .reset(rst), .digitalData(digitalData), .digitalDataReady(digitalDataReady), 
								.digitalDataRequest(digitalDataRequest), .orbSwitch(FF_SWCH), .orbData(DW_DATA), 
								.orbAddr(DW_ADDR), .orbWrEn(DW_WREN) );


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
