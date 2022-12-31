module fpu #(
    parameter DATA_WIDTH = 32,
    parameter INST_WIDTH = 1
)(
    input                   i_clk,
    input                   i_rst_n,
    input  [DATA_WIDTH-1:0] i_data_a,
    input  [DATA_WIDTH-1:0] i_data_b,
    input  [INST_WIDTH-1:0] i_inst,
    input                   i_valid,
    output [DATA_WIDTH-1:0] o_data,
    output                  o_valid
);

    // wires and registers;
    reg [DATA_WIDTH-1:0] o_data_r, o_data_w;
    reg                  o_valid_r, o_valid_w;
    
    reg data_a_sign;
    reg data_b_sign;
    
    reg [7:0] data_a_exp;
    reg [7:0] data_b_exp;
    
    reg [23:0] data_a_significand;
    reg [23:0] data_b_significand;
    
    integer shift_num;
    reg [1:0] rs;
    
    reg [23:0] tmp_result;
    reg overflow;

    reg [47:0] mul_result;
    integer i;
    integer breakout;
    integer first_one_idx;

    // continuous assignment
    assign o_data = o_data_r;
    assign o_valid = o_valid_r;
    
    // combinational part
    always @(*) begin
        if (i_valid) begin
            case (i_inst)
                // floating point addition
                1'd0: begin
                    data_a_sign = i_data_a[31];
                    data_b_sign = i_data_b[31];
                    
                    data_a_exp = i_data_a[30:23];
                    data_b_exp = i_data_b[30:23];
    
                    data_a_significand[23] = 1;
                    data_a_significand[22:0] = i_data_a[22:0];
                    data_b_significand[23] = 1;
                    data_b_significand[22:0] = i_data_b[22:0];

                    // decide which exponent is smaller and shift its significand
                    if(data_a_exp > data_b_exp) begin
                        shift_num = data_a_exp - data_b_exp;
                        
                        // set rounding and sticky bit
                        if(shift_num >= 2) begin
                            rs[1] = data_b_significand[shift_num-1];
                            rs[0] = data_b_significand[shift_num-2];
                        end else if(shift_num == 1) begin
                            rs[1] = data_b_significand[0];
                            rs[0] = 0;
                        end
                        
                        data_b_significand = data_b_significand >> shift_num;
                        
                        // rounding
                        if(rs[1] == 1 && rs[0] == 1) begin
                            data_b_significand = data_b_significand + 1;
                        end else if(rs[1] == 1 && rs[0] == 0) begin
                            if(data_b_significand[0] == 1) begin
                                data_b_significand = data_b_significand + 1;
                            end
                        end

                        o_data_w[30:23] = data_a_exp;
                    end else begin // b_exp > a_exp
                        shift_num = data_b_exp - data_a_exp;
                        
                        // set rounding and sticky bit
                        if(shift_num >= 2) begin
                            rs[1] = data_a_significand[shift_num-1];
                            rs[0] = data_a_significand[shift_num-2];
                        end else if(shift_num == 1) begin
                            rs[1] = data_a_significand[0];
                            rs[0] = 0;
                        end

                        data_a_significand = data_a_significand >> shift_num;
                        
                        // rounding
                        if(rs[1] == 1 && rs[0] == 1) begin
                            data_a_significand = data_a_significand + 1;
                        end else if(rs[1] == 1 && rs[0] == 0) begin
                            if(data_a_significand[0] == 1) begin
                                data_a_significand = data_a_significand + 1;
                            end
                        end

                        o_data_w[30:23] = data_b_exp;
                    end
                    
                    // signifiacnd calculation 
                    if(data_a_sign == 0 && data_b_sign == 0) begin
                        {overflow, tmp_result[23:0]} = data_a_significand + data_b_significand;
                        if(overflow == 0) begin
                            o_data_w[22:0] = tmp_result[22:0];
                        end else if(overflow == 1) begin
                            o_data_w[22:0] = tmp_result[23:1];
                            o_data_w[30:23] = o_data_w[30:23] + 1;
                        end
                        o_data_w[31] = 0;
                    end else if(data_a_sign == 0 && data_b_sign == 1) begin
                        if(data_a_significand > data_b_significand) begin
                            tmp_result[23:0] = data_a_significand - data_b_significand;
                            o_data_w[31] = 0;
                        end else begin
                            tmp_result[23:0] = data_b_significand - data_a_significand;
                            o_data_w[31] = 1;
                        end
                        o_data_w[22:0] = tmp_result[22:0];
                    end else if(data_a_sign == 1 && data_b_sign == 0) begin
                        if(data_a_significand > data_b_significand) begin
                            tmp_result[23:0] = data_a_significand - data_b_significand;
                            o_data_w[31] = 1;
                        end else begin
                            tmp_result[23:0] = data_b_significand - data_a_significand;
                            o_data_w[31] = 0;
                        end
                        o_data_w[22:0] = tmp_result[22:0];
                    end else if(data_a_sign == 1 && data_b_sign == 1) begin
                        {overflow, tmp_result[23:0]} = data_a_significand + data_b_significand;
                        if(overflow == 0) begin
                            o_data_w[22:0] = tmp_result[22:0];
                        end else if(overflow == 1) begin
                            o_data_w[22:0] = tmp_result[23:1];
                            o_data_w[30:23] = o_data_w[30:23] + 1;
                        end
                        o_data_w[31] = 1;
                    end

                    o_valid_w = 1;
                end
                // floating point multiplication
                1'd1: begin
                    data_a_sign = i_data_a[31];
                    data_b_sign = i_data_b[31];
                    
                    data_a_exp = i_data_a[30:23];
                    data_b_exp = i_data_b[30:23];
    
                    data_a_significand[23] = 1;
                    data_a_significand[22:0] = i_data_a[22:0];
                    data_b_significand[23] = 1;
                    data_b_significand[22:0] = i_data_b[22:0];
                    
                    // add the exponents (bias notation)
                    o_data_w[30:23] = data_a_exp + data_b_exp - 127;
                    
                    // multiply the significand
                    mul_result = data_a_significand * data_b_significand;
                    
                    breakout = 0;
                    for(i = 47; i >= 0; i = i - 1) begin
                        if(breakout == 0) begin
                            if(mul_result[i] == 1) begin
                                first_one_idx = i;
                                breakout = 1;
                            end
                        end
                    end
                   
                    if(first_one_idx == 47)
                        o_data_w[30:23] = o_data_w[30:23] + 1;
                    
                    mul_result = mul_result << (47 - first_one_idx);
                    o_data_w[22:0] = mul_result[46:24];
                    
                    // rounding using rounding and sticky bit
                    if(mul_result[23] == 1 && mul_result[22] == 1)
                        o_data_w[22:0] = o_data_w[22:0] + 1;
                    else if(mul_result[23] == 1 && mul_result[22] == 0 && o_data_w[0] == 1)
                        o_data_w[22:0] = o_data_w[22:0] + 1;
                    


                    // set the sign
                    o_data_w[31] = (data_a_sign == data_b_sign)? 0 : 1;
                    
                    o_valid_w = 1;
                end
                default: begin
                    o_data_w = 0;
                    o_valid_w = 1;
                end
            endcase
        end else begin
            o_data_w = 0;
            o_valid_w = 0;
        end
    end

    // sequential part
    always @(posedge i_clk or negedge i_rst_n) begin
        // if i_rst_n = 0, then reset
        if (~i_rst_n) begin
            o_data_r <= 0;
            o_data_r <= 0;
        end else begin
            o_data_r <= o_data_w;
            o_valid_r <= o_valid_w;
        end
    end
    

endmodule
