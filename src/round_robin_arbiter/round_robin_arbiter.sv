/**
 * N-Input Round Robin Arbiter.
 *
 */
module round_robin_arbiter #(
    parameter int N = 4
) (
    input logic rst_n,         ///< Asynchronous active low reset
    input logic clk,            ///< Clock input.
    input logic [N-1:0] req,    ///< Request inputs.
    output logic [N-1:0] grant ///< Grant outputs.
);
    genvar i;

    logic [N-1:0] rotate_ptr;
    logic [N-1:0] mask_req;
    logic [N-1:0] mask_grant;
    logic [N-1:0] grant_comb;

    logic no_mask_req;
    logic [N-1:0] no_mask_grant;
    logic update_ptr;


    // Rotate pointer update logic.
    // Rotate pointer is the bitmask that bit order higher than the last granted request are set to 1.
    // E.g., if N=4 and last granted request is req[1], rotate_ptr = 1100.
    //       If the last granted requst is req[N-1], rotate_ptr is N'b111..11.
    // rotate_ptr[0] <= grant[N-1];
    // rotate_ptr[1] <= grant[N-1] | grant[0];
    // rotate_ptr[2] <= grant[N-1] | grant[1] | grant[0];
    // ...

    assign update_ptr = |grant; // Update rotate pointer when any grant is issued.
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            rotate_ptr[0] <= 'b1;
        end else if (update_ptr) begin
            rotate_ptr[0] <= grant[N-1];
        end
    end

    generate
        for (i = 1; i < N; i = i + 1) begin : gen_mask_req
            always_ff @(posedge clk or negedge rst_n) begin
                if (~rst_n) begin
                    rotate_ptr[i] <= 1'b1;
                end else if (update_ptr) begin
                    rotate_ptr[i] <= grant[N-1] | (|grant[i-1:0]);
                end
            end
        end
    endgenerate

    // Mask grant generation logic.
    assign mask_req = req & rotate_ptr;
    assign mask_grant[0] = mask_req[0];

    generate
        for (i = 1; i < N; i = i + 1) begin : gen_mask_grant
            assign mask_grant[i] = mask_req[i] & (~|mask_req[i-1:0]);
        end
    endgenerate

    // Non-mask grant generation logic.
    // The lowest bit indexed request has the highest priority.
    // Grant to the lowest numbered request when no masked requests are present.
    assign no_mask_grant[0] = req[0];
    generate
        for (i = 1; i < N; i = i + 1) begin : gen_no_mask_grant
            assign no_mask_grant[i] = (~|req[i-1:0]) & req[i];
        end
    endgenerate

    // Grant generation logic.
    assign no_mask_req = ~|mask_req; // Is there no any masked request present?
    assign grant_comb = mask_grant | (no_mask_grant & {N{no_mask_req}});

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            grant <= {N{1'b0}};
        end else if (|(grant & req)) begin // If request is still asserted, hold the grant.
            grant <= grant;
        end else begin
            grant <= grant_comb & ~grant;
        end
    end
endmodule
