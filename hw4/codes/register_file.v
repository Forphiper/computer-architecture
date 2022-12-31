module RegisterFile #(
	parameter DATA_W = 64
)(
	input                   i_clk,
    input                   i_rst_n,
	input	   [5-1:0]	    i_read_register1,
	input	   [5-1:0] 		i_read_register2,
	input	   [5-1:0] 		i_write_register,
	input					i_RegWrite,
	input	   [DATA_W-1:0]	i_write_data,
	output reg [DATA_W-1:0]	o_read_data1,
	output reg [DATA_W-1:0]	o_read_data2
);
	
	reg [DATA_W-1:0] registers[0:31];
	reg [DATA_W-1:0] registers_w[0:31];
	integer i;

	always @(*) begin
		for(i = 0; i < 32; i = i + 1) begin
			registers_w[i] = registers[i];
		end
		if(i_RegWrite) begin
			registers_w[i_write_register] = i_write_data;
		end
		else begin
			registers_w[i_write_register] = registers[i_write_register];
		end
		o_read_data1 = registers_w[i_read_register1];
		o_read_data2 = registers_w[i_read_register2];
	end

	always @(posedge i_clk or negedge i_rst_n) begin
		if(!i_rst_n) begin
			for(i = 0; i < 32; i = i + 1) begin
				registers[i] <= 0;
			end
		end
		else begin
			for(i = 0; i < 32; i = i + 1) begin
				registers[i] <= registers_w[i];
			end
		end
	end

endmodule