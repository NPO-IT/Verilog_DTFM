module DTFM (
	input clk,
	input dCLK,
	input dFM,
	input dDAT,
	output FRM
);

//assign FRM = dDAT;
//assign FRM = dCLK;
assign FRM = dFM;

endmodule
