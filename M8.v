module M8(
	// common
	input reset,
	input clk,										// 12'582'912
	// group memory interactions
	input [11:0]iData,
	output reg oSwitch,
	output reg oRdEn,
	output reg [9:0]oAddr,
	// output frame signals
	output reg oSerial,
	output reg [11:0]oParallel,
	output reg oValid,
	// request signals (depending on reading states)
	output reg oLCB1_rq,
	output reg oLCB2_rq,
	output reg oLCB3_rq,
	output reg oLCB4_rq,
	output reg oMCM_rq,
	output reg [4:0]oLCB_num
);
//frame variables
reg [23:0]outWrd;
wire [23:0]iDoubled;
wire [11:0]oSingled;
reg [1:0]cntDiv, cntCcl;
reg [4:0]cntBit, cntGrp;
reg [2:0]cntWrd;
reg [6:0]cntPhr;
reg [9:0]cntMem;
reg [3:0]cnt1Sec, cnt10Sec, cnt100Sec, cnt1000Sec;
// requester variables
reg [11:0]cntLCBrq;
reg [4:0]MCM_rq_delay;
reg oldSw, MCM_delay;

assign iDoubled = {iData[11],iData[11],iData[10],iData[10],iData[9],iData[9],iData[8],iData[8],iData[7],iData[7],iData[6],iData[6],iData[5],iData[5],iData[4],iData[4],iData[3],iData[3],iData[2],iData[2],iData[1],iData[1],iData[0],iData[0]};
assign oSingled = {outWrd[22], outWrd[20], outWrd[18], outWrd[16], outWrd[14], outWrd[12], outWrd[10], outWrd[8], outWrd[6], outWrd[4], outWrd[2], outWrd[0]};

always@(posedge clk or negedge reset) begin
if (~reset) begin // initial
	cntDiv <= 1;
	cntBit <= 0;
	cntWrd <= 0;
	cntPhr <= 0;
	cntGrp <= 0;
	cntMem <= 1;
	cntCcl <= 0;
	cnt1Sec <= 0;
	cnt10Sec <= 0;
	cnt100Sec <= 0;
	cnt1000Sec <= 0;
	cntLCBrq <= 0;
	oLCB_num <= 0;
	oLCB1_rq <= 0;
	oLCB2_rq <= 0;
	oLCB3_rq <= 0;
	oLCB4_rq <= 0;
	oSwitch <= 0;
	oParallel <= 0;
	oSerial <= 0;
	oValid <= 0;

	oMCM_rq <= 0;
	MCM_delay <= 0;
	MCM_rq_delay <= 0;
	oldSw <= 0;

