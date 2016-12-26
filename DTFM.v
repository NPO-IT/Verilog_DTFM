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

pllMain pll ( .inclk0(clk), .c0(clk12), .c1(clk20) );

wire				FF_RDEN, FF_SWCH;
wire	[9:0]		FF_RADR;
reg	[11:0]	FF_DATA;
wire	[11:0]	m0_DO, m1_DO;
reg				m0_RE, m1_RE;
reg				m0_WE, m1_WE;


always@(*) begin
	case (FF_SWCH)
		0: begin
			m0_RE = FF_RDEN;
			m1_RE = 1'b0;
			FF_DATA = m0_DO;
		end
		1: begin
			m1_RE = FF_RDEN;
			m0_RE = 1'b0;
			FF_DATA = m1_DO;
		end
	endcase
end

grpBuffer m0 ( .clock(clk), .data(0), .rdaddress(FF_RADR), .rden(m0_RE), .wraddress(0), .wren(m0_WE), .q(m0_DO) );
grpBuffer m1 ( .clock(clk), .data(0), .rdaddress(FF_RADR), .rden(m1_RE), .wraddress(0), .wren(m1_WE), .q(m1_DO) );
M8 frameFormer ( .reset(rst), .clk(clk12), .iData(FF_DATA), .oSwitch(FF_SWCH), .oRdEn(FF_RDEN), .oAddr(FF_RADR), .oSerial(FRM) );

endmodule
