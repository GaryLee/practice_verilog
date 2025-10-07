// This is a SystemVerilog module template for a DUT (Device Under Test)
// TODO: If you're using Cocotb to test your design, this module should be
//       a glue logic to instantiate your actual DUT module.
//       The testbench should be implemented in the test_proc.py file in Python.
`timescale 1ns/100ps

// This module is a simple adder that adds two 8-bit inputs and outputs the result.
module {dut_module} (
    input logic clk, 
    input logic rst_n,
    input logic [7:0] a, // TODO: Replace with your actual inputs
    input logic [7:0] b, // TODO: Replace with your actual inputs
    output logic [7:0] c // TODO: Replace with your actual inputs
);

// TODO: Replace following logic with your DUT implementation.
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        c <= 8'h00;
    end else begin
        c <= a + b;
    end
end 

endmodule