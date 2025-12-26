/**
 * N-Input request queue.
 */
module request_queue #(
    parameter int N = 4,
    parameter int DEPTH = 3,
    parameter int QUICK_POP = 1   ///< If set to 1, the queue will try to fill the popped entry immediately.
) (
    input logic rst_n,           ///< Asynchronous active low reset
    input logic clk,             ///< Clock input.
    input logic [N-1:0] req,     ///< Request inputs.
    input logic pop,             ///< Pop signal to dequeue the head entry.
    output logic [N-1:0] req_o,  ///< Grant outputs.
    output logic is_full,        ///< High when the queue is full.
    output logic is_empty        ///< High when the queue is empty.
);
    logic [DEPTH-1:0][N-1:0] queue;
    logic [DEPTH-1:0] queue_occupied;

    // The item is occupied when it is non-zero.
    for (genvar i = 0; i < DEPTH; i = i + 1) begin : gen_queue_occupied
        assign queue_occupied[i] = |queue[i];
    end

    // Queue availability logic.
    // The first free queue entry is available when all previous queues are occupied.
    // E.g., if queue[0], queue[1] are occupied, queue[2] is available.
    //       The queue_avail is 'b0100 (if DEPTH=4).
    logic [DEPTH-1:0] queue_avail;
    for (genvar i = 0; i < DEPTH; i = i + 1) begin : gen_queue_avail
        if (i == 0) begin : gen_queue_head
            assign queue_avail[i] = ~queue_occupied[i];
        end else begin : gen_queue_others
            assign queue_avail[i] = ~queue_occupied[i] & (&queue_occupied[i-1:0]);
        end
    end

    logic has_req_input;
    assign has_req_input = (|req);

    for (genvar i = 0; i < DEPTH; i = i + 1) begin : gen_queue
        always_ff @(posedge clk or negedge rst_n) begin
            if (~rst_n | ~has_req_input) begin
                // Clear all queues on reset or no request input.
                // The reason to clear on ~has_req_input is to avoid stale requests in the queue.
                queue[i] <= '0;
            end else if (pop) begin
                if (QUICK_POP == 1) begin
                    if (i == DEPTH-1) begin
                        queue[i] <= (queue_occupied[i] & (req != queue[i])) ? req : '0;
                    end else begin
                        queue[i] <= ~queue_avail[i+1] ? queue[i+1] :
                                    (req != queue[i]) ? req : '0;
                    end
                end else begin
                    if (i == DEPTH-1) begin
                        queue[i] <= '0;
                    end else begin
                        queue[i] <= queue[i+1];
                    end
                end
            end else if (has_req_input & queue_avail[i]) begin
                if (i == 0) begin
                    queue[i] <= req;
                end else if (req != queue[i-1]) begin // Avoid duplicate entry.
                    queue[i] <= req;
                end
            end
        end
    end

    // Output logic.
    assign is_full = &queue_occupied; // Mark full if all queue entries are occupied.
    assign is_empty = ~|queue_occupied; // Mark empty if all queue entries are free.
    assign req_o = queue[0];
endmodule
