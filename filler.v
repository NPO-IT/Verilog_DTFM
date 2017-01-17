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

reg	[3:0]		rSequence;
reg	[7:0]		cntSubStream;
reg	[2:0]		cntMarker;
reg	[2:0]		state;
reg				WRITE_MARKER = 3'd0;
reg				WRITE_DATA = 3'd1;
reg				CHECK_BUFFER = 3'd2;
reg				sender;
reg				enable;
reg	[175:0]	toWriteBuffer;
reg	[3:0]		pWR;
reg	[3:0]		pRD;

always@(posedge clk or negedge reset) begin
	if (~reset) begin
		outWDAT <= 12'b0;
		outWREN <= 1'b0;
		outWADR <= 10'b1;
		rSequence <= 4'b0;
		cntSubStream <= 8'b0;
		cntMarker <= 3'b0;
		state <= 3'b0;
		sender <= 1'b0;
		enable <= 1'b0;
		fifoRead <= 1'b0;
		pWR <= 4'b0;
		pRD <= 4'b0;
		toWriteBuffer <= 176'b0;
	end else begin
		if ((fifoUsed > 640) && (bufferChanged)) enable <= 1'b1;			// once we get 1000 words - enable the following scheme

		if (enable) begin
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
							state <= CHECK_BUFFER;
							if((outWADR[1:0] == 2'd3)) begin
								outWADR <= outWADR + 2'd2;
							end else begin
								outWADR <= outWADR + 1'b1;
							end
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
							//read 11 words and write 16 words at a time
							fifoRead <= 1'b1;
						end
						1: fifoRead <= 1'b0;
						3: begin
							case (pWR)
								0: toWriteBuffer[175 : 160] <= fifoOut;
								1: toWriteBuffer[159 : 144] <= fifoOut;
								2: toWriteBuffer[143 : 128] <= fifoOut;
								3: toWriteBuffer[127 : 112] <= fifoOut;
								4: toWriteBuffer[111 : 96] <= fifoOut;
								5: toWriteBuffer[95 : 80] <= fifoOut;
								6: toWriteBuffer[79 : 64] <= fifoOut;
								7: toWriteBuffer[63 : 48] <= fifoOut;
								8: toWriteBuffer[47 : 32] <= fifoOut;
								9: toWriteBuffer[31 : 16] <= fifoOut;
								10: toWriteBuffer[15 : 0] <= fifoOut;
							endcase
							pWR <= pWR + 1'b1;
							if (pWR < 10) begin
								rSequence <= 4'b0;
							end else begin
								rSequence <= 4'd4;
								pWR <= 1'b0;
							end
						end
						4: begin
							pRD <= pRD + 1'b1;
							case(pRD)
								0: outWDAT <= { 1'b0, toWriteBuffer[175: 165] };
								1: outWDAT <= { 1'b0, toWriteBuffer[164: 154] };
								2: outWDAT <= { 1'b0, toWriteBuffer[153: 143] };
								3: outWDAT <= { 1'b0, toWriteBuffer[142: 132] };
								4: outWDAT <= { 1'b0, toWriteBuffer[131: 121] };
								5: outWDAT <= { 1'b0, toWriteBuffer[120: 110] };
								6: outWDAT <= { 1'b0, toWriteBuffer[109: 99] };
								7: outWDAT <= { 1'b0, toWriteBuffer[98: 88] };
								8: outWDAT <= { 1'b0, toWriteBuffer[87: 77] };
								9: outWDAT <= { 1'b0, toWriteBuffer[76: 66] };
								10: outWDAT <= { 1'b0, toWriteBuffer[65: 55] };
								11: outWDAT <= { 1'b0, toWriteBuffer[54: 44] };
								12: outWDAT <= { 1'b0, toWriteBuffer[43: 33] };
								13: outWDAT <= { 1'b0, toWriteBuffer[32: 22] };
								14: outWDAT <= { 1'b0, toWriteBuffer[21: 11] };
								15: outWDAT <= { 1'b0, toWriteBuffer[10: 0] };
							endcase
						end
						5: outWREN <= 1'b1;
						7: begin
							outWREN <= 1'b0;
							sender <= 1'b0;
							state <= CHECK_BUFFER;
							if((outWADR[1:0] == 2'd3)) begin
								outWADR <= outWADR + 2'd2;
							end else begin
								outWADR <= outWADR + 1'b1;
							end
							if (pRD > 0) rSequence <= 4'd4;
						end
					endcase
				end
			endcase
		end
	end
end

endmodule
