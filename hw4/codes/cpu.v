module cpu #( // Do not modify interface
	parameter ADDR_W = 64,
	parameter INST_W = 32,
	parameter DATA_W = 64
)(
    input                   i_clk,
    input                   i_rst_n,
    input                   i_i_valid_inst, // from instruction memory
    input  [ INST_W-1 : 0 ] i_i_inst,       // from instruction memory
    input                   i_d_valid_data, // from data memory
    input  [ DATA_W-1 : 0 ] i_d_data,       // from data memory
    output                  o_i_valid_addr, // to instruction memory
    output [ ADDR_W-1 : 0 ] o_i_addr,       // to instruction memory
    output [ DATA_W-1 : 0 ] o_d_w_data,     // to data memory
    output [ ADDR_W-1 : 0 ] o_d_w_addr,     // to data memory
    output [ ADDR_W-1 : 0 ] o_d_r_addr,     // to data memory
    output                  o_d_MemRead,    // to data memory
    output                  o_d_MemWrite,   // to data memory
    output                  o_finish
);


    // wires and registers
    reg              o_i_valid_addr_w, o_i_valid_addr_r;
    reg [ADDR_W-1:0] o_i_addr_w, o_i_addr_r;
    reg [DATA_W-1:0] o_d_w_data_w, o_d_w_data_r;
    reg [ADDR_W-1:0] o_d_w_addr_w, o_d_w_addr_r;
    reg [ADDR_W-1:0] o_d_r_addr_w, o_d_r_addr_r;
    reg              o_d_MemRead_w, o_d_MemRead_r;
    reg              o_d_MemWrite_w, o_d_MemWrite_r;
    reg              o_finish_w, o_finish_r;

    // IF/ID register
    reg [ADDR_W-1:0] IFID_PC_r;
    reg [INST_W-1:0] IFID_inst_r;

    // ID/EX register
    reg [DATA_W-1:0] IDEX_read_data1_r;
    reg [DATA_W-1:0] IDEX_read_data2_r;
    reg [DATA_W-1:0] IDEX_imm_r;
    reg              IDEX_inst30_r;
    reg [3-1:0]      IDEX_funct3_r;
    reg [5-1:0]      IDEX_rs1_r;
    reg [5-1:0]      IDEX_rs2_r;
    reg [5-1:0]      IDEX_rd_r;
    reg [3-1:0]      IDEX_EX_control_r;
    reg [2-1:0]      IDEX_MEM_control_r;
    reg [2-1:0]      IDEX_WB_control_r;

    // EX/MEM register
    reg [DATA_W-1:0] EXMEM_ALU_result_data_r;
    reg [DATA_W-1:0] EXMEM_write_data_r;
    reg [5-1:0]      EXMEM_rd_r;
    reg [2-1:0]      EXMEM_MEM_control_r;
    reg [2-1:0]      EXMEM_WB_control_r;

    // MEM/WB register
    reg [DATA_W-1:0] MEMWB_dm_read_data_r;
    reg [DATA_W-1:0] MEMWB_ALU_result_data_r;
    reg [5-1:0]      MEMWB_rd_r;
    reg [2-1:0]      MEMWB_WB_control_r;

    // IF stage
    reg  [ADDR_W-1:0] IF_PC_r;
    reg  [INST_W-1:0] IF_inst_r;
    reg [ADDR_W-1:0] IF_PC_prev;
    reg [INST_W-1:0] IF_inst_prev;
    wire [ADDR_W-1:0] IF_PC_add_four;
    wire [ADDR_W-1:0] IF_PC_next;
    wire              IF_PCSrc;

    // ID stage
    wire [DATA_W-1:0] ID_read_data1, ID_read_data2;
    wire [DATA_W-1:0] ID_imm;
    wire [ADDR_W-1:0] ID_imm_shift_left_one;
    wire              ID_Branch;
    wire [3-1:0]      ID_EX_control;
    wire [2-1:0]      ID_MEM_control;
    wire [2-1:0]      ID_WB_control;
    wire [DATA_W-1:0] ID_control;
    wire [ADDR_W-1:0] ID_PC_branch;
    wire              ID_is_stall;

    // EX stage
    wire [2-1:0]      EX_ForwardA_control;
    wire [2-1:0]      EX_ForwardB_control;
    wire [DATA_W-1:0] EX_ALU_src_data1;
    wire [DATA_W-1:0] EX_ALU_src_data2;
    wire [DATA_W-1:0] EX_ALU_forward_data;
    wire [DATA_W-1:0] EX_ALU_result_data;
    wire [4-1:0]      EX_ALU_op_type;

    // MEM stage
    reg [DATA_W-1:0] MEM_dm_read_data_r;
    
    // WB stage
    wire [DATA_W-1:0] WB_WBtoReg_data;
    
    // others
    integer count_cycles;
    integer is_load_use_hazard;
    integer is_inst_changed;

    // continuous assign
    assign o_i_valid_addr = o_i_valid_addr_r;
    assign o_i_addr = o_i_addr_r;
    assign o_d_w_data = o_d_w_data_r;
    assign o_d_w_addr = o_d_w_addr_r;
    assign o_d_r_addr = o_d_r_addr_r;
    assign o_d_MemRead = o_d_MemRead_r;
    assign o_d_MemWrite = o_d_MemWrite_r;
    assign o_finish = o_finish_r;

    // IF/ID register
    always @(count_cycles) begin
        // update every 4 cycles
        if(count_cycles == 4) begin
            if(!is_load_use_hazard) begin
                IFID_PC_r <= IF_PC_r;
                IFID_inst_r <= IF_inst_r;
            end
        end
    end

    // ID/EX register
    always @(count_cycles) begin
        // update every 4 cycles
        if(count_cycles == 4) begin
            IDEX_read_data1_r <= ID_read_data1;
            IDEX_read_data2_r <= ID_read_data2;
            IDEX_imm_r <= ID_imm;

            IDEX_inst30_r <= IFID_inst_r[30]; 
            IDEX_funct3_r <= IFID_inst_r[14:12]; 

            IDEX_rs1_r <= IFID_inst_r[19:15]; 
            IDEX_rs2_r <= IFID_inst_r[24:20]; 
            IDEX_rd_r <= IFID_inst_r[11:7];

            IDEX_EX_control_r <= ID_control[6:4];
            IDEX_MEM_control_r <= ID_control[3:2];
            IDEX_WB_control_r <= ID_control[1:0];
        end
    end

    // EX/MEM register
    always @(count_cycles) begin
        // update every 4 cycles
        if(count_cycles == 4) begin
            EXMEM_ALU_result_data_r <= EX_ALU_result_data;
            EXMEM_write_data_r <= EX_ALU_forward_data;
            EXMEM_rd_r <= IDEX_rd_r;

            EXMEM_MEM_control_r <= IDEX_MEM_control_r;
            EXMEM_WB_control_r <= IDEX_WB_control_r;
        end
    end

    // MEM/WB register
    always @(count_cycles) begin
        // update every 4 cycles
        if(count_cycles == 4) begin
            MEMWB_dm_read_data_r <= MEM_dm_read_data_r;
            MEMWB_ALU_result_data_r <= EXMEM_ALU_result_data_r;
            MEMWB_rd_r <= EXMEM_rd_r;
            
            MEMWB_WB_control_r <= EXMEM_WB_control_r;
        end
    end
    
    // IF stage
    always @(i_i_valid_inst) begin
        // instruction memory
        if(i_i_valid_inst) begin
            is_inst_changed = (IF_inst_r != i_i_inst)? 1 : 0;

            IF_inst_r = i_i_inst;
            IF_PC_r = o_i_addr_w;

            IF_inst_prev = IF_inst_r;
            IF_PC_prev = IF_PC_r;

            // STOP: wait for remaining inst in pipeline to finish
            if(IF_inst_r == {32{1'b1}}) begin
                #100
                count_cycles = 0;
                #100
                count_cycles = 0;
                #100
                count_cycles = 0;

                o_finish_w = 1;
            end
            else begin
                o_finish_w = 0;
            end
        end
        else begin
            IF_inst_r = IF_inst_prev;
            IF_PC_r = IF_PC_prev;
            IF_PC_prev = 0;
            IF_inst_prev = 0;
            o_finish_w = 0;
        end
    end

    always @(IF_PC_next or is_inst_changed) begin
        o_i_valid_addr_w = 1;
        o_i_addr_w = (is_load_use_hazard)? IF_PC_r : IF_PC_next;

        is_load_use_hazard = 0;
        count_cycles = 0;
    end
    
    always @(count_cycles) begin
        if(count_cycles == 0) begin
            o_i_valid_addr_w = 1;
        end
        else begin
            o_i_valid_addr_w = 0;
        end
    end
    

    Adder #(
        .DATA_W(DATA_W)
    ) adderAddFour (
        .i_data_a(IF_PC_r),
        .i_data_b(64'd4),
        .o_data(IF_PC_add_four)
    );

    Mux #(
        .DATA_W(DATA_W)
    ) muxPCSrc (
        .i_control({1'b0, IF_PCSrc}),
        .i_data_a(IF_PC_add_four),
        .i_data_b(ID_PC_branch),
        .i_data_c(64'b0),
        .i_data_d(64'b0),
        .o_data(IF_PC_next)
    );

    // ID stage
    always @(ID_is_stall) begin
        if(ID_is_stall) begin
            is_load_use_hazard = 1;
        end
    end

    RegisterFile #(
        .DATA_W(DATA_W)
    ) registerFile (
        .i_clk(i_clk),
        .i_rst_n(i_rst_n),
        .i_read_register1(IFID_inst_r[19:15]),
        .i_read_register2(IFID_inst_r[24:20]), 
        .i_write_register(MEMWB_rd_r),
        .i_RegWrite(MEMWB_WB_control_r[0]),
        .i_write_data(WB_WBtoReg_data),
        .o_read_data1(ID_read_data1),
        .o_read_data2(ID_read_data2)
    );

    Control control (
        .i_opcode(IFID_inst_r[6:0]),
        .o_ID_control(ID_Branch),
        .o_EX_control(ID_EX_control),
        .o_MEM_control(ID_MEM_control),
        .o_WB_control(ID_WB_control)
    );

    Mux #(
        .DATA_W(DATA_W)
    ) muxControl (
        .i_control({1'b0, ID_is_stall}),
        .i_data_a({57'b0, ID_EX_control, ID_MEM_control, ID_WB_control}),
        .i_data_b(64'b0),
        .i_data_c(64'b0),
        .i_data_d(64'b0),
        .o_data(ID_control)
    );

    ImmGen #(
        .INST_W(INST_W),
        .DATA_W(DATA_W)
    ) immGen (
        .i_inst(IFID_inst_r),
        .o_imm(ID_imm)
    );

    PCSrc #(
        .DATA_W(DATA_W)
    ) pcSrc (
        .i_Branch(ID_Branch),
        .i_inst12(IFID_inst_r[12]),
        .i_read_data1(ID_read_data1),
        .i_read_data2(ID_read_data2),
        .o_PCSrc(IF_PCSrc)
    );

    ShiftLeftOne #(
        .ADDR_W(ADDR_W)
    ) shiftLeftOne (
        .i_data(ID_imm),
        .o_data(ID_imm_shift_left_one)
    );

    Adder #(
        .DATA_W(DATA_W)
    ) adderBranch (
        .i_data_a(IFID_PC_r), //
        .i_data_b(ID_imm_shift_left_one),
        .o_data(ID_PC_branch)
    );

    HazardDetectionUnit hazardDetectiionUnit (
        .i_IFID_rs1(IFID_inst_r[19:15]),
        .i_IFID_rs2(IFID_inst_r[24:20]),
        .i_IDEX_rd(IDEX_rd_r),
        .i_IDEX_MemRead(IDEX_EX_control_r[1]),
        .o_stall(ID_is_stall)
    );

    // EX stage
    Mux #(
        .DATA_W(DATA_W)
    ) muxALUSrc1 (
        .i_control(EX_ForwardA_control),
        .i_data_a(IDEX_read_data1_r),
        .i_data_b(WB_WBtoReg_data),
        .i_data_c(EXMEM_ALU_result_data_r),
        .i_data_d(64'b0),
        .o_data(EX_ALU_src_data1)
    );

    Mux #(
        .DATA_W(DATA_W)
    ) muxALUSrc2FirstLevel (
        .i_control(EX_ForwardB_control),
        .i_data_a(IDEX_read_data2_r),
        .i_data_b(WB_WBtoReg_data),
        .i_data_c(EXMEM_ALU_result_data_r),
        .i_data_d(64'b0),
        .o_data(EX_ALU_forward_data)
    );
    
    Mux #(
        .DATA_W(DATA_W)
    ) muxALUSrc2SecondLevel (
        .i_control({1'b0, IDEX_EX_control_r[0]}), // if I-type, then pass imm to ALU
        .i_data_a(EX_ALU_forward_data),
        .i_data_b(IDEX_imm_r),
        .i_data_c(64'b0),
        .i_data_d(64'b0),
        .o_data(EX_ALU_src_data2)
    );

    ALUControl aluControl (
        .i_inst30(IDEX_inst30_r),
        .i_funct3(IDEX_funct3_r),
        .i_ALUOp(IDEX_EX_control_r[2:1]),
        .o_ALU_Optype(EX_ALU_op_type)
    );

    ALU #(
        .DATA_W(DATA_W)
    ) alu (
        .i_data_a(EX_ALU_src_data1),
        .i_data_b(EX_ALU_src_data2),
        .i_Optype(EX_ALU_op_type),
        .o_data(EX_ALU_result_data)
    );

    ForwardingUnit forwardingUnit (
        .i_IDEX_rs1(IDEX_rs1_r),
        .i_IDEX_rs2(IDEX_rs2_r),
        .i_EXMEM_rd(EXMEM_rd_r),
        .i_EXMEM_RegWrite(EXMEM_WB_control_r[0]),
        .i_MEMWB_rd(MEMWB_rd_r),
        .i_MEMWB_RegWrite(MEMWB_WB_control_r[0]),
        .o_ForwardA(EX_ForwardA_control),
        .o_ForwardB(EX_ForwardB_control)
    );

    // MEM stage
    always @(*) begin
        // check if MemRead is set to 1
        if(EXMEM_MEM_control_r[1] == 1) begin 
            o_d_w_data_w = 0;
            o_d_w_addr_w = 0;
            o_d_r_addr_w = EXMEM_ALU_result_data_r;
            o_d_MemRead_w = 1;
            o_d_MemWrite_w = 0;
        end
        // check if MemWrite is set to 1
        else if(EXMEM_MEM_control_r[0] == 1) begin
            o_d_w_data_w = EXMEM_write_data_r;
            o_d_w_addr_w = EXMEM_ALU_result_data_r;
            o_d_r_addr_w = 0;
            o_d_MemRead_w = 0;
            o_d_MemWrite_w = 1;
        end
        else begin
            o_d_w_data_w = 0;
            o_d_w_addr_w = 0;
            o_d_r_addr_w = 0;
            o_d_MemRead_w = 0;
            o_d_MemWrite_w = 0;
        end
    end

    always @(i_d_valid_data) begin
        // get data from data memory
        if(i_d_valid_data) begin
            MEM_dm_read_data_r = i_d_data;
        end
        else begin
            MEM_dm_read_data_r = 0;
        end
    end

    // WB stage
    Mux #(
        .DATA_W(DATA_W)
    ) muxWBtoReg (
        .i_control({1'b0, MEMWB_WB_control_r[1]}),
        .i_data_a(MEMWB_ALU_result_data_r),
        .i_data_b(MEMWB_dm_read_data_r),
        .i_data_c(64'b0),
        .i_data_d(64'b0),
        .o_data(WB_WBtoReg_data)
    );


    // sequential part
    always @(posedge i_clk or negedge i_rst_n) begin
        if(~i_rst_n) begin
            o_i_valid_addr_r <= 0;
            o_i_addr_r <= 0;
            o_d_w_data_r <= 0;
            o_d_w_addr_r <= 0;
            o_d_r_addr_r <= 0;
            o_d_MemRead_r <= 0;
            o_d_MemWrite_r <= 0;
            o_finish_r <= 0;
        end
        else begin
            o_i_valid_addr_r <= o_i_valid_addr_w;
            o_i_addr_r <= o_i_addr_w;
            o_d_w_data_r <= o_d_w_data_w;
            o_d_w_addr_r <= o_d_w_addr_w;
            o_d_r_addr_r <= o_d_r_addr_w;
            o_d_MemRead_r <= o_d_MemRead_w;
            o_d_MemWrite_r <= o_d_MemWrite_w;
            o_finish_r <= o_finish_w;

            case(count_cycles)
                0: count_cycles <= 1;
                1: count_cycles <= 2;
                2: count_cycles <= 3;
                3: count_cycles <= 4;
                4: count_cycles <= 0;
            endcase
        end
    end

endmodule
