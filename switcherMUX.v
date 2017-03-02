module switcherMUX (
	input				reset,
	input 			clk,
	input 			switchSignal,
	output 			A01,
	output 			A11,
	output 			A21,
	output 			A02,
	output 			A12,
	output	 		A22,
	output 			A03,
	output 			A13,
	output 			A23,
	output reg [4:0] cntChannel
);

localparam SETUP = 2'd0;
localparam PREPARE = 2'd1;
localparam WAIT = 2'd2;

reg	[1:0]		state;
reg	[2:0]		muxA3;

assign A02 = cntChannel[0];
assign A12 = cntChannel[1];
assign A22 = cntChannel[2];
assign A01 = cntChannel[0];
assign A11 = cntChannel[1];
assign A21 = cntChannel[2];
assign A03 = muxA3[0];
assign A13 = muxA3[1];
assign A23 = muxA3[2];

wire	[2:0]		funConnect	[0:2];
assign funConnect[0] = 3'd3;
assign funConnect[1] = 3'd4;
assign funConnect[2] = 3'd6;
reg 	[1:0]		cntA3;


always@(posedge clk or negedge reset) begin
	if (~reset) begin
		state <= 2'd0;
		cntChannel <= 5'd0;
		muxA3 <= 3'b0;
		cntA3 <= 2'd0;
	end else begin
		case(state)
			SETUP: begin
				if (switchSignal)begin
					state <= PREPARE;
				end
			end
			PREPARE: begin
				cntChannel <= cntChannel + 1'b1;
				if (cntChannel < 5'd8) begin
					muxA3 <= 3'd1;
				end else begin
					if (cntChannel < 5'd16) begin
						muxA3 <= 3'd2;
					end else begin
						if (cntChannel == 5'd16) begin
							muxA3 <= funConnect[cntA3];
							cntA3 <= cntA3 + 1'b1;
							if(cntA3 == 2'd2) cntA3 <= 2'd0;
						end else begin
							muxA3 <= 3'd5;
							cntChannel <= 5'd0;
						end
					end
				end
				state <= WAIT;
			end
			WAIT: begin
				if (~switchSignal) state <= SETUP;
			end
		endcase
	end
end


endmodule
