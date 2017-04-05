module markers (
	input clk,
	input reset,
	input iemp,
	input idat,
	output reg orack,
	output reg odat,
	output reg oval
);

wire	[30:0]	M 	=	31'b1111100110100100001010111011000;
wire	[30:0]	nM	=	31'b0000011001011011110101000100111;
wire	[12:0]	B	=	13'b1111100110101;
wire	[12:0]	nB	=	13'b0000011001010;
wire	[43:0]	mark	[0:3];
assign	mark[0]	=	{ M,	B	};
assign	mark[1]	=	{ nM,	B	};
assign	mark[2]	=	{ M,	nB	};
assign	mark[3]	=	{ nM,	nB	};

localparam WRITE_MARKER = 3'd0;
localparam WRITE_DATA = 3'd1;
localparam CHECK = 3'd3;

reg	[1:0]		m;
reg	[2:0]		state;
reg	[3:0]		sequence;
reg	[43:0]	current_marker;
reg	[5:0]		marker_pointer;
reg	[11:0]	bit;
always@(posedge clk or negedge reset) begin
	if (~reset) begin
		m <= 2'b00;
		bit <= 12'd0;
		state <= WRITE_MARKER;
		sequence <= 4'd0;
		current_marker <= mark[0];
		marker_pointer <= 6'd43;
		orack <= 1'b0;
		odat <= 1'b0;
		oval <= 1'b0;
	end else begin
		case (state)
			WRITE_MARKER: begin
				sequence <= sequence + 1'b1;
				case (sequence)
					0, 1, 2: current_marker <= mark[m];
					3, 4, 5: odat <= current_marker[marker_pointer];
					6: oval <= 1'b1;
					7: begin
						oval <= 1'b0;
						marker_pointer <= marker_pointer - 1'b1;
					end
					10: begin
						if (marker_pointer == 6'd63) begin
							state <= WRITE_DATA;
							sequence <= 4'd0;
							m <= m + 1'b1;
						end else begin
							sequence <= 4'd1;
						end
					end
				endcase
			end
			WRITE_DATA: begin
				marker_pointer <= 6'd43;
				case (sequence)
					0: begin
						if(!iemp) begin
							odat <= idat;
							sequence <= 4'd1;
						end
					end
					1: begin
						orack <= 1'b1;
						oval <= 1'b1;
						bit <= bit + 1'b1;
						sequence <= 4'd2;
					end
					2: begin
						orack <= 1'b0;
						oval <= 1'b0;
						sequence <= 4'd0;
						state <= CHECK;
					end
				endcase
			end
			CHECK: begin
				if (bit == 12'd2816) begin
					state <= WRITE_MARKER;
					bit <= 12'd0;
				end else begin
					state <= WRITE_DATA;
				end
			end
		endcase
	end
end


endmodule
