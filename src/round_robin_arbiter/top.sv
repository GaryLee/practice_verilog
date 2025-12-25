module top #(parameter int N = 4, parameter int DEPTH = 4) (
    input logic rst_n,
    input logic clk,
    input logic [N-1:0] req,
    output logic [N-1:0] grant,
    // For debugging purpose.
    input reg [7:0] dbg_idx,
    input reg dbg0,
    input reg dbg1,
    input reg dbg2,
    input reg dbg3
);
    round_robin_queue_arbiter #(.N(N), .DEPTH(DEPTH)) dut (
        .rst_n(rst_n),
        .clk(clk),
        .req(req),
        .grant(grant)
    );

endmodule
