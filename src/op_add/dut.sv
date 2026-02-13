// This is a SystemVerilog module template for a DUT (Device Under Test)
// TODO: If you're using Cocotb to test your design, this module should be
//       a glue logic to instantiate your actual DUT module.
//       The testbench should be implemented in the test_proc.py file in Python.
`timescale 1ns/100ps

// This module is a simple adder that adds two 8-bit inputs and outputs the result.
module dut #(parameter N = 8) (
    input logic clk, 
    input logic rst_n,
    input logic [N-1:0] a,
    input logic [N-1:0] b,
    output logic [N-1:0] c
);
    logic ov;
    logic uv;
    logic [N-1:0] op_a;
    logic [N-1:0] op_b;

    op_add #(.N(N), .SIGNED(0)) u0_op_add (
        .a(op_a),
        .b(op_b),
        .result(c),
        .ov(ov),
        .uv(uv) 
    );

    // TODO: Replace following logic with your DUT implementation.
    always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        op_a <= '0;
        op_b <= '0;
    end else begin
        op_a <= a;
        op_b <= b;
    end
end 

endmodule