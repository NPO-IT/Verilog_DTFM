module PWM (
	input					clk,
	input					reset,
	input			[9:0]	in,
	output reg			out
);

reg[9:0] counter;

always@(negedge reset or posedge clk) begin
	if(~reset)begin
		counter <= 10'd0;
		out <= 1'b0;
	end else begin
		if(counter <= in) begin
			out <= 1'b1;
		end else begin
			out <= 1'b0;
		end
		counter <= counter + 1'b1;
	end

end
endmodule
