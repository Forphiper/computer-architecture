module alu #(
    parameter DATA_WIDTH = 32,
    parameter INST_WIDTH = 5
)(
    input                   i_clk,
    input                   i_rst_n,
    input  [DATA_WIDTH-1:0] i_data_a,
    input  [DATA_WIDTH-1:0] i_data_b,
    input  [INST_WIDTH-1:0] i_inst,
    input                   i_valid,
    output [DATA_WIDTH-1:0] o_data,
    output                  o_overflow,
    output                  o_valid
);

    // homework
    // wires and registers;
    reg [DATA_WIDTH-1:0] o_data_r, o_data_w;
    reg                  o_overflow_r, o_overflow_w;
    reg                  o_valid_r, o_valid_w;
    
    reg signed [DATA_WIDTH-1:0] signed_data_a, signed_data_b;
    
    integer i;

    // continuous assignment
    assign o_data = o_data_r;
    assign o_overflow = o_overflow_r;
    assign o_valid = o_valid_r;
    
    // combinational part
    always @(*) begin
        if (i_valid) begin
            case (i_inst)
                // signed add
                5'd0: begin
                    signed_data_a = i_data_a;
                    signed_data_b = i_data_b;
                    o_data_w = signed_data_a + signed_data_b;
                    o_overflow_w = 0;
                    if(signed_data_a[DATA_WIDTH-1] == 0 && signed_data_b[DATA_WIDTH-1] == 0 && o_data_w[DATA_WIDTH-1] == 1)
                        o_overflow_w = 1;
                    if(signed_data_a[DATA_WIDTH-1] == 1 && signed_data_b[DATA_WIDTH-1] == 1 && o_data_w[DATA_WIDTH-1] == 0)
                        o_overflow_w = 1;
                    o_valid_w = 1;
                end
                // signed sub
                5'd1: begin
                    signed_data_a = i_data_a;
                    signed_data_b = i_data_b;
                    o_data_w = signed_data_a - signed_data_b;
                    o_overflow_w = 0;
                    if(signed_data_a[DATA_WIDTH-1] == 0 && signed_data_b[DATA_WIDTH-1] == 1 && o_data_w[DATA_WIDTH-1] == 1)
                        o_overflow_w = 1;
                    if(signed_data_a[DATA_WIDTH-1] == 1 && signed_data_b[DATA_WIDTH-1] == 0 && o_data_w[DATA_WIDTH-1] == 0)
                        o_overflow_w = 1;
                    o_valid_w = 1;
                end
                // signed mul
                5'd2: begin
                    signed_data_a = i_data_a;
                    signed_data_b = i_data_b;
                    o_data_w = signed_data_a * signed_data_b;
                    o_overflow_w = 0;
                    if(signed_data_a[DATA_WIDTH-1] == 0 && signed_data_b[DATA_WIDTH-1] == 0 && o_data_w[DATA_WIDTH-1] == 1)
                        o_overflow_w = 1;
                    if(signed_data_a[DATA_WIDTH-1] == 1 && signed_data_b[DATA_WIDTH-1] == 1 && o_data_w[DATA_WIDTH-1] == 0)
                        o_overflow_w = 1;
                    o_valid_w = 1;
                end
                // signed max
                5'd3: begin
                    signed_data_a = i_data_a;
                    signed_data_b = i_data_b;
                    o_data_w = (signed_data_a > signed_data_b)? signed_data_a : signed_data_b;
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end
                // signed min
                5'd4: begin
                    signed_data_a = i_data_a;
                    signed_data_b = i_data_b;
                    o_data_w = (signed_data_a < signed_data_b)? signed_data_a : signed_data_b;
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end
                // unsigned add
                5'd5: begin
                    {o_overflow_w, o_data_w} = i_data_a + i_data_b;
                    o_valid_w = 1;
                end
                // unsigned sub
                5'd6: begin
                    {o_overflow_w, o_data_w} = i_data_a - i_data_b;
                    o_valid_w = 1;
                end
                // signed mul
                5'd7: begin
                    {o_overflow_w, o_data_w} = i_data_a * i_data_b;
                    o_valid_w = 1;
                end
                // unsigned max
                5'd8: begin
                    o_data_w = (i_data_a > i_data_b)? i_data_a : i_data_b;
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end
                // unsigned min
                5'd9: begin
                    o_data_w = (i_data_a < i_data_b)? i_data_a : i_data_b;
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end
                // and
                5'd10: begin
                    o_data_w = i_data_a & i_data_b;
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end
                // or
                5'd11: begin
                    o_data_w = i_data_a | i_data_b;
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end
                // xor
                5'd12: begin
                    o_data_w = i_data_a ^ i_data_b;
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end
                // bitflip
                5'd13: begin
                    o_data_w = ~i_data_a;
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end
                // bitreverse
                5'd14: begin
                    for(i = 0; i < DATA_WIDTH; i = i + 1)
                        o_data_w[i] = i_data_a[DATA_WIDTH-1-i];
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end
                // signed LT (<)
                5'd15: begin
                    signed_data_a = i_data_a;
                    signed_data_b = i_data_b;
                    o_data_w = (signed_data_a < signed_data_b);
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end
                // signed GE (>=)
                5'd16: begin
                    signed_data_a = i_data_a;
                    signed_data_b = i_data_b;
                    o_data_w = (signed_data_a >= signed_data_b);
                    o_overflow_w = 0;
                    o_valid_w = 1;
                end
                default: begin
                    o_overflow_w = 0;
                    o_data_w = 0;
                    o_valid_w = 1;
                end
            endcase
        end else begin
            o_overflow_w = 0;
            o_data_w = 0;
            o_valid_w = 0;
        end
    end

    // sequential part
    always @(posedge i_clk or negedge i_rst_n) begin
        // if i_rst_n = 0, then reset
        if (~i_rst_n) begin
            o_data_r <= 0;
            o_overflow_r <= 0;
            o_data_r <= 0;
        end else begin
            o_data_r <= o_data_w;
            o_overflow_r <= o_overflow_w;
            o_valid_r <= o_valid_w;
        end
    end
    

endmodule
