module switcherMUX (
	input				reset,
	input 			clk,
	input 			switchSignal,
	output reg		A01,
	output reg		A11,
	output reg		A21,
	
	output reg		A02,
	output reg		A12,
	output reg		A22,
	
	output reg		A03,
	output reg		A13,
	output reg		A23
);

localparam SETUP = 2'd0;
localparam PREPARE = 2'd1;
localparam WAIT = 2'd2;

reg	[1:0]		state;
reg	[4:0]		cntChannels;
reg	[2:0]		muxAddress;

always@(posedge clk or negedge reset) begin
	if (~reset) begin
		muxAddress <= 3'd0;
		state <= 2'd0;
		cntChannels <= 5'd0;
		A01 <= 1'b0;
		A11 <= 1'b0;
		A21 <= 1'b0;
		A02 <= 1'b0;
		A12 <= 1'b0;
		A22 <= 1'b0;
		A03 <= 1'b0;
		A13 <= 1'b0;
		A23 <= 1'b0;
	end else begin
		case(state)
			SETUP: begin
				if (switchSignal)begin
					cntChannels <= cntChannels + 1'b1;
					state <= PREPARE;
				end
			end
			PREPARE: begin
				case(cntChannels)
					0,1,2,3,4,5,6,7: begin
						A03 <= 1'b1;
						A13 <= 1'b0;
						A23 <= 1'b0;
						muxAddress <= cntChannels[2:0];
					end
					8,9,10,11,12,13,14: begin
						A03 <= 1'b0;
						A13 <= 1'b1;
						A23 <= 1'b0;
						muxAddress <= cntChannels[2:0];
					end
					15: begin
						A03 <= 1'b1;
						A13 <= 1'b1;
						A23 <= 1'b0;
					end
					16: begin
						A03 <= 1'b0;
						A13 <= 1'b0;
						A23 <= 1'b1;
					end
					17: begin
						A03 <= 1'b1;
						A13 <= 1'b0;
						A23 <= 1'b1;
						cntChannels <= 5'd0;
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
