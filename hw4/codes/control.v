module Control (
	input	   [7-1:0] i_opcode,
	output reg		   o_ID_control,
	output reg [3-1:0] o_EX_control,
	output reg [2-1:0] o_MEM_control,
	output reg [2-1:0] o_WB_control
);
	// o_ID_control: {Branch}
	// o_EX_control: {ALUOp, ALUSrc}
	// o_MEM_control: {MemRead, MemWrite}
	// o_WB_control: {MemtoReg, RegWrite}
	always @(i_opcode) begin
		case(i_opcode)
			// LD
			7'b0000011: begin
				o_ID_control = 0;
				o_EX_control = 3'b001;
				o_MEM_control = 2'b10;
				o_WB_control = 2'b11;
			end
			// SD
			7'b0100011: begin
				o_ID_control = 0;
				o_EX_control = 3'b001;
				o_MEM_control = 2'b01;
				o_WB_control = 2'b0X;
			end

			// BEQ, BNE
			7'b1100011: begin
				o_ID_control = 1;
				o_EX_control = 3'b010;
				o_MEM_control = 2'b00;
				o_WB_control = 2'bX0;
			end

			// ADDI, XORI, ORI, ANDI, SLLI, SRLI
			7'b0010011: begin
				o_ID_control = 0;
				o_EX_control = 3'b101;
				o_MEM_control = 2'b00;
				o_WB_control = 2'b01;
			end
			// ADD, SUB, XOR, OR, AND
			7'b0110011: begin
				o_ID_control = 0;
				o_EX_control = 3'b100;
				o_MEM_control = 2'b00;
				o_WB_control = 2'b01;
			end

			// OTHER
			default: begin
				o_ID_control = 0;
				o_EX_control = 3'b000;
				o_MEM_control = 2'b00;
				o_WB_control = 2'b00;
			end
		endcase
	end

endmodule