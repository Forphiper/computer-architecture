module ShiftLeftOne #(
	parameter ADDR_W = 64
)(
	input	   [ADDR_W-1:0]	i_data,
	output reg [ADDR_W-1:0]	o_data
);

	always @(*) begin
        o_data = {51'b0, i_data[12:1], 1'b0};
	end

endmodule