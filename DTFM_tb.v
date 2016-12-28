`timescale 10 ps/10 ps

module DTFM_tb();
reg 				clk = 0;
reg 				dCLK = 0, dFM = 0, dDAT = 0;
reg	[3:0]		bitCnt	=	15;
reg	[4:0]		wrdCnt	=	19;
reg	[5:0]		strNum	=	63;
reg	[8:0]		frmNum	=	1023;
wire				out;


initial begin						// clk ~32768MHz
	clk = 0;
	forever #1525 clk = ~clk;
end

initial begin						// clk ~1MHz
	dCLK = 0;
	forever #50000 dCLK = ~dCLK;
end

// Static
reg	[11:0]	OK1	=	12'd1101;
reg	[11:0]	OK2	=	12'd1202;
reg	[11:0]	OK3	=	12'd1303;
reg	[11:0]	VK1	=	12'd0;
reg	[11:0]	VK2	=	12'd240;
reg	[11:0]	VK3	=	12'd3855;
reg	[11:0]	UF1	=	12'd1365;
reg	[11:0]	UF2	=	12'd2730;
reg	[11:0]	UF3	=	12'd0;
reg	[7:0]		corr	=	8'd101;
reg	[7:0]		pel	=	8'd111;
reg	[7:0]		XD		=	8'd121;
reg	[7:0]		YD		=	8'd131;
reg	[7:0]		RM		=	8'd141;
reg	[7:0]		POS	=	8'd151;
reg	[7:0]		ARU	=	8'd161;
// Structure
wire	[15:0]	w[0:19];
assign			w[0]	=	{frmNum[8:0],	strNum[5:0],	1'b1	};
assign			w[1]	=	{OK1[11:0],		corr[7:4]				};
assign			w[2]	=	{OK2[11:0],		pel[7:4]					};
assign			w[3]	=	{OK3[11:0],		XD[7:4]					};
assign			w[4]	=	{VK1[11:0],		YD[7:4]					};
assign			w[5]	=	{VK2[11:0],		RM[7:4]					};
assign			w[6]	=	{VK3[11:0],		POS[7:4]					};
assign			w[7]	=	{UF1[11:0],		ARU[7:4]					};
assign			w[8]	=	{UF2[11:0],							4'd0	};
assign			w[9]	=	{UF3[11:0],							4'd0	};
assign			w[10]	=	{frmNum[8:0],	strNum[5:0],	1'b0	};
assign			w[11]	=	{OK1[11:0],		corr[3:0]				};
assign			w[12]	=	{OK2[11:0],		pel[3:0]					};
assign			w[13]	=	{OK3[11:0],		XD[3:0]					};
assign			w[14]	=	{VK1[11:0],		YD[3:0]					};
assign			w[15]	=	{VK2[11:0],		RM[3:0]					};
assign			w[16]	=	{VK3[11:0],		POS[3:0]					};
assign			w[17]	=	{UF1[11:0],		ARU[3:0]					};
assign			w[18]	=	{UF2[11:0],							4'd0	};
assign			w[19]	=	{UF3[11:0],							4'd0	};

initial begin
	repeat(10)@(posedge dCLK);
	repeat(15)begin
		repeat(10240) begin
			dFM = 0;
			dDAT = w[wrdCnt][bitCnt];
			bitCnt <= bitCnt - 1'b1;
			if(bitCnt == 4'd15) begin
				wrdCnt <= wrdCnt + 1'b1;
				if(wrdCnt == 5'd9) begin
					strNum <= strNum + 1'b1;
				end else
				if(wrdCnt == 5'd19) begin
					strNum <= strNum + 1'b1;
					if (strNum == 6'd63) begin
						frmNum <= frmNum + 1'b1;
						dFM = 1;
					end
					wrdCnt <= 5'b0;
				end
			end
			@(posedge dCLK);
		end
	end
	$stop;
end


DTFM DTFM_tb(
	.clk(clk),
	.dCLK(dCLK),
	.dFM(dFM),
	.dDAT(dDAT),
	.FRM(out)
);

endmodule
