// This is a SystemVerilog module template for a DUT (Device Under Test)
`timescale 1ns/100ps

// This module is a simple adder that adds two 8-bit inputs and outputs the result.
module {dut_module} (
    input logic clk, 
    input logic rst_n,
    input logic [7:0] a,
    input logic [7:0] b,
    output logic [7:0] c
);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        c <= 8'h00;
    end else begin
        c <= a + b;
    end
end 

endmodule