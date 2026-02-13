// This is a SystemVerilog module template for a DUT (Device Under Test)
// TODO: If you're using Cocotb to test your design, this module should be
//       a glue logic to instantiate your actual DUT module.
//       The testbench should be implemented in the test_proc.py file in Python.
`timescale 1ns/100ps

// This module is a simple adder that adds two 8-bit inputs and outputs the result.
module dut #(parameter N = 8) (
    input  logic clk, 
    input  logic rst_n,
    input  logic [N-1:0] a,
    input  logic [N-1:0] b,
    output logic [2*N-1:0] c_signed,
    output logic           ov_signed,
    output logic [2*N-1:0] c_unsigned,
    output logic           ov_unsigned,
    output logic [2*N-1:0] c_signed_sat,
    output logic           ov_signed_sat,
    output logic [2*N-1:0] c_unsigned_sat,
    output logic           ov_unsigned_sat
);
    logic [N-1:0] op_a;
    logic [N-1:0] op_b;

    always_ff @(posedge clk, negedge rst_n) begin
        if (!rst_n) begin
            op_a <= 0;
            op_b <= 0;
        end else begin
            op_a <= a;
            op_b <= b;
        end
    end

    op_mult #(.N(N), .SIGNED(0), .SATURATE(0)) u_op_mult_unsigned (
        .a     (op_a),
        .b     (op_b),
        .result(c_unsigned),
        .ov    (ov_unsigned)
    );

    op_mult #(.N(N), .SIGNED(0), .SATURATE(1)) u_op_mult_unsigned_sat (
        .a     (op_a),
        .b     (op_b),
        .result(c_unsigned_sat),
        .ov    (ov_unsigned_sat)
    );

    op_mult #(.N(N), .SIGNED(1), .SATURATE(0)) u_op_mult_signed (
        .a     (op_a),
        .b     (op_b),
        .result(c_signed),
        .ov    (ov_signed)
    );

    op_mult #(.N(N), .SIGNED(1), .SATURATE(1)) u_op_mult_signed_sat (
        .a     (op_a),
        .b     (op_b),
        .result(c_signed_sat),
        .ov    (ov_signed_sat)
    );

endmodule