module round_robin_arbiter_v2 #(
    parameter int NUM_CLIENTS = 4
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [NUM_CLIENTS-1:0]  req,
    output logic [NUM_CLIENTS-1:0]  grant
);

    logic [NUM_CLIENTS-1:0] priority_pointer;
    logic [NUM_CLIENTS-1:0] double_req;
    logic [NUM_CLIENTS*2-1:0] double_grant;

    // Double the request vector
    assign double_req = {req, req};

    // Priority encoder with mask
    always_comb begin
        double_grant = '0;
        for (int i = 0; i < NUM_CLIENTS*2; i++) begin
            if (double_req[i] && priority_pointer[i % NUM_CLIENTS]) begin
                double_grant[i] = 1'b1;
                break;
            end
        end
    end

    // Extract grant signal
    assign grant = double_grant[NUM_CLIENTS-1:0] | double_grant[NUM_CLIENTS*2-1:NUM_CLIENTS];
    // If the priority is granted and req is active, we need to hold the priority pointer.
    assign grant_occupied = |(priority_pointer & req);
    // Check if there is any request
    assign has_freq = |req;

    // Update priority pointer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_pointer <= {{(NUM_CLIENTS-1){1'b0}}, 1'b1};
        end else if (has_freq & ~grant_occupied) begin
            priority_pointer <= {priority_pointer[NUM_CLIENTS-2:0], priority_pointer[NUM_CLIENTS-1]};
        end
    end

endmodule
