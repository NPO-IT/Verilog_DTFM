module PowerController(
	input 					clk,
	input 					reset,
	input 		[7:0] 	curr_pwr,		//0-255 0.8 = 193-194
	output 		[6:0]		duty
);

reg [6:0] clk_duty;
assign duty = {1'b0, clk_duty[5:0]};

always@(posedge clk or negedge reset) begin
	if (~reset) begin 
		clk_duty <= 7'd29;
	end else begin 
		if (curr_pwr < 8'd192) begin
			if (clk_duty > 6'd0) 
				clk_duty <= clk_duty - 1'b1;
		end else if (curr_pwr > 8'd194)begin
			if (clk_duty < 6'd127) 
				clk_duty <= clk_duty + 1'b1;
		end
		
	end
end


endmodule
