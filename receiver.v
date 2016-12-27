module receiver (
	input							cClk,		// common clock
	input							reset,
	input							dClk,		// incoming data clock
	input							data,		// incoming data
	input							sync,		// frame marker (sync clear)
	output	reg	[15:0]	word,
	output	reg				ready		// valid word on bus
);
// read data to output by the rear dClk
// clear all counters and variables by front sync
reg	[2:0]		syncReg;
reg	[2:0]		clkReg;
wire				syncFront;
wire				clkFront;
wire				clkRear;

always@(posedge cClk or negedge reset) begin
	if(~reset)
		syncReg <= 3'b0;
	else
		syncReg <= { syncReg[1:0],  sync };
end

always@(posedge cClk or negedge reset) begin
	if (~reset)
		clkReg <= 3'b0;
	else
		clkReg <= { clkReg[1:0],  dClk };
end
		
assign	syncFront	=	(!syncReg[2] & syncReg[1]);
assign	clkFront		=	(!clkReg[2] & clkReg[1]);
assign	clkRear		=	(clkReg[2] & !clkReg[1]);

reg	[3:0]		cntBits;

always@(posedge cClk or negedge reset) begin
	if(~reset) begin
		word <= 16'b0;
		cntBits <= 4'd15;
		ready <= 1'b0;
	end else begin
		if(syncFront) begin
			word <= 16'b0;
			cntBits <= 4'd15;
			ready <= 1'b0;
		end else begin
			if(clkRear) begin
				cntBits <= cntBits - 1'b1;
				word[cntBits] <= data;
				if (cntBits == 4'd0) ready <= 1'b1;
			end
			if (clkFront) ready <= 1'b0;
		end
	end
end

endmodule
