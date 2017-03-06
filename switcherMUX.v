module switcherMUX (
	input						reset,
	input 					clk,
	input 					switchSignal,
	output 					A01,
	output 					A11,
	output 					A21,
	output	 				A02,
	output		 			A12,
	output	 				A22,
	output 					A03,
	output 					A13,
	output 					A23,
	output reg	[1:0]		state,
	output reg	[2:0]		muxA3,
	output reg	[4:0]		cntChannel
);

localparam SETUP = 2'd0;
localparam PREPARE = 2'd1;
localparam WAIT = 2'd2;

//reg		[1:0]		state;
reg 	[1:0]		cntA3;
//reg		[2:0]		muxA3;
wire	[2:0]		funConnect	[0:3];
assign funConnect[0] = 3'd3;
assign funConnect[1] = 3'd5;
assign funConnect[2] = 3'd2;
assign funConnect[3] = 3'd5;
assign A01 = cntChannel[0];
assign A11 = cntChannel[1];
assign A21 = cntChannel[2];
assign A02 = cntChannel[0];
assign A12 = cntChannel[1];
assign A22 = cntChannel[2];
assign A03 = muxA3[0];
assign A13 = muxA3[1];
assign A23 = muxA3[2];


always@(posedge clk or negedge reset) begin
	if (~reset) begin
		state <= SETUP;
		cntChannel <= 5'd0;
		muxA3 <= 3'd3;
		cntA3 <= 2'd0;
	end else begin
		case(state)
			SETUP: begin
				if (switchSignal)
					state <= PREPARE;
			end
			PREPARE: begin
				cntChannel <= cntChannel + 1'b1;
				case (cntChannel)
					5'd1, 5'd2, 5'd3, 5'd4, 5'd5, 5'd6, 5'd7, 5'd8: muxA3 <= 3'd0;
					5'd9, 5'd10, 5'd11, 5'd12, 5'd13, 5'd14, 5'd15, 5'd16: muxA3 <= 3'd1;
					5'd0: begin
						muxA3 <= funConnect[cntA3];
						cntA3 <= cntA3 + 1'b1;
					end
					default: begin
						muxA3 <= 3'd4;
						cntChannel <= 5'd0;
					end
				endcase
				state <= WAIT;
			end
			WAIT: begin
				if (~switchSignal) state <= SETUP;
			end
		endcase
	end
end


endmodule
