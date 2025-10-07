`timescale 1us/100ns

`define N 16
`define OP_ADD 0
`define OP_MULTIPLY 1

module dut(
    input logic clk, 
    input logic rst_n,
    input logic op_sel, // Operation selector: 0 for addition, 1 for multiplication
    input logic [`N-1:0] a,
    input logic [`N-1:0] b,
    output logic [`N-1:0] result,
    output logic ov, // Overflow flag
    output logic uv  // Underflow flag

);
    parameter int N=`N;
    logic [N-1:0] adder_a, adder_b, adder_result;
    logic adder_ov, adder_uv;
    logic [N-1:0] multiplier_a, multiplier_b, multiplier_result;
    logic multiplier_ov, multiplier_uv;

    signed_adder #(.N(N)) adder (
        .a(adder_a),
        .b(adder_b),
        .sum(adder_result),
        .ov(adder_ov),
        .uv(adder_uv)
    );

    signed_multiplier #(.N(N)) multiplier (
        .a(multiplier_a),
        .b(multiplier_b),
        .product(multiplier_result),
        .ov(multiplier_ov),
        .uv(multiplier_uv)
    );

    assign adder_a = op_sel == `OP_ADD ? a : 0;
    assign adder_b = op_sel == `OP_ADD ? b : 0;
    assign multiplier_a = op_sel == `OP_MULTIPLY ? a : 0;
    assign multiplier_b = op_sel == `OP_MULTIPLY ? b : 0;

    // The result and flags are updated synchronously with the clock.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 0;
            ov <= 0;
            uv <= 0;
        end else begin
            if (op_sel == `OP_ADD) begin
                result <= adder_result;
                ov <= adder_ov;
                uv <= adder_uv;
            end else begin
                result <= multiplier_result;
                ov <= multiplier_ov;
                uv <= multiplier_uv;
            end
        end
    end

endmodule