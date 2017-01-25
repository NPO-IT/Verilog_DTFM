module DTFM (
	input clk,
	input dCLK,
	input dFM,
	input dDAT,
	output FRM
);
wire 				rst, clk12, clk20;
globalReset aCLR ( .clk(clk), .rst(rst) );
	defparam aCLR.clockFreq = 1;
	defparam aCLR.delayInSec = 20;

pllMain pll ( .inclk0(clk), .c0(clk12) );

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

always@(posedge clk or negedge rst) begin
	if (~rst) begin syncReg <= 3'b0; end
	else begin syncReg <= { syncReg[1:0],  dFM }; end

	if (~rst) begin clkReg <= 3'b0; end
	else begin clkReg <= { clkReg[1:0],  dCLK }; end
end

assign	syncFront	=	(!syncReg[2] & syncReg[1]);
assign	clkFront		=	(!clkReg[2] & clkReg[1]);
assign	clkRear		=	(clkReg[2] & !clkReg[1]);

//reg	[2:0]		clkReg;
reg				enWriter;
reg				writeBuffer;
wire	[14:0]	bufferUsed;
wire				bufferFull;
wire				bufferEmpty;
wire				readBuffer;
wire				bufferData;
wire	[11:0]	DW_DATA;
wire	[9:0]		DW_ADDR;
wire				DW_WREN;

always@(posedge clk or negedge rst) begin
	if (~rst) begin
		enWriter <= 1'b0;
		writeBuffer <= 1'b0;
	end else begin
		if (syncFront) begin
			enWriter <= 1'b1;
		end
		if (enWriter) begin
			if (clkRear) begin
				writeBuffer <= 1'b1;
			end else begin
				writeBuffer <= 1'b0;
			end
		end
	end
end

bitBuffer bitBuf ( .clock(clk), .data(dDAT), .rdreq(readBuffer), .wrreq(writeBuffer), .empty(bufferEmpty), .full(bufferFull), .q(bufferData), .usedw(bufferUsed));
digitalWriter digitalData ( .clk(clk), .reset(rst), .bitData(bufferData), .bitRequest(readBuffer), .bitLevel(bufferUsed), .orbSwitch(FF_SWCH), .orbWord(DW_DATA), .orbAddr(DW_ADDR), .orbWren(DW_WREN) );
	
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

grpBuffer m0 ( .clock(clk), .data(DW_DATA), .rdaddress(FF_RADR), .rden(m0_RE), .wraddress(DW_ADDR), .wren(m0_WE), .q(m0_DO) );
grpBuffer m1 ( .clock(clk), .data(DW_DATA), .rdaddress(FF_RADR), .rden(m1_RE), .wraddress(DW_ADDR), .wren(m1_WE), .q(m1_DO) );
M8 frameFormer ( .reset(rst), .clk(clk12), .iData(FF_DATA), .oSwitch(FF_SWCH), .oRdEn(FF_RDEN), .oAddr(FF_RADR), .oSerial(FRM) );

endmodule
