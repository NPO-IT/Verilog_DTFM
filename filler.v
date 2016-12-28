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

wire e, f;
wire [16:0] out;
reg	[2:0]		readyReg;
wire				readyFront;

always@(posedge clk or negedge reset) begin
	if(~reset) readyReg <= 3'b0;
	else readyReg <= { readyReg[1:0],  ready };
end

assign	readyFront	=	(!readyReg[2] & readyReg[1]);

// Takes 2 clocks to set output, use 4 to be sure
digitalFIFO fifo( .clock(clk), .data(word), .rdreq(0), .wrreq(readyFront), .empty(e), .full(f), .q(out), .usedw(fifoUsed));

endmodule
