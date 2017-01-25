module digitalWriter (
	input 					clk,
	input						reset,
	input						bitData,
	output reg				bitRequest,
	input			[14:0]	bitLevel,
	input						orbSwitch,
	output reg	[11:0]	orbWord,
	output reg	[9:0]		orbAddr,
	output reg				orbWren
);

wire	[30:0]	M 	=	31'b1111100110100100001010111011000;
wire	[30:0]	nM	=	31'b0000011001011011110101000100111;
wire	[12:0]	B	=	13'b1111100110101;
wire	[12:0]	nB	=	13'b0000011001010;
wire	[43:0]	mark	[0:3];
assign	mark[0]	=	{ M,	B	};
assign	mark[1]	=	{ nM,	B	};
assign	mark[2]	=	{ M,	nB	};
assign	mark[3]	=	{ nM,	nB	};

reg				oldSwitch;
wire				bufferChanged;
reg	[3:0]		dSeq;
reg				enable;
reg				switched;
reg	[8:0]		wordsWritten;
reg	[1:0]		markerNumber;
reg	[14:0]	bitRead;
reg	[2:0]		mSeq;
reg	[2:0]		zSeq;
reg	[43:0]	tempMark;
reg	[10:0]	wrd;
reg	[1:0]		pMark;
reg	[3:0]		pData;

always@(posedge clk or negedge reset) begin
	if(~reset) oldSwitch <= 1'b0;
	else oldSwitch <= orbSwitch;
end
assign	bufferChanged	=	(oldSwitch != orbSwitch) ? 1'b1 : 1'b0;

always@(posedge clk or negedge reset) begin
	if (~reset) begin
		orbWord			<= 12'd0;
		orbAddr			<= 10'd0;
		orbWren			<= 1'b0;
		dSeq				<= 4'd0;
		enable			<= 1'b0;
		switched			<= 1'b1;
		bitRequest		<= 1'b0;
		wordsWritten	<= 9'd0;
		markerNumber	<= 2'd0;
		bitRead			<= 15'd0;
		mSeq				<= 3'd0;
		zSeq				<= 3'd0;
		tempMark			<= 44'd0;
		wrd				<= 11'd0;
		pMark				<= 2'b0;
		pData				<= 4'd0;
	end else begin
		if ((~enable) && (bitLevel > 15'd10240)) begin
			enable <= 1'b1;
		end

		if(orbAddr == 1023) begin
			switched <= 1'b0;
			bitRequest <= 1'b0;
		end 
		if (bufferChanged) begin
			switched <= 1'b1;
		end
		
		if (enable) begin
			if (switched) begin
				if (wordsWritten == 9'd0) begin
					mSeq <= mSeq + 1'b1;
					case (mSeq)
						0: begin
							tempMark <= mark[markerNumber];
							pMark <= 2'd0;
						end
						1: begin
							case (pMark)
								2'd0: orbWord <= {1'b0, tempMark[43:33]};
								2'd1: orbWord <= {1'b0, tempMark[32:22]};
								2'd2: orbWord <= {1'b0, tempMark[21:11]};
								2'd3: orbWord <= {1'b0, tempMark[10:0]};
							endcase
							pMark <= pMark + 1'b1;
						end
						2: orbWren <= 1'b1;
						4: begin
							orbWren <= 1'b0;
							
							if((orbAddr[1:0] == 2'd3)) begin
								orbAddr <= orbAddr + 2'd2;
							end else begin
								orbAddr <= orbAddr + 1'b1;
							end
							
							if (pMark > 2'd0) begin
								mSeq <= 3'd1;
							end else begin
								mSeq <= 3'd0;
								markerNumber <= markerNumber + 1'b1;
								wordsWritten <= 1'b1;
							end
						end
					endcase
				end else begin
					if (bitRead < 15'd10240) begin
						dSeq <= dSeq + 1'b1;
						case (dSeq)
							0: begin
								bitRequest <= 1'b1;
								wrd[pData] <= bitData;
							end
							1: begin
								bitRequest <= 1'b0;
								pData <= pData - 1'b1;
								bitRead <= bitRead + 1'b1;
							end
							2:	begin
								if (pData == 4'd15) begin
									dSeq <= 4'd3;
									pData <= 4'd10;
								end else begin
									dSeq <= 4'd0;
								end
							end	
							3: orbWord <= {1'b0, wrd};
							4:	orbWren <= 1'b1;
							6: begin
								orbWren <= 1'b0;
								if((orbAddr[1:0] == 2'd3)) begin
									orbAddr <= orbAddr + 2'd2;
								end else begin
									orbAddr <= orbAddr + 1'b1;
								end
								wordsWritten <= wordsWritten + 1'b1;
								if(wordsWritten == 256) begin
									wordsWritten <= 9'b0;
								end
								dSeq <= 4'b0;
							end
						endcase
					end else begin
						if (bitLevel < 10240) begin
							zSeq <= zSeq + 1'b1;
							case (zSeq)
								0: wrd[pData] <= 1'b0;
								1: pData <= pData - 1'b1;
								2:	begin
									if (pData == 4'd15) begin
										zSeq <= 4'd3;
										pData <= 4'd10;
									end else begin
										zSeq <= 4'd0;
									end
								end	
								3: orbWord <= {1'b0, wrd};
								4:	orbWren <= 1'b1;
								6: begin
									orbWren <= 1'b0;
									if((orbAddr[1:0] == 2'd3)) begin
										orbAddr <= orbAddr + 2'd2;
									end else begin
										orbAddr <= orbAddr + 1'b1;
									end
									zSeq <= 4'b0;
								end
							endcase
						end else begin
							dSeq <= 4'd0;
							wordsWritten <= 9'd0;
							markerNumber <= 2'd0;
							bitRead <= 15'd0;
							mSeq <= 3'd0;
							zSeq <= 3'd0;
							tempMark	<= 11'd0; 
							wrd <= 11'd0;
							pMark	<= 2'b0;
							pData	<= 4'd0;
						end
					end
				end	
			end

		end
	end
end
endmodule
