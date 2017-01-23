module filler ( 
	input 						clk, 
	input 						reset, 
	input				[15:0]	word,
	input 						ready,
	input							bufSwitch,
	output	reg	[11:0]	outWDAT,
	output	reg				outWREN,
	output	reg	[9:0]		outWADR
);

wire	[9:0]		fifoUsed;
wire	[30:0]	M 	=	31'b1111100110100100001010111011000;
wire	[30:0]	nM	=	31'b0000011001011011110101000100111;
wire	[12:0]	B	=	13'b1111100110101;
wire	[12:0]	nB	=	13'b0000011001010;
wire	[43:0]	mark	[0:3];
assign	mark[0]	=	{ M,	B	};
assign	mark[1]	=	{ nM,	B	};
assign	mark[2]	=	{ M,	nB	};
assign	mark[3]	=	{ nM,	nB	};

wire				e, f;
wire	[15:0]	fifoOut;
reg	[2:0]		readyReg;
wire				readyFront;
reg				oldSwitch;
wire				bufferChanged;
reg				fifoRead;
reg				bitDatIn;
wire				bitDatOut;
reg				bitWreq;
reg				bitRdrq;
wire	[5:0]		bufUsed;


always@(posedge clk or negedge reset) begin
	if(~reset) readyReg <= 3'b0;
	else readyReg <= { readyReg[1:0],  ready };
	
	if(~reset) oldSwitch <= 1'b0;
	else oldSwitch <= bufSwitch;
end

assign	readyFront		=	(!readyReg[2] & readyReg[1]);
assign	bufferChanged	=	(oldSwitch != bufSwitch) ? 1'b1 : 1'b0;

// Takes 2 clocks to set output, use 4 to be sure
digitalFIFO fifo( .clock(clk), .data(word), .rdreq(fifoRead), .wrreq(readyFront), .empty(e), .full(f), .q(fifoOut), .usedw(fifoUsed));
oneBitFIFO outBuffer( .clock(clk), .data(bitDatIn), .rdreq(bitRdrq), .wrreq(bitWreq), .q(bitDatOut), .usedw(bufUsed) );

localparam		READ_DATA = 3'd0;
localparam		READ_MARKER = 3'd1;
localparam		DO_CHECKS = 3'd2;
localparam		WRITE_DATA = 3'd3;
localparam		READ_ZEROS = 3'd4;
reg				enable;
reg				switched;
reg	[2:0]		state;
reg	[3:0]		mSequence;
reg	[3:0]		dSequence;
reg	[43:0]	marker;
reg	[5:0]		pMark;
reg	[1:0]		markNumber;
reg	[3:0]		pData;
reg	[8:0]		wordsWritten;
reg	[9:0]		wordsRead;
reg	[3:0]		wSequence;
reg	[3:0]		pWrite;
reg	[3:0]		zSequence;
reg	[15:0]	wrd;

