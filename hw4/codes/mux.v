module Mux #(
	parameter DATA_W = 64
)(
	input	   [2-1:0]		i_control,
	input	   [DATA_W-1:0]	i_data_a,
	input	   [DATA_W-1:0]	i_data_b,
	input	   [DATA_W-1:0]	i_data_c,
	input	   [DATA_W-1:0]	i_data_d,
	output reg [DATA_W-1:0]	o_data
);

	always @(*) begin
		// decide which data can pass
		case(i_control)
			2'b00: o_data = i_data_a;
			2'b01: o_data = i_data_b;
			2'b10: o_data = i_data_c;
			2'b11: o_data = i_data_d;
			default: o_data = 0;
		endcase
	end

endmodule