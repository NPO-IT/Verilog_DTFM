module receiverSPI
#(
	parameter SLAVE_DELAY = 6'd10
)
(
	input						clk, 				//80
	input						reset, 
	input						dataRequest,	// read data from ADC
	input						DAT,				// incoming serial data
	output reg				nCS,				// actiavate ADC signal
	output					CLK,				// up to 20 MHz ADC clk
	output reg	[11:0]	spiData,			// received parallel data
	output reg				spiReady 		// parallel data ready
);

localparam STATE_WAIT = 2'd0;
localparam STATE_WRITE = 2'd1;
localparam STATE_REAR = 2'd2;
localparam STATE_GIVE = 2'd3;

reg	[2:0]		dataRQReg;
reg	[1:0]		clkDiv;
wire				dataRQFront;
always @(posedge clk or negedge reset) begin
	if (~reset) begin dataRQReg <= 3'b0; end
	else begin dataRQReg <= { dataRQReg[1:0],  dataRequest }; end
	if (~reset) begin	clkDiv <= 2'b0; end 
	else begin clkDiv <= clkDiv + 1'b1; end
end
assign	dataRQFront	=	(!dataRQReg[2] & dataRQReg[1]);
assign CLK = clkDiv[1];


reg	[5:0]		ready;
reg				slave_ready;
reg	[1:0]		state;
reg				delay;
reg	[5:0]		cntDelay;
reg	[3:0]		pointer;
reg	[4:0]		cntRX;
reg	[11:0]	word;

always @(negedge reset or posedge clk) begin
	if (~reset) begin
		ready <= 6'd0;
		slave_ready <= 1'b0;
		nCS <= 1'b1;
		state <= 2'b0;
		delay <= 1'b0;
		cntDelay <= 6'd0;
		pointer <= 4'd15;
		cntRX <= 5'd0;
		word <= 12'd0;
		spiData <= 12'd0;
		spiReady <= 1'd0;
	end else begin
		case (state)
			STATE_WAIT: begin
				if(dataRQFront) begin delay <= 1; end
				if(delay) cntDelay <= cntDelay + 1'b1;
				if(cntDelay == SLAVE_DELAY) begin
					delay <= 1'b0;
					state <= STATE_WRITE;
					nCS <= 1'b0;
					cntDelay <= 6'd0;
				end
			end
			STATE_WRITE: begin
				if(CLK == 1'b1) begin
					state <= STATE_REAR;
					if(cntRX < 5'd4) begin 
						cntRX <= cntRX + 1'b1; 
					end else begin
						word[pointer] <= DAT;
						pointer <= pointer - 1'b1;
					end
				end
			end
			STATE_REAR: begin
				if(CLK == 1'b0) begin
					state <= STATE_WRITE;
					if (pointer == 4'd15) begin
						pointer <= 4'd11;
						cntRX <= 5'd0;
						spiData <= word;
						spiReady <= 1'b1;
						nCS <= 1'b1;
						state <= STATE_GIVE;
					end
				end
			end
			STATE_GIVE: begin
				cntDelay <= cntDelay + 1'b1;
				if (cntDelay == 6'd3) begin
					cntDelay <= 6'd0;
					spiReady <= 1'b0;
					state <= STATE_WAIT;
				end
			end
		endcase
	end
end

endmodule
