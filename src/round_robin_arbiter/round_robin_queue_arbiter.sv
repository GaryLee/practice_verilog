module round_robin_queue_arbiter #(parameter int N = 4, parameter int DEPTH = 4) (
    input logic rst_n,
    input logic clk,
    input logic [N-1:0] req,
    output logic [N-1:0] grant
);
    logic [N-1:0] queued_req;
    logic [N-1:0] masked_req;
    logic [N-1:0] noncheck_grant;
    logic pop_req_queue;
    logic is_queue_full;
    logic is_queue_empty;

    // The glue logic between request queue and round robin arbiter.
    // 1. If the granted request is devoked (not asserted), pop the next request queue.
    // 2. If the masked_req is not empty, don't pop the request queue.
    //    Because the grant logic needs some time to response.
    // 3. To saving power, we do not pop the request queue if the queue is empty.
    assign pop_req_queue = (~|grant & ~|masked_req) & ~is_queue_empty;

    // The request queue can keep the changing order of requests.
    // The first come request will be granted first.
    request_queue #(.N(N), .DEPTH(DEPTH)) request_queue_u0 (
                        .req(req),
                        .req_o(queued_req),
                        .pop(pop_req_queue),
                        .is_full(is_queue_full),
                        .is_empty(is_queue_empty),
                        .clk(clk),
                        .rst_n(rst_n)
                        );

    // Masked request generation logic. Request should hold its status until it is granted.
    // If the request devoke earlier than being granted, the request in queue will be marked out.
    // If queue is empty, to increase the responsiblity, we directly pass the req to arbiter.
    assign masked_req = is_queue_empty ? req : (req & queued_req);

    round_robin_arbiter #(.N(N)) round_robin_arbiter_u0 (
                        .req(masked_req),
                        .grant(noncheck_grant),
                        .clk(clk),
                        .rst_n(rst_n)
                        );

    // Make sure the grant only happend when there is a valid request. Use combinational logic to reduce latency.
    assign grant = noncheck_grant & req;

endmodule
