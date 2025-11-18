`timescale 1us/100ns
module dut(
    input logic clk, 
    input logic rst_n,
    input logic [3:0] req,
    output logic [3:0] grant
);

    req_grant_fifo #(
        .NUM_CLIENTS(4)
    ) u_req_grant_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .req(req),
        .grant(grant)
    );

endmodule