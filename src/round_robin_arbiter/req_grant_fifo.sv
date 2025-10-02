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
    logic [NUM_CLIENTS-1:0] req_onehot_fifo[NUM_CLIENTS];

    // Double the request vector
    assign double_req = {req, req};

    // Priority encoder with mask
    always_comb begin
        double_req_onehot = '0;
        for (int i = 0; i < NUM_CLIENTS*2; i++) begin
            if (double_req[i] && grant_pointer[i % NUM_CLIENTS]) begin
                double_req_onehot[i] = 1'b1;
                break;
            end
        end
    end

    // Extract onehot req signal
    assign req_onehot = double_req_onehot[NUM_CLIENTS-1:0] | double_req_onehot[NUM_CLIENTS*2-1:NUM_CLIENTS];

    always_comb begin
        // Shift the FIFO
        for (int i = 0; i < NUM_CLIENTS-1; i++) begin
            req_onehot_fifo[i] = req_onehot_fifo[i+1];
        end
        req_onehot_fifo[NUM_CLIENTS-1] = req_onehot;
    end


    // If the client is granted and req is active, we need to hold the grant pointer.
    assign grant_occupied = |(grant_pointer & req);
    // Check if there is any request
    assign has_freq = |req;

    // Update grant pointer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grant_pointer <= {{(NUM_CLIENTS-1){1'b0}}, 1'b1};
        end else if (has_freq & ~grant_occupied) begin
            grant_pointer <= {grant_pointer[NUM_CLIENTS-2:0], grant_pointer[NUM_CLIENTS-1]};
        end
    end
endmodule
