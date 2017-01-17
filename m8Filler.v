module m8Filler(
	input reset,
	input clk,
	input bufGetWord,
	input [9:0]bufRdPointer,
	input [4:0]cntGrp,
	output reg [11:0]dataWord
);

reg once3, once2, once1;
reg [7:0]dat1;
reg [9:0]slow128, dat1012;
reg [4:0]grpCnt;

always@(negedge reset or posedge clk)begin
	if (~reset) begin
		dataWord <= 0;
		dat1012 <= 0;
		once1 <= 0;
		once2 <= 0;
		once3 <= 0;
		slow128 <= 0;
		dat1 <= 0;
		grpCnt <= 0;
	end else begin
			if(bufGetWord) begin
				case((bufRdPointer))
					0:
					begin
						dataWord <= {1'b0, dat1012[9:0],1'b1};
						if(once1==0)begin
							dat1012 <= dat1012 - 1'b1;
							once1<=1;
						end
					end
					297:
					begin
						dataWord <= {1'b0, slow128[9:0], 1'b0};
						if (once3 == 0) begin
							once3 <= 1;
							if (cntGrp == 0)				// on this stage = 4hz
								slow128 <= slow128 + 1'b1;
						end
					end
					2,34,66,98,130,162,194,226,258,290,322,354,386,418,450,482,514,546,578,610,642,674,706,738,770,802,834,866,898,930,962,994:
					begin
						dataWord <= {1'b0, dat1[7:0],3'b1};
						if(once2==0) begin
							dat1 <= dat1 + 1'b1;
							once2=1;
						end
					end
					default: begin
						dataWord <= {1'b0, 8'd0, 3'b010};
						once1<=0;
						once2<=0;
						once3<=0;
					end
				endcase
			end

	end
end
endmodule
