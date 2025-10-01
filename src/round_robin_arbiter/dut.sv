`timescale 1us/100ns
module dut(
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