module HazardDetectionUnit (
	input	   [5-1:0] i_IFID_rs1,
	input	   [5-1:0] i_IFID_rs2,
	input	   [5-1:0] i_IDEX_rd,
	input			   i_IDEX_MemRead,
	output reg         o_stall
);

	always @(*) begin
		// detect load-use data hazard
		// if there's hazard, need to stall the pipeline
		if(i_IDEX_MemRead &&
		   (i_IFID_rs1 == i_IDEX_rd ||
			i_IFID_rs2 == i_IDEX_rd)) begin
				o_stall = 1;
		end
		else begin
			o_stall = 0;
		end
	end
	


endmodule