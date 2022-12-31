module PCSrc #(
	parameter DATA_W = 64
)(
	input	                i_Branch,
	input	                i_inst12,
	input      [DATA_W-1:0] i_read_data1,
	input      [DATA_W-1:0] i_read_data2,
	output reg              o_PCSrc
);

	always @(*) begin
		if(i_Branch) begin
			// BEQ and branch taken
			if(i_inst12 == 0 && 
			   (i_read_data1 == i_read_data2)) begin
			    o_PCSrc = 1;
			end
			// BNE and branch taken
			else if(i_inst12 == 1 && 
			   (i_read_data1 != i_read_data2)) begin
				o_PCSrc = 1;
			end
			else begin
				o_PCSrc = 0;
			end
		end
		else begin
			o_PCSrc = 0;
		end
	end

endmodule