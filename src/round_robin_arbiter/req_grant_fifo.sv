module req_grant_fifo #(
    parameter int NUM_CLIENTS = 4
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [NUM_CLIENTS-1:0]  req,
    output logic [NUM_CLIENTS-1:0]  grant
);

    logic [NUM_CLIENTS-1:0] grant_pointer;
    logic [NUM_CLIENTS*2-1:0] double_req;
    logic [NUM_CLIENTS*2-1:0] double_req_onehot;
    logic [NUM_CLIENTS-1:0] req_onehot;
    logic [NUM_CLIENTS-1:0] req_onehot_hist;
    logic [NUM_CLIENTS-1:0] req_onehot_fifo[NUM_CLIENTS];
    logic [NUM_CLIENTS-1:0] fifo_occupied;
    logic has_freq;
    logic grant_occupied;

    // Double the request vector
    assign double_req = {req, req};

    // Priority encoder with mask
    always_comb begin
        double_req_onehot = '0;
        for (int i = 0; i < NUM_CLIENTS*2; i++) begin
            if (double_req[i] && grant_pointer[i % NUM_CLIENTS] && double_req_onehot == '0) begin
                double_req_onehot[i] = 1'b1;
            end
        end
    end

    // Extract onehot req signal
    assign req_onehot = double_req_onehot[NUM_CLIENTS-1:0] | double_req_onehot[NUM_CLIENTS*2-1:NUM_CLIENTS];

    // If the client is granted and req is active, we need to hold the grant pointer.
    assign grant_occupied = |(grant_pointer & req);
    // Check if there is any request
    assign has_freq = |req;
    // Can we grant next cycle?
    assign can_grant_next = has_freq & ~grant_occupied;
    // Check if the granted request is removed
    assign is_granted_req_removed = |(grant & ~req);
    assign has_no_granted = ~|grant;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_onehot_hist <= '0;
        end else begin
            req_onehot_hist <= req_onehot;
        end
    end

    assign req_onehot_updated = (req_onehot == req_onehot_hist);

    // Update grant pointer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_pointer <= {{(NUM_CLIENTS-1){1'b0}}, 1'b1};
        end else if (can_grant_next) begin
            grant_pointer <= {grant_pointer[NUM_CLIENTS-2:0], grant_pointer[NUM_CLIENTS-1]};
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        for (int i = 0; i < NUM_CLIENTS; i++) begin
            if (!rst_n) begin
                fifo_occupied[i] <= '0;
            end else begin
                fifo_occupied[i] <= |req_onehot_fifo[i];
            end
        end
    end

    always_comb begin
        for (int i = 0; i < NUM_CLIENTS-1; i++) begin
            if (~fifo_occupied[i]) begin
                req_onehot_fifo[i] = req_onehot_fifo[i+1];
                req_onehot_fifo[i+1] =
                    ((i + 1 == NUM_CLIENTS - 1) && req_onehot_updated) ? req_onehot : '0;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant <= '0;
        end else begin
            grant <= req_onehot_fifo[0];
        end
    end

endmodule
