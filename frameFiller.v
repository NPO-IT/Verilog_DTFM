module frameFiller(
	input						clk,	//80
	input						reset,
	input			[11:0]	digitalData,
	input 					digitalDataReady,
	output reg 				digitalDataRequest,
	
	input			[11:0]	analogData,
	output reg				analogDataRequest,
	
	input						orbSwitch,
	output reg	[11:0]	orbData,
	output reg	[9:0]		orbAddr,
	output reg				orbWrEn
);

reg	[2:0]		valReg;
wire				valFront;
reg	[2:0]		fmReg;
wire				fmChange;

always@(posedge clk or negedge reset) begin
	if (~reset) begin valReg <= 3'b0; end
	else begin valReg <= { valReg[1:0],  digitalDataReady }; end
	if (~reset) begin fmReg <= 3'b0; end
	else begin fmReg <= { fmReg[1:0],  orbSwitch }; end
end
assign	valFront	=	(!valReg[2] & valReg[1]);
assign	fmChange = (!fmReg[2] & fmReg[1]) | (fmReg[2] & !fmReg[1]);


reg 	[2:0]		state;
localparam		WAIT_BUFFER = 3'd0;
localparam		CHECK_ADDRESS = 3'd1;
localparam		POLL_DIGITAL = 3'd2;
localparam		POLL_ANALOG = 3'd3;
localparam		WRITE_BUFFER = 3'd4;
localparam		MAKE_ADDRESS = 3'd5;
reg	[2:0]		cntVal;


always@(posedge clk or negedge reset) begin
	if (~reset) begin
		state <= 3'd0;
		digitalDataRequest <= 1'b0;
		cntVal <= 3'd0;
		orbData <= 12'b0;
		orbAddr <= 10'b0;
		orbWrEn <= 1'b0;
		analogDataRequest <= 1'd0;
	end else begin
		case(state)
			WAIT_BUFFER: begin
				if (fmChange) begin
					state <= CHECK_ADDRESS;
					orbAddr <= 10'd0;
				end
			end
			CHECK_ADDRESS: begin
				if(orbAddr[1:0] != 2'd0) begin state <= POLL_DIGITAL; end 
				else begin state <= POLL_ANALOG; end
			end
			POLL_DIGITAL: begin
				digitalDataRequest <= 1'b1;
				if (valFront) begin
					orbData <= digitalData;
					digitalDataRequest <= 1'b0;
					state <= WRITE_BUFFER;
				end
			end
			POLL_ANALOG: begin
				orbData <= analogData;
				analogDataRequest <= 1'b1;
				state <= WRITE_BUFFER;
			end
			WRITE_BUFFER: begin
				analogDataRequest <= 1'b0;
				if (cntVal < 3) begin 			//long WrEn here, even longer if needed
					orbWrEn <= 1'b1;
					cntVal <= cntVal + 1'b1;
				end else begin
					cntVal <= 3'd0;
					orbWrEn <= 1'b0;
					state <= MAKE_ADDRESS;
				end			
			end
			MAKE_ADDRESS: begin
				orbAddr <= orbAddr + 1'b1;
				if (orbAddr == 10'd1023) begin
					state <= WAIT_BUFFER;
				end else begin
					state <= CHECK_ADDRESS;
				end
			end
		endcase
	end
end
endmodule
