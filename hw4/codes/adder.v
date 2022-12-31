module Adder #(
	parameter DATA_W = 64
)(
	input	   [DATA_W-1:0]	i_data_a,
	input	   [DATA_W-1:0]	i_data_b,
	output reg [DATA_W-1:0]	o_data
);
	reg	[13-1:0] data_b_positive;

	always @(*) begin
		// check if i_data_b is negative
		if(i_data_b[12] == 1) begin 
			data_b_positive = ~i_data_b[12:0] + 1; // 2's complement
			o_data = i_data_a - {51'b0, data_b_positive};
		end
		else begin
			o_data = i_data_a + i_data_b;
		end
	end

endmodule