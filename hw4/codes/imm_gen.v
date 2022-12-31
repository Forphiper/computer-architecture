module ImmGen #(
	parameter INST_W = 32,
	parameter DATA_W = 64
)(
	input	   [INST_W-1:0] i_inst,
	output reg [DATA_W-1:0]	o_imm
);

	reg [7-1:0] opcode;
	
	always @(i_inst) begin
		opcode = i_inst[6:0];
		case(opcode)
			// LD
			7'b0000011: o_imm = {52'b0, i_inst[31:20]};
			// SD
			7'b0100011: o_imm = {52'b0, i_inst[31:25], i_inst[11:7]};
			// BEQ, BNE
			7'b1100011: o_imm = {51'b0, i_inst[31], i_inst[7], i_inst[30:25], i_inst[11:8], 1'b0};
			// ADDI, XORI, ORI, ANDI, SLLI, SRLI
			7'b0010011: o_imm = {52'b0, i_inst[31:20]};
			// OTHER
			default: o_imm = 0;
		endcase
	end

endmodule