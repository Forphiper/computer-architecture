module ForwardingUnit (
	input	   [5-1:0] i_IDEX_rs1,
	input	   [5-1:0] i_IDEX_rs2,
	input	   [5-1:0] i_EXMEM_rd,
	input			   i_EXMEM_RegWrite,
	input	   [5-1:0] i_MEMWB_rd,
	input			   i_MEMWB_RegWrite,
	output reg [2-1:0] o_ForwardA,
	output reg [2-1:0] o_ForwardB
);

	always @(*) begin
		// EX hazard of rs1
		if(i_EXMEM_RegWrite &&
		   i_EXMEM_rd != 0 &&
		   i_EXMEM_rd == i_IDEX_rs1) begin
		    o_ForwardA = 2'b10;
		end
		// MEM hazard of rs1
		else if(i_MEMWB_RegWrite &&
		   i_MEMWB_rd != 0 &&
		   !(i_EXMEM_RegWrite && i_EXMEM_rd != 0 && 
		   i_EXMEM_rd == i_IDEX_rs1) &&
		   i_MEMWB_rd == i_IDEX_rs1) begin
			o_ForwardA = 2'b01;
		end
		else begin
			o_ForwardA = 2'b00;
		end

		// EX hazard of rs2
		if(i_EXMEM_RegWrite &&
		   i_EXMEM_rd != 0 &&
		   i_EXMEM_rd == i_IDEX_rs2) begin
		    o_ForwardB = 2'b10;
		end
		// MEM hazard of rs2
		else if(i_MEMWB_RegWrite &&
		   i_MEMWB_rd != 0 &&
		   !(i_EXMEM_RegWrite && i_EXMEM_rd != 0 &&
		   i_EXMEM_rd == i_IDEX_rs2) &&
		   i_MEMWB_rd == i_IDEX_rs2) begin
			o_ForwardB = 2'b01;
		end
		else begin
			o_ForwardB = 2'b00;
		end
	end


endmodule