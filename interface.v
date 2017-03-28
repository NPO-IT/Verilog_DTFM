module interface (
	input clk,
	input reset,
	input imk,
	input iclk,
	input idat,
	output reg odat,
	output reg oval,
	output reg osw,
	output reg oflush
);

reg	[2:0]		regSync;
wire				syncFront;
always@(posedge clk or negedge reset) begin
	if (~reset) begin regSync <= 3'b0; end
	else begin regSync <= { regSync[1:0],  imk }; end
end
assign	syncFront	=	(!regSync[2] & regSync[1]);

reg	[2:0]		regClk;
wire				clkRear;
always@(posedge clk or negedge reset) begin
	if (~reset) begin regClk <= 3'b0; end
	else begin regClk <= { regClk[1:0],  iclk }; end
end
assign	clkRear		=	(regClk[2] & !regClk[1]);

reg [1:0] state;
always@(posedge clk or negedge reset) begin
	if (~reset) begin
		osw <= 1'b0;
		oflush <= 1'b0;
		state <= 2'd0;
	end else begin 
		case (state)
			0: begin
				if (syncFront) 
					state <= 2'd1;
			end
			1: begin
				osw <= !osw;
				state <= 2'd2;
			end
			2: begin
				oflush <= 1'b1;
				state <= 2'd3;
			end
			3: begin
				oflush <= 1'b0;
				state <= 2'd0;
			end
		endcase
	end
end

reg ena;

always@(posedge clk or negedge reset) begin
	if (~reset) begin 
		odat <= 1'b0;
		oval <= 1'b0;
		ena <= 1'b0;
	end else begin
		if (imk) ena <= 1'b1;
		if (ena) begin
			if(clkRear)begin
				odat <= idat;
				oval <= 1'b1;
			end else begin
				oval <= 1'b0;
			end
		end
	end
end


endmodule
