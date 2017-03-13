module switcher (
	input						reset,
	input 					clk,
	input 					spiReceived,
	output reg	[2:0]		MxA3,
	output reg	[2:0]		MxA12,
	output reg	[4:0]		rxAddress
);

localparam WAIT = 2'd0;
localparam PREPARE = 2'd1;
localparam SETUP = 2'd2;
localparam RETURN = 2'd3;
wire	[2:0]		funConnect	[0:3];
assign funConnect[2'd0] = 3'd5;		//gnd
assign funConnect[2'd1] = 3'd2;		//min
assign funConnect[2'd2] = 3'd5;		//gnd
assign funConnect[2'd3] = 3'd3;		//max

reg	[2:0]		rxReg;
wire				rxFront;
always@(posedge clk or negedge reset) begin
	if (~reset) begin rxReg <= 3'b0; end
	else begin rxReg <= { rxReg[1:0],  spiReceived }; end
end
assign	rxFront	=	(!rxReg[2] & rxReg[1]);

reg	[1:0]		state;
reg	[4:0]		address;
reg	[2:0]		_MxA3;
reg	[2:0]		_MxA12;
reg	[1:0]		calib;

always@(posedge clk or negedge reset) begin
	if (~reset) begin
		MxA3 <= 3'd0;
		_MxA3 <= 3'd0;
		MxA12 <= 3'd0;
		_MxA12 <= 3'd0;
		calib <= 2'd0;
		address <= 5'd1;
		rxAddress <= 5'd0;
		state <= WAIT;
	end else begin
		case (state)
			WAIT: if (rxFront) state <= PREPARE;
			PREPARE: begin
				address <= address + 1'b1;
				rxAddress <= address;
				case (address)
					5'd0: begin
						_MxA3 = funConnect[calib];
						calib <= calib + 1'b1;
					end
					5'd1, 5'd2, 5'd3, 5'd4, 5'd5, 5'd6, 5'd7, 5'd8: begin
						_MxA3 <= 3'd0;
						_MxA12 <= address[3:0] - 1'b1;
					end
					5'd9, 5'd10, 5'd11, 5'd12, 5'd13, 5'd14, 5'd15, 5'd16: begin
						_MxA3 <= 3'd1;
						_MxA12 <= address[3:0] - 1'b1;
					end
					default: begin
						_MxA3 <= 3'd4;
						address <= 5'd0;
					end
				endcase
				state <= SETUP;
			end
			SETUP: begin
				MxA3 <= _MxA3;
				MxA12 <= _MxA12;
				state <= RETURN;
			end
			RETURN: begin
				state <= WAIT;
			end
		endcase
	end
end

endmodule
