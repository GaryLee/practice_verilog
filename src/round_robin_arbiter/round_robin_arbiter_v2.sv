module round_robin_arbiter_v2 #(
    parameter int NUM_CLIENTS = 4
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [NUM_CLIENTS-1:0]  req,
    output logic [NUM_CLIENTS-1:0]  grant
);

    logic [NUM_CLIENTS-1:0] priority_oh;
    logic [NUM_CLIENTS-1:0] double_req;
    logic [NUM_CLIENTS-1:0] double_grant;

    // Double the request vector
    assign double_req = {req, req};

    // Priority encoder with mask
    always_comb begin
        double_grant = '0;
        for (int i = 0; i < NUM_CLIENTS*2; i++) begin
            if (double_req[i] && priority_oh[i % NUM_CLIENTS]) begin
                double_grant[i] = 1'b1;
                break;
            end
        end
    end

    // Extract grant signal
    assign grant = double_grant[NUM_CLIENTS-1:0] | double_grant[NUM_CLIENTS*2-1:NUM_CLIENTS];

    // Update priority pointer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_oh <= {{(NUM_CLIENTS-1){1'b0}}, 1'b1};
        end else if (|grant) begin
            priority_oh <= {priority_oh[NUM_CLIENTS-2:0], priority_oh[NUM_CLIENTS-1]};
        end
    end

endmodule
