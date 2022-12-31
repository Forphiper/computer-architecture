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
    output [ DATA_W-1 : 0 ] o_d_data,       // to data memory
    output [ ADDR_W-1 : 0 ] o_d_addr,       // to data memory
    output                  o_d_MemRead,    // to data memory
    output                  o_d_MemWrite,   // to data memory
    output                  o_finish
);
    
    // wires and registers
    reg [64-1:0]     pc_r, pc_w;
    reg [4-1:0]      im_cs, im_ns;
    reg [4-1:0]      dm_cs, dm_ns;
    reg              o_i_valid_r, o_i_valid_w;
    reg [ADDR_W-1:0] o_i_addr_r, o_i_addr_w;
    reg [INST_W-1:0] instr;
    
    reg [DATA_W-1:0] reg_file_r [0:31];
    reg [DATA_W-1:0] reg_file_w [0:31];
    reg [5-1:0]      write_register;
    reg [5-1:0]      read_register1;
    reg [5-1:0]      read_register2;
    reg [5-1:0]      shamt;
    reg [12-1:0]     immediate;
    reg [DATA_W-1:0] sign_extend;
    
    reg [DATA_W-1:0] o_d_data_r, o_d_data_w;
    reg [ADDR_W-1:0] o_d_addr_r,o_d_addr_w;
    reg              o_d_MemRead_r, o_d_MemRead_w;
    reg              o_d_MemWrite_r, o_d_MemWrite_w;
    reg              o_finish_r, o_finish_w;

    reg              data_transfer;
    reg              Branch_r, Branch_w;
    reg [ADDR_W-1:0] branch_target;
    
    integer          i;

    // continuous assignments
    assign o_i_valid_addr = o_i_valid_r;
    assign o_i_addr = o_i_addr_r;
    assign o_d_addr = o_d_addr_r;
    assign o_d_data = o_d_data_r;
    assign o_d_MemWrite = o_d_MemWrite_r;
    assign o_d_MemRead = o_d_MemRead_r;
    assign o_finish = o_finish_r;

    // instruction memory latency
    always @(*) begin
        case(im_cs)
            0: im_ns = 1;
            1: im_ns = 2;
            2: im_ns = 3;
            3: im_ns = 4;
            4: im_ns = 5;
            5: im_ns = 6;
            6: im_ns = 7;
            7: im_ns = 8;
            8: im_ns = 9;
            9: im_ns = 10;
            10: im_ns = 11;
            11: im_ns = 12;
            12: im_ns = 13;
            13: im_ns = 14;
            14: im_ns = 15;
            15: im_ns = 0;
        endcase
        
        if(i_i_valid_inst) begin
            instr = i_i_inst;    
        end
    end

    // combinational part
    always @(*) begin
        for(i = 0; i < 32; i = i + 1)
            reg_file_w[i] = reg_file_r[i];
        
        if(im_cs == 6) begin
        	o_i_valid_w = 0; 
            o_i_addr_w = pc_r;        
            Branch_w = 0;
            
            case(instr[6:0])
                7'b0000011: begin
                    // LD 
                    case(instr[14:12])
                        3'b011: begin
                            immediate[11:0] = instr[31:20];
                            read_register1 = instr[19:15];
                            write_register = instr[11:7]; 
                            sign_extend = {{52{immediate[11]}}, immediate[11:0]}; 
                            o_d_addr_w = sign_extend + reg_file_r[read_register1];
                            o_d_MemRead_w = 1;
                            data_transfer = 1;
                        end
                    endcase
                end

                // SD
                7'b0100011: begin 
                    case(instr[14:12]) 
                        3'b011: begin
                            immediate[11:5] = instr[31:25];
                            read_register2 = instr[24:20];
                            read_register1 = instr[19:15];
                            immediate[4:0] = instr[11:7];
                            sign_extend = {{52{immediate[11]}}, immediate[11:0]}; 
                            o_d_addr_w = sign_extend + reg_file_r[read_register1];
                            o_d_data_w = reg_file_r[read_register2];
                            o_d_MemWrite_w = 1;
                            data_transfer = 1;
                        end
                    endcase
                end
                
                // Branch
                7'b1100011: begin
                    read_register1 = instr[19:15];
                    read_register2 = instr[24:20];
                    immediate = {instr[31], instr[7], instr[30:25], instr[11:8]}; 
                    sign_extend = {{52{immediate[11]}}, immediate[11:0]}; 

                    // BEQ
                    case(instr[14:12])
                        3'b000: begin
                            if(reg_file_r[read_register1] == reg_file_r[read_register2]) begin
                                Branch_w = 1;
                                branch_target = pc_r + (sign_extend << 1);
                            end
                        end

                        // BNE
                        3'b001: begin
                            if(reg_file_r[read_register1] != reg_file_r[read_register2]) begin
                                Branch_w = 1;
                                branch_target = pc_r + (sign_extend << 1);
                            end 
                        end
                    endcase
                end


                // I-type
                7'b0010011: begin 
                    immediate[11:0] = instr[31:20];
                    read_register1 = instr[19:15];
                    write_register = instr[11:7];
                    shamt = instr[24:20];
                    sign_extend = {{52{immediate[11]}}, immediate[11:0]}; 

                    case(instr[14:12])
                        // ADDI
                        3'b000: begin
                            reg_file_w[write_register] = sign_extend + reg_file_r[read_register1]; 
                        end
                        
                        // XORI
                        3'b100: begin
                            reg_file_w[write_register] = sign_extend ^ reg_file_r[read_register1];
                        end
                        
                        // ORI
                        3'b110: begin
                            reg_file_w[write_register] = sign_extend | reg_file_r[read_register1];
                        end

                        // ANDI
                        3'b111: begin
                            reg_file_w[write_register] = sign_extend & reg_file_r[read_register1];
                        end

                        // SLLI
                        3'b001: begin
                            reg_file_w[write_register] = reg_file_r[read_register1] << shamt;
                        end

                        // SRLI
                        3'b101: begin
                            reg_file_w[write_register] = reg_file_r[read_register1] >> shamt;
                        end
                    endcase    
                end        


                // R-type
                7'b0110011: begin
                    read_register2 = instr[24:20];
                    read_register1 = instr[19:15];
                    write_register = instr[11:7];

                    case(instr[14:12])
                        3'b000: begin
                            case(instr[31:25])
                                // ADD
                                7'b0000000: begin
                                    reg_file_w[write_register] = reg_file_r[read_register1] +
                                                                 reg_file_r[read_register2];
                                end

                                // SUB
                                7'b0100000: begin
                                    reg_file_w[write_register] = reg_file_r[read_register1] -
                                                                 reg_file_r[read_register2];
                                end
                            endcase 
                        end

                        // XOR
                        3'b100: begin
                            reg_file_w[write_register] = reg_file_r[read_register1] ^
                                                         reg_file_r[read_register2];
                        end
                        
                        // OR
                        3'b110: begin
                            reg_file_w[write_register] = reg_file_r[read_register1] |
                                                         reg_file_r[read_register2];
                        end
                        
                        // AND
                        3'b111: begin
                            reg_file_w[write_register] = reg_file_r[read_register1] &
                                                         reg_file_r[read_register2];
                        end
                    endcase
                end

                // Finish
                7'b1111111: begin
                    o_finish_w = 1;
                end
            endcase
        end

        else if(im_cs == 15) begin
            if(Branch_r) begin
                pc_w = branch_target - 4;
                o_i_addr_w = branch_target - 4;
            end else begin
                pc_w = pc_r + 4;
                o_i_addr_w = pc_r;
            end
            o_i_valid_w = 1;
        end

        else begin
        	o_i_valid_w = 0; 
            o_i_addr_w = pc_r;  
            o_d_data_w = 0;
            o_d_MemRead_w = 0;
            o_d_MemWrite_w = 0;
            o_finish_w = 0;
        end
            
    end


    // data memory
    always @(*) begin
        case(dm_cs)
            0: begin
                if(data_transfer)
                    dm_ns = 1;
                else 
                    dm_ns = 0;
            end
            1: begin
                if(o_d_MemRead_r)
                    o_d_MemRead_w = 0;
                if(o_d_MemWrite_r)
                    o_d_MemWrite_w = 0;
                dm_ns = 2;
            end
            2: dm_ns = 3;
            3: dm_ns = 4;
            4: dm_ns = 5;
            5: dm_ns = 6;
            6: dm_ns = 7;
            7: dm_ns = 8;
            8: dm_ns = 9;
            9: dm_ns = 10;
            10: begin
                dm_ns = 0;
                data_transfer = 0;
            end
        endcase

        if(i_d_valid_data) begin
            write_register = instr[11:7];
            reg_file_r[write_register] = i_d_data;
        end
    end

    // sequential part
    always @(posedge i_clk or negedge i_rst_n) begin
        if(~i_rst_n) begin
            for(i = 0; i < 32; i = i + 1)
                reg_file_r[i] <= 0;
            pc_r <= 0;   
            pc_w <= 0;   
            im_cs <= 0;
            dm_cs <= 0;
            o_i_valid_r <= 0;
            o_i_addr_r <= 0;
            instr <= 0;
            o_d_addr_r <= 0;
            o_d_data_r <= 0;
            o_d_MemRead_r <= 0;
            o_d_MemWrite_r <= 0;
            o_finish_r <= 0;
            data_transfer <= 0;
            Branch_r <= 0;
        end else begin
            for(i = 0; i < 32; i = i + 1)
                reg_file_r[i] <= reg_file_w[i];
            pc_r <= pc_w;
            im_cs <= im_ns;
            dm_cs <= dm_ns;
            o_i_valid_r <= o_i_valid_w;
            o_i_addr_r <= o_i_addr_w;
            o_d_addr_r <= o_d_addr_w;
            o_d_data_r <= o_d_data_w;
            o_d_MemRead_r <= o_d_MemRead_w;
            o_d_MemWrite_r <= o_d_MemWrite_w;
            o_finish_r <= o_finish_w;
            Branch_r <= Branch_w;
        end
    end


endmodule