always@(posedge clk or negedge reset) begin
	if (~reset) begin
		outWDAT <= 12'b0;
		outWREN <= 1'b0;
		outWADR <= 10'b1;
		state <= DO_CHECKS;
		enable <= 1'b0;
		fifoRead <= 1'b0;
		bitDatIn <= 1'b0;
		bitWreq <= 1'b0;
		bitRdrq <= 1'b0;
		mSequence <= 4'b0;
		marker <= 44'b0;
		pMark <= 6'd43;
		markNumber <= 2'b0;
		wSequence <= 4'b0;
		pWrite <= 4'd10;
		wordsWritten <= 9'd0;
		dSequence <= 4'b0;
		pData <= 4'd15;
		zSequence <= 4'b0;
		wrd <= 16'd0;
		switched <= 1'b1;
		wordsRead <= 10'b0;
	end else begin
		if ((~enable) && (fifoUsed > 640)) begin
			enable <= 1'b1;			// once we get 640 words - enable the following scheme
			state <= READ_MARKER;			// first entrance (flag?)
		end

		if (enable) begin
			case (state)
				READ_ZEROS: begin
					zSequence <= zSequence + 1'b1;
					case (zSequence)
						0: begin
							bitDatIn <= 1'b0;
							bitWreq <= 1'b1;
						end
						2: begin
							bitWreq <= 1'b0;
						end
						3: begin
							zSequence <= 4'b0;
							state <= DO_CHECKS;
						end
					endcase

				end
				READ_DATA: begin
					dSequence <= dSequence + 1'b1;
					case (dSequence)
						0: begin
							wrd <= fifoOut;
							fifoRead <= 1'b1;
						end
						1: begin
							fifoRead <= 1'b0;
							bitDatIn <= wrd[pData];
							bitWreq <= 1'b1;
						end
						3: begin
							bitWreq <= 1'b0;
							pData <= pData - 1'b1;
						end
						4: begin
							if (pData == 4'd15) begin
								dSequence <= 4'b0;
								wordsRead <= wordsRead + 1'b1;
								state <= DO_CHECKS;
							end else begin
								dSequence <= 4'b1;
							end
						end
					endcase
				end
				READ_MARKER: begin
					mSequence <= mSequence + 1'b1;					// make a sequencer
					case(mSequence)
						0: begin												// when entered for the first time
							marker <= mark[markNumber];				// read data to a secondary variable
						end
						1: begin												// then enter a cycle
							bitDatIn <= marker[pMark];					//	set the bit FIFO input
							bitWreq <= 1'b1;								// write enable
						end
						2: begin												// wait
							bitWreq <= 1'b0;								// stop writing
							if (pMark == 6'd0) begin					// if just wrote last bit 
								pMark <= 6'd43;							// reset bit pointer
								markNumber <= markNumber + 1'b1;		// point to next marker
								mSequence <= 4'd0;						// drop the sequence
								state <= DO_CHECKS;						// and go for checks
							end else begin								// otherwise
								pMark <= pMark - 1'b1;					// point to next bit
								mSequence <= 4'b1;						// and go write next bit to FIFO
							end
						end
					endcase
				end
				DO_CHECKS: begin
					if(outWADR == 1023) begin
						switched <= 1'b0;
					end else begin
						if (bufferChanged) begin
							switched <= 1'b1;
						end
					end
					if (switched) begin
						if (wordsRead < 10'd640) begin
							if (wordsWritten >= 9'd255) begin
								state <= READ_MARKER;
								wordsWritten <= 9'd0;
							end else begin
								if (bufUsed >= 6'd11) begin							// if buffer contains more than one word 
									state <= WRITE_DATA;
								end else begin
									state <= READ_DATA;
								end
							end
						end else begin
							if (fifoUsed > 11'd640) begin
								wordsRead <= 10'd0;
							end else begin
								state <= READ_ZEROS;
							end
						end
					end				
				end
				WRITE_DATA: begin
					wSequence <= wSequence + 1'b1;
					case(wSequence)
					0: begin
						outWDAT[pData] <= bitDatOut;
						pWrite <= pWrite - 1'b1;
						bitRdrq <= 1'b1;
					end
					1: begin
						bitRdrq <= 1'b0;
						wSequence <= 4'b0;
						if (pWrite > 4'd10) begin
							pWrite <= 4'd10;
							wSequence <= 4'd3;
						end
					end
					3: begin
						outWREN <= 1'b1;
						wordsWritten <= wordsWritten + 1'b1;
					end
					5: begin
							if((outWADR[1:0] == 2'd3)) begin
								outWADR <= outWADR + 2'd2;
							end else begin
								outWADR <= outWADR + 1'b1;
							end
						outWREN <= 1'b0;
						wSequence <= 4'b0;
						state <= DO_CHECKS;
					end
					endcase
				end
			endcase
		end
	end
end

endmodule
