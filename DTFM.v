module DTFM (
	input		clk,
	input		clk80,
	input		dCLK,
	input		dFM,
	input		dDAT,
	output	IO_105,
	output	FRM,
	
	output ADC_SCLK,
	output ADC_nCS,
	input ADC_SDATA,
	
	output PWM,
	output FunFrequency,
	
	output pin50,
	output pin52,
	output pin54,
	output pin73,
	output pin75,
	output pin77,
	
	output pin53,
	
	output pin83,
	output pin84,
	
	output	EN1,
	output	A01,
	output	A11,
	output	A21,
	output	EN2,
	output	A02,
	output	A12,
	output	A22,
	output	EN3,
	output	A03,
	output	A13,
	output	A23
);
wire 				rst, clk12, clk240, clkPWM;		//pwm10M
wire				UART_CLK, UART;
assign 			IO_105 = 1'b1;
assign			EN1 = 1'b1;
assign			EN2 = 1'b1;
assign			EN3 = 1'b1;

globalReset aCLR ( .clk(clk), .rst(rst) );
	defparam aCLR.clockFreq = 1;
	defparam aCLR.delayInSec = 20;

pllMain pll ( .inclk0(clk), .c0(clk12), .c1(requestADC) );
pllRX pll80 ( .inclk0(clk80), .c1(clkPWM), .c2(FunFrequency), .c3(UART_CLK));

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
wire	[11:0]	ADC_data;
wire				ADC_valid;
wire	[4:0]		ADC_address;
wire	[11:0]	ADC_d;
wire				ADC_v;
wire	[11:0]	ADC_POWER;
wire	[11:0]	analogData;
wire				analogDataRequest;
wire				p_val;


//Analog Data
wire [2:0] muxA3;
wire [2:0] muxA12;

assign A01 = muxA12[0];
assign A11 = muxA12[1];
assign A21 = muxA12[2];
assign A02 = muxA12[0];
assign A12 = muxA12[1];
assign A22 = muxA12[2];
assign A03 = muxA3[0];
assign A13 = muxA3[1];
assign A23 = muxA3[2];

switcher ADCswMUX ( .reset(rst), .clk(clk80), .spiReceived(ADC_valid),
	.MxA3(muxA3), .MxA12(muxA12), .rxAddress(ADC_address) 
);

receiverSPI ADCrxreceiverSPI ( .clk(clk80), .reset(rst), .dataRequest(requestADC),
	.DAT(ADC_SDATA), .nCS(ADC_nCS), .CLK(ADC_SCLK),
	.spiData(ADC_data), .spiReady(ADC_valid)
);
defparam ADCrxreceiverSPI.SLAVE_DELAY = 6'd10;

distributor analog_distributor ( .clk(clk80), .reset(rst),
	.data(12'd4095 - ADC_data), .valid(ADC_valid), .address(ADC_address),
	.fData(ADC_d), .fRdEn(ADC_v), .power(ADC_POWER), .pwr_chng(p_val)
);
defparam analog_distributor.IGNORED_CHANNEL = 5'd1;

analogBuffer fifoAN ( .clock(clk80), .data(ADC_d), .wrreq(ADC_v), 
								.rdreq(analogDataRequest),	.q(analogData) );

//POWER contol

wire [6:0] duty;

assign pin53 = ADC_POWER[6];
assign pin52 = ADC_POWER[7];
assign pin54 = ADC_POWER[8];
assign pin73 = ADC_POWER[9];
assign pin75 = ADC_POWER[10];
assign pin77 = ADC_POWER[11];

PowerController p_ctrl(
	.clk(p_val),
	.reset(rst),
	.curr_pwr(ADC_POWER[11:4]),
	.duty(duty)
);

PWM pwm (
	.clk(clkPWM),
	.reset(rst),
	.duty(duty),
	.out(PWM)
);

//Digital Data
wire				writeBuffer;
reg				writeBuffer0;
reg				writeBuffer1;
wire				bitBufferData;
reg				bufferEmpty;
wire				bufferEmpty0;
wire				bufferEmpty1;
wire				readBuffer;
reg				readBuffer0;
reg				readBuffer1;
reg				bufferData;
wire				bufferData0;
wire				bufferData1;
wire				RX_SWCH;
wire				flush;
reg				flush0;
reg				flush1;

always@(*) begin
	case (RX_SWCH)
		0: begin
			bufferData <= bufferData0;
			bufferEmpty <= bufferEmpty0;
			readBuffer0 <= readBuffer;
			readBuffer1 <= 1'b0;
			writeBuffer0 <= 1'b0;
			writeBuffer1 <= writeBuffer;
			flush1 <= flush;
			flush0 <= 1'b0;
		end
		1: begin
			bufferData <= bufferData1;
			bufferEmpty <= bufferEmpty1;
			readBuffer1 <= readBuffer;
			readBuffer0 <= 1'b0;
			writeBuffer1 <= 1'b0;
			writeBuffer0 <= writeBuffer;
			flush0 <= flush;
			flush1 <= 1'b0;
		end
	endcase
end

wire sendUART;
wire [7:0] sendDATA;
assign pin50 = UART;
UARTTX u_tx( .reset(rst), .clk(UART_CLK), .RQ(sendUART), .data(sendDATA), .tx(UART) );

inMonitor im (.reset(rst), .clk(clk80), .dMK(dFM), 
					.inBit(bitBufferData), .inVal(writeBuffer),
					.sendUART(sendUART), .data(sendDATA)
);

RXandCTRL dRX( .reset(rst), .clk(clk80), .dMK(dFM), .dCLK(dCLK), .dDAT(dDAT),
				.bit(bitBufferData), .val(writeBuffer), .swch(RX_SWCH), .flush(flush)
);

bitBuffer bitBuf0 ( .clock(clk80), .data(bitBufferData), .rdreq(readBuffer0), .wrreq(writeBuffer0), 
							.empty(bufferEmpty0), .q(bufferData0), .sclr(flush0) );
							
bitBuffer bitBuf1 ( .clock(clk80), .data(bitBufferData), .rdreq(readBuffer1), .wrreq(writeBuffer1), 
							.empty(bufferEmpty1), .q(bufferData1), .sclr(flush1) );

digitalDataOrZeroes dorz( .clk(clk80), .reset(rst), .bitData(bufferData), .bitBufEmpty(bufferEmpty), .bitRequest(readBuffer), 
									.dataRequest(digitalDataRequest), .data(digitalData), .dataReady(digitalDataReady) );

//Frame OrbitaM8
frameFiller orbMaker( .clk(clk80), .reset(rst), .nowRead(FF_RDEN), .nowAddr(FF_RADR),
							.digitalData(digitalData), .digitalDataReady(digitalDataReady), .digitalDataRequest(digitalDataRequest),
							.analogData(analogData), .analogDataRequest(analogDataRequest),
							.orbSwitch(FF_SWCH), .orbData(DW_DATA), .orbAddr(DW_ADDR), .orbWrEn(DW_WREN) );


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
