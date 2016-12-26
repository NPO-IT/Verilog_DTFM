`timescale 10 ps/10 ps

module DTFM_tb();
reg clk80;
initial begin						// clk 80MHz
	clk80 = 0;
	forever #625 clk80 = ~clk80;
end
DTFM DTFM_tb(
	.clk(clk80)
);

endmodule
