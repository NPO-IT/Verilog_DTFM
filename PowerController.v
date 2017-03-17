module PowerController(
	input 					clk,
	input 					reset,
	input 		[7:0] 	curr_pwr,
	output 		[6:0]		duty
);

reg [22:0] clk_duty;
assign duty = clk_duty[22:15];

always@(posedge clk or negedge reset) begin
	if (~reset) begin 
		clk_duty <= 21'd2097152;
	end else begin

		if(curr_pwr < 8'd210) begin
			if (clk_duty > 7'd1)clk_duty <= clk_duty - 3'b111;
		end
		if(curr_pwr >= 8'd210) begin
			if (clk_duty < 23'd2097152)clk_duty <= clk_duty + 3'b111;
		end
	
	end
end


endmodule
