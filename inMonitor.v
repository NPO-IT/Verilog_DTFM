module inMonitor (
	input reset, 
	input clk, 
	input dMK, 
	input inBit, 
	input inVal,
	output reg sendUART, 
	output reg [7:0] data
);

reg	[2:0]		regMK;
reg	[2:0]		regVAL;
wire				MKFront;
wire				VALFront;
always@(posedge clk or negedge reset) begin
	if (~reset) begin regMK <= 3'b0; end
	else begin regMK <= { regMK[1:0],  dMK }; end

	if (~reset) begin regVAL <= 3'b0; end
	else begin regVAL <= { regVAL[1:0],  inVal }; end
end
assign	MKFront		=	(!regMK[2] & regMK[1]);
assign	VALFront		=	(!regVAL[2] & regVAL[1]);

reg [2:0] ptr;
reg [2:0] state;
reg [2:0] delay;
always@(posedge clk or negedge reset) begin
	if (~reset) begin 
		sendUART <= 1'b0;
		data <= 8'd0;
		state <= 3'd0;
		ptr <= 3'd7;
		delay <= 3'd0;
	end else begin 
		case (state)
			0: if (MKFront) state <= 3'd1;
			1: begin
				if (VALFront) begin
					data[ptr] <= inBit;
					ptr <= ptr - 1'b1;
					state <= 3'd2;
				end
			end
			2: begin
				if (ptr == 3'd7) begin
					sendUART <= 1'b1;
					state <= 3'd3;
				end else begin
					state <= 3'd1;
				end
			end
			3: begin
				delay <= delay + 1'b1;
				if (delay == 3'd7) begin
					state <= 3'd0;
					sendUART <= 1'b0;
				end
			end
		endcase
	end
end



endmodule
