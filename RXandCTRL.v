module RXandCTRL (
	input reset,
	input clk,
	
	input dMK,
	input dCLK,
	input dDAT,
	
	output bit,
	output val,
	output swch,
	output flush
);

wire sub_if_dat;
wire sub_if_val;
wire sub_fm_dat;
wire sub_fm_rack;
wire sub_fm_emp;

interface rxint(
	.clk(clk),
	.reset(reset),
	.imk(dMK),
	.iclk(dCLK),
	.idat(dDAT),
	.odat(sub_if_dat),
	.oval(sub_if_val),
	.osw(swch),
	.oflush(flush)
);

localfifo rxfifo( 
	.clock(clk), 
	.data(sub_if_dat), 
	.rdreq(sub_fm_rack), 
	.wrreq(sub_if_val), 
   .empty(sub_fm_emp), 
	.sclr(flush),
	.q(sub_fm_dat)
);

markers rxmrk(
	.clk(clk),
	.reset(!flush),
	.iemp(sub_fm_emp),
	.idat(sub_fm_dat),
	.orack(sub_fm_rack),
	.odat(bit),
	.oval(val)
);

endmodule
