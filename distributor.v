module distributor
#(
	parameter IGNORED_CHANNEL = 5'd0
)
(
	input						clk,
	input						reset,
	input			[11:0]	data,
	input						valid,
	input			[4:0]		address,
	
	output reg	[11:0]	fData,
	output reg				fRdEn,
	
	output reg	[11:0]	power
);


localparam WAIT_FRONT = 2'd0;
localparam DISTRIBUTE = 2'd1;
localparam WAIT_REAR = 2'd2;
reg 	[1:0]		state;

always@(posedge clk or negedge reset) begin
	if (~reset) begin 
		fRdEn <= 1'b0;
		fData <= 12'd0;
		power <= 12'd0;
		state <= 2'd0;
	end else begin
		case (state)
			WAIT_FRONT: begin
				if(valid) state <= DISTRIBUTE;
			end
			DISTRIBUTE: begin
				case (address)
					IGNORED_CHANNEL: state <= WAIT_FRONT;
					5'd17: begin
						power <= data;
						state <= WAIT_FRONT;
					end
					default: begin
						fData <= data;
						fRdEn <=1'b1;
						state <= WAIT_REAR;
					end
				endcase
			end
			WAIT_REAR: begin
				fRdEn <= 1'b0;
				if(~valid) begin
					state <= WAIT_FRONT;
				end
			end
		endcase
	end
end


endmodule
