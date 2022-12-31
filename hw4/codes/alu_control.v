module ALUControl (
	input			   i_inst30,
	input	   [2:0]   i_funct3,
	input	   [1:0]   i_ALUOp,
	output reg [4-1:0] o_ALU_Optype
);

	always @(*) begin
		if(i_ALUOp == 2'b00) begin
			// LD, SD: want ALU do add
			o_ALU_Optype = 4'b0010;
		end
		else if(i_ALUOp == 2'b01) begin
			// BEQ, BNE: want ALU do subtract
			o_ALU_Optype = 4'b0110;
		end
		else begin
			if(i_inst30 == 1) begin
				// SUB: want ALU do subtract
				o_ALU_Optype = 4'b0110;
			end
			else begin
				case(i_funct3)
					// ADD, ADDI: want ALU do add
					3'b000: o_ALU_Optype = 4'b0010;
					// AND, ANDI: want ALU do and
					3'b111: o_ALU_Optype = 4'b0000;
					// OR, ORI: want ALU do or
					3'b110: o_ALU_Optype = 4'b0001;
					// XOR, XORI: want ALU do xor
					3'b100: o_ALU_Optype = 4'b0011;
					// SLLI: want ALU do sll
					3'b001: o_ALU_Optype = 4'b0100;
					// SRLI: : want ALU do srl
					3'b101: o_ALU_Optype = 4'b0101;
					// OTHER
					default: o_ALU_Optype = 4'bXXXX;
				endcase
			end
		end
	end


endmodule