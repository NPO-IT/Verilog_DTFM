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
wire	[16:0]	fifoOut;
reg	[2:0]		readyReg;
wire				readyFront;
reg				oldSwitch;
wire				bufferChanged;
reg				fifoRead;

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
reg				enable;
reg				bitDatIn;
reg				bitDatOut;
reg				bitWreq;
reg				bitRdrq;
reg	[2:0]		state;
reg	[3:0]		mSequence;
reg	[3:0]		dSequence;
reg	[43:0]	marker;
reg	[5:0]		pRead;
reg	[1:0]		markNumber;

always@(posedge clk or negedge reset) begin
	if (~reset) begin
		outWDAT <= 12'b0;
		outWREN <= 1'b0;
		outWADR <= 10'b1;
		state <= DO_CHECKS;
		enable <= 1'b0;
		fifoRead <= 1'b0;
		bitDatIn <= 1'b0;
		bitDatOut <= 1'b0;
		bitWreq <= 1'b0;
		bitRdrq <= 1'b0;
		mSequence <= 4'b0;
		marker <= 44'b0;
		pRead <= 6'b43;
		markNumber <= 2'b0;
		dSequence <= 4'b0;
	end else begin
		if ((fifoUsed > 640) && (bufferChanged)) enable <= 1'b1;			// once we get 1000 words - enable the following scheme

		if (enable) begin
			case (state)
				READ_DATA: begin
				end
				READ_MARKER: begin
					mSequence <= mSequence + 1'b1;					// make a sequencer
					case(mSequence)
						0: begin												// when entered for the first time
							marker <= mark[markNumber];				// read data to a secondary variable
						end
						1: begin												// then enter a cycle
							bitDatIn <= marker[pRead];					//	set the bit FIFO input
							bitRdrq <= 1'b1;								// write enable
						end
						4: begin												// wait
							bitRdrq <= 1'b0;								// stop writing
							if (pRead == 6'd0) begin					// if just wrote last bit 
								pRead <= 6'd43;							// reset bit pointer
								markNumber <= markNumber + 1'b1;		// point to next marker
								mSequence <= 4'd0;						// drop the sequence
								state <= DO_CHECKS;						// and go for checks
							end else begin								// otherwise
								pRead <= pRead - 1'b1;					// point to next bit
								mSequence <= 4'b1;						// and go write next bit to FIFO
							end
						end
					endcase
				end
				DO_CHECKS: begin
					state <= READ_MARKER;			// first entrance (flag?)
					
					// check memory availability
					
					if (bufUsed > 6'd12) begin							// if buffer contains more than one word 
						state <= WRITE_DATA;								// go write word to output
					end else begin										// otherwise
						
						// check written words (if 256 write marker,)
						
					end
				end
				WRITE_DATA: begin
					dSequence <= dSequence + 1'b1;
				end
			endcase
		end
	end
end

endmodule