end else begin	// main

	cntDiv <= cntDiv + 1'b1;
	case (cntDiv)									// ???? ? ?????????
		0: 	begin
			oSerial <= outWrd[(23-cntBit)];			// set out digit
			if (cntBit == 0) begin
				oParallel <= oSingled;
				oValid <= 1;
			end else oValid <= 0;
		end
		1:	begin
			if (cntBit == 23) begin					// on last bit
				oAddr <= cntMem;
				oRdEn <= 1;							// prepare to read next word
				outWrd <= 24'd0;					// clear the word
			end
			cntBit <= cntBit + 1'b1;				// count to next bit
		end
		2:	if (cntBit == 24) begin					// on last bit of word
				cntBit <= 0;						// reset the bit counter
				outWrd <= iDoubled;					// change the word
			
								/*count address for reading*/
				if (cntMem == 0) begin oSwitch <= ~oSwitch; end 
				cntMem <= cntMem + 1'b1;			// count 1024 words of memory
				
								/*count all markers*/
				cntWrd <= cntWrd + 1'b1;
				if (cntWrd == 7) begin		// 8 ???? = 1 ?????
					cntPhr <= cntPhr + 1'b1;
					if (cntPhr == 127) begin		// 128 ???? = 1 ??????
						cntGrp <= cntGrp + 1'b1;
						if (cntGrp == 31) begin		// 32 ?????? = 1 ????
							cntCcl <= cntCcl + 1'b1;
							if (cntCcl == 3) begin		// 4 ????? = 1 ???? = 1 ???????
								cnt1Sec <= cnt1Sec + 1'b1;
								if (cnt1Sec == 9) begin		// ??????? ??????? ??????
									cnt1Sec <= 0;
									if (cnt10Sec == 9) begin	// ??????? ????? ??????
										cnt10Sec <= 0;
										if (cnt100Sec == 9) begin		// ??????? ?????? ??????
											cnt100Sec <= 0;
											if (cnt1000Sec == 9) begin
												cnt1000Sec <= 0; 
											end else begin cnt1000Sec <= cnt1000Sec + 1'b1; end
										end else begin cnt100Sec <= cnt100Sec + 1'b1; end
									end else begin cnt10Sec <= cnt10Sec + 1'b1; end
								end 
							end 
						end 
					end 
				end 
			end
		3: begin
			oRdEn <= 0;
								/*all marker conditions here*/
			if (cntBit == 0) begin
				case (cntPhr)							// phrase marker
					0,2,4,6,8,10,12,14,16,18,20,22,24,26,28,30,32,34,36,38,40,42,44,46,48,50,52,54,56,58,60,62,64,66,68,70,72,74,76,78,80,82,84,86,88,90,92,94,96,98,100,102,104,106,108,110,112,114,116,118,120,122,124,126:
						if (cntWrd == 0) begin outWrd <= (outWrd | 24'b100000000000000000000000); end
						// group number counter
					1: if (cntWrd == 0) begin outWrd <= (outWrd | {24'b0}); end
					3: if (cntWrd == 0) begin outWrd <= (outWrd | {24'b0}); end
					5: if (cntWrd == 0) begin outWrd <= (outWrd | {cntGrp[4],cntGrp[4], 22'b0}); end
					7: if (cntWrd == 0) begin outWrd <= (outWrd | {cntGrp[3],cntGrp[3], 22'b0}); end
					9: if (cntWrd == 0) begin outWrd <= (outWrd | {cntGrp[2],cntGrp[2], 22'b0}); end
					11: if (cntWrd == 0) begin outWrd <= (outWrd | {cntGrp[1],cntGrp[1], 22'b0}); end
					13: if (cntWrd == 0) begin outWrd <= (outWrd | {cntGrp[0],cntGrp[0], 22'b0}); end
						// time label
/*	doesn't work. yet.
						// ones
					41: if (cntGrp == 0) begin if (cntWrd == 0) begin outWrd <= (outWrd | {cnt1Sec[3],cnt1Sec[3], 22'b0}); end end
					43: if (cntGrp == 0) begin if (cntWrd == 0) begin outWrd <= (outWrd | {cnt1Sec[2],cnt1Sec[2], 22'b0}); end end
					45: if (cntGrp == 0) begin if (cntWrd == 0) begin outWrd <= (outWrd | {cnt1Sec[1],cnt1Sec[1], 22'b0}); end end
					47: if (cntGrp == 0) begin if (cntWrd == 0) begin outWrd <= (outWrd | {cnt1Sec[0],cnt1Sec[0], 22'b0}); end end
						// decades
					33: if (cntGrp == 0) begin if (cntWrd == 0) begin outWrd <= (outWrd | {cnt10Sec[3],cnt10Sec[3], 22'b0}); end end
					35: if (cntGrp == 0) begin if (cntWrd == 0) begin outWrd <= (outWrd | {cnt10Sec[2],cnt10Sec[2], 22'b0}); end end
					37: if (cntGrp == 0) begin if (cntWrd == 0) begin outWrd <= (outWrd | {cnt10Sec[1],cnt10Sec[1], 22'b0}); end end
					39: if (cntGrp == 0) begin if (cntWrd == 0) begin outWrd <= (outWrd | {cnt10Sec[0],cnt10Sec[0], 22'b0}); end end
						// hundreds
					25: if (cntGrp == 0) begin if (cntWrd == 0) begin outWrd <= (outWrd | {cnt100Sec[3],cnt100Sec[3], 22'b0}); end end
					27: if (cntGrp == 0) begin if (cntWrd == 0) begin outWrd <= (outWrd | {cnt100Sec[2],cnt100Sec[2], 22'b0}); end end
					29: if (cntGrp == 0) begin if (cntWrd == 0) begin outWrd <= (outWrd | {cnt100Sec[1],cnt100Sec[1], 22'b0}); end end
					31: if (cntGrp == 0) begin if (cntWrd == 0) begin outWrd <= (outWrd | {cnt100Sec[0],cnt100Sec[0], 22'b0}); end end
						// thousands
					17: if (cntGrp == 0) begin if (cntWrd == 0) begin outWrd <= (outWrd | {cnt1000Sec[3],cnt1000Sec[3], 22'b0}); end end
					19: if (cntGrp == 0) begin if (cntWrd == 0) begin outWrd <= (outWrd | {cnt1000Sec[2],cnt1000Sec[2], 22'b0}); end end
					21: if (cntGrp == 0) begin if (cntWrd == 0) begin outWrd <= (outWrd | {cnt1000Sec[1],cnt1000Sec[1], 22'b0}); end end
					23: if (cntGrp == 0) begin if (cntWrd == 0) begin outWrd <= (outWrd | {cnt1000Sec[0],cnt1000Sec[0], 22'b0}); end end
*/					
				endcase
				case (cntGrp)
					31:	begin							// cycle marker

						case (cntPhr)
							113,121,123,127: if (cntWrd == 0) begin outWrd <= (outWrd | 24'b110000000000000000000000); 	end
						endcase
					end
					default: begin						// group marker
			
						case (cntPhr)
							115,117,119,125: if (cntWrd == 0) begin outWrd <= (outWrd | 24'b110000000000000000000000); end
						endcase
					end
				endcase
				case (cntCcl)							// frame cycle
					0:	if (cntGrp == 0)
							if (cntPhr == 15)
								if (cntWrd == 0) begin outWrd <= (outWrd | 24'b110000000000000000000000); end
				endcase
			end
			cntDiv <= 0;
		end
	endcase

//MCM request	
// search for group switching signal
if(oldSw != oSwitch) begin
	MCM_delay <= 1'b1;						// enable count
end
oldSw <= oSwitch;
// make a MCM_RQ signal 15x12MHz clocks
if(MCM_delay == 1)begin
	MCM_rq_delay <= MCM_rq_delay + 1'b1;	// count
	if(MCM_rq_delay == 15) begin			// if done counting
		MCM_rq_delay <= 0;					// reset counter
		MCM_delay <= 0;						// disable count
		oMCM_rq <= 0;						// stop requesting
	end else begin							// otherwise
		oMCM_rq <= 1;						// request
	end
end

	
//LCB request
	cntLCBrq <= cntLCBrq + 1'b1;
	case (cntLCBrq)
		0: oLCB1_rq <= 1;
		20: oLCB1_rq <= 0;
		750: oLCB2_rq <= 1;
		770: oLCB2_rq <= 0;
		1500: oLCB3_rq <= 1;
		1520: oLCB3_rq <= 0;
		2250: oLCB4_rq <= 1;
		2270: oLCB4_rq <= 0;
		3021: oLCB_num <= oLCB_num + 1'b1;
		3071: cntLCBrq <= 0;
	endcase


end
end
endmodule
