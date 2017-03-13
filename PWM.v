module PWM (
	input						clk,
	input						reset,
	input			[6:0]		duty,
	output reg				out
);

reg	[6:0]		counter;

always@(negedge reset or posedge clk) begin
	if(~reset)begin
		counter <= 7'd0;
		out <= 1'b0;
	end else begin
		if(counter <= duty) begin
			out <= 1'b1;
		end else begin
			out <= 1'b0;
		end
		counter <= counter + 1'b1;
	end

end
endmodule
