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
wire	[10:0]	mark	[0:15];
assign	mark[0]	=	{ M[30:20] 					};
assign	mark[1]	=	{ M[19:9]				 	};
assign	mark[2]	=	{ M[8:0],	B[12:11]		};
assign	mark[3]	=	{ B[10:0] 					};
assign	mark[4]	=	{ nM[30:20]					};
assign	mark[5]	=	{ nM[19:9]				 	};
assign	mark[6]	=	{ nM[8:0],	B[12:11]		};
assign	mark[7]	=	{ B[10:0] 					};
assign	mark[8]	=	{ M[30:20] 					};
assign	mark[9]	=	{ M[19:9]				 	};
assign	mark[10]	=	{ M[8:0],	nB[12:11]	};
assign	mark[11]	=	{ nB[10:0] 					};
assign	mark[12]	=	{ nM[30:20] 				};
assign	mark[13]	=	{ nM[19:9]				 	};
assign	mark[14]	=	{ nM[8:0],	nB[12:11]	};
assign	mark[15]	=	{ nB[10:0] 					};

wire				e, f;
wire	[16:0]	out;
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
digitalFIFO fifo( .clock(clk), .data(word), .rdreq(fifoRead), .wrreq(readyFront), .empty(e), .full(f), .q(out), .usedw(fifoUsed));

reg	[3:0]		rSequence;
reg	[2:0]		pBegin, pEnd;
reg	[7:0]		cntSubStream;
reg	[2:0]		cntMarker;
reg	[2:0]		state;
reg				WRITE_MARKER = 3'd0;
reg				WRITE_DATA = 3'd1;
reg				CHECK_BUFFER = 3'd2;
reg				sender;
wire				act;
reg				enable;

assign act = ((fifoUsed > 320) && (fifoUsed < 1020)) ? 1'b1 : 1'b0;

always@(posedge clk or negedge reset) begin
	if (~reset) begin
		outWDAT <= 12'b0;
		outWREN <= 1'b0;
		outWADR <= 10'b1;
		rSequence <= 4'b0;
		pBegin <= 0;
		pEnd <= 10;
		cntSubStream <= 8'b0;
		cntMarker <= 3'b0;
		state <= 3'b0;
		sender <= 1'b0;
		enable <= 1'b0;
	end else begin
		if (fifoUsed == 1000) enable <= 1'b1;			// once we get 1000 words - enable the following scheme

		if (enable && act) begin
			case (state)
				WRITE_MARKER: begin
					rSequence <= rSequence + 1'b1;
					case(rSequence)
						0: begin
							outWDAT <= { 1'b0, mark[cntMarker] };
							outWREN <= 1'b1;
						end
						3: begin
							cntMarker <= cntMarker + 1'b1;
							outWREN <= 1'b0;
							if((outWADR[1:0] == 2'd3))
								outWADR <= outWADR + 2'd2;
							else
								outWADR <= outWADR + 1'b1;
							state <= CHECK_BUFFER;
						end
						4: begin
							rSequence <= 4'b0;
							if (cntMarker[1:0] == 2'b0) begin
								state <= WRITE_DATA;
								sender <= 1'b1;
							end
						end
					endcase			
				end
				CHECK_BUFFER: begin
					if(outWADR != 1023) begin
						if (sender == 1'b1) begin
							state <= WRITE_MARKER;
						end else begin
							state <= WRITE_DATA;
						end
					end else begin
						if (bufferChanged) begin
							if (sender == 1'b1) begin
								state <= WRITE_MARKER;
							end else begin
								state <= WRITE_DATA;
							end
						end
					end
				end
				WRITE_DATA: begin
					rSequence <= rSequence + 1'b1;
					case(rSequence)
						0: begin
						//	fifoRead <= 1'b1;
						end
						3: begin
							
						end
						default: begin
						end
					endcase
				end
			endcase
		end
	end
end

endmodule
