/*
	Ivan I. Ovchinnikov
	last upd.: 2016.04.25
	
	up to 32 bytes * 8 bits, startbit 0, stopbit 1, 
	no parity, MSB sequence, multiplexed input. 
	additional IP needed: 1-port ROM (uROM_bb.v)
	modify uROM.hex
*/

module UARTTX
#(
	parameter BYTES = 1
)
(
	input reset,					// global reset and enable signal
	input clk,						// actual needed baudrate (tested on 4,8 MHz)
	input RQ,						// start transfer signal
	input [7:0] data,
	output reg tx,					// serial transmitted data
	output reg dirTX,				// rs485 TX dir controller 
	output reg dirRX				// rs485 RX dir controller
);

	reg [4:0]switch;		// memory switcher

	localparam WAIT=0, MEGAWAIT=1, DIRON=2, TX=3, DIROFF=4;

reg [2:0] state;
reg [3:0] serialize;
reg [4:0] delay;
reg [1:0] rqsync;

always@(posedge clk) begin			// double d-flipflop to avoid metastability
	rqsync <= { rqsync[0],  RQ };	// start signal from other clock domain
end

always@(posedge clk or negedge reset)
begin
if (~reset) begin					// global asyncronous reset, initial values
	state <= 1'b0;
	serialize <= 0;
	delay <= 1'b0;
	tx <= 1'b1;
	switch <= 0;
end else begin						// main circuit
	case (state)					// state machine
		WAIT: begin					// waiting for transfer request
			if (rqsync[1]) state <= DIRON;		// just move on
		end
		DIRON: begin 				// set the DIR pins to high level with a tiny delay
			delay <= delay + 1'b1;	// count while in this state
			if (delay == 0) begin dirRX <= 1; end
			if (delay == 15) begin dirTX <= 1; end
			if (delay == 30) begin state <= TX; end	// proceed to next state
		end
		TX: begin					// the transfer
			serialize <= serialize + 1'b1;		// count while in this state
			case (serialize)					// make a sequence while here
				0: begin 
					tx <= 0;  		// startbit
					delay <= 0;		// reset previous counter
				end
				1,2,3,4,5,6,7,8: tx <= data[((serialize - 1))];	// transmit every bit of data
				9: begin 
					tx <= 1;		// stopbit
					switch <= switch + 1'b1;	// switch multiplexor
				end
				10: begin
					serialize <= 0; // reset sequencer
					if (switch == BYTES) begin switch <=0; state <= DIROFF; end	// if completed transfer proceed to next state 
				end	
			endcase
		end
		DIROFF: begin				// set the DIR pins to low level with a tiny delay
			delay <= delay + 1'b1;	// count while in this state
			if (delay == 15) begin dirTX <= 0; end
			if (delay == 30) begin dirRX <= 0; state <= MEGAWAIT; end	// proceed to next state
		end
		MEGAWAIT: begin			// checking the low level of request signal
			delay <= 0;				// reset previous counter
			if (~rqsync[1]) state <= WAIT; // just move on
		end
	endcase 
end
end
endmodule
