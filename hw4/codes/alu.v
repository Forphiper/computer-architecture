module ALU #(
	parameter DATA_W = 64
)(
	input	   [DATA_W-1:0]	i_data_a,
	input	   [DATA_W-1:0]	i_data_b,
	input	   [4-1:0]		i_Optype,
	output reg [DATA_W-1:0] o_data
);

	always @(*) begin
		case(i_Optype)
			// add
			4'b0010: o_data = i_data_a + i_data_b;
			// subtract
			4'b0110: o_data = i_data_a - i_data_b;
			// and
			4'b0000: o_data = i_data_a & i_data_b;
			// or
			4'b0001: o_data = i_data_a | i_data_b;
			// xor
			4'b0011: o_data = i_data_a ^ i_data_b;
			// sll
			4'b0100: o_data = i_data_a << i_data_b[4:0];
			// srl
			4'b0101: o_data = i_data_a >> i_data_b[4:0];
			// other
			default: o_data = 0;
		endcase
	end

endmodule