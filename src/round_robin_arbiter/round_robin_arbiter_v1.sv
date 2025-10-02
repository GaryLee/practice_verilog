module round_robin_arbiter_v1 #(
    parameter int NUM_CLIENTS = 4
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [NUM_CLIENTS-1:0]  req,
    output logic [NUM_CLIENTS-1:0]  grant
);

    logic [NUM_CLIENTS-1:0] priority_mask;
    logic [NUM_CLIENTS-1:0] masked_req;
    logic [NUM_CLIENTS-1:0] unmasked_req;
    logic [NUM_CLIENTS-1:0] grant_masked;
    logic [NUM_CLIENTS-1:0] grant_unmasked;
    logic                   mask_valid;

    // Mask the requests based on priority
    assign masked_req = req & priority_mask;
    assign unmasked_req = req;

    // Priority encoder for masked requests
    always_comb begin
        grant_masked = '0;
        for (int i = 0; i < NUM_CLIENTS; i++) begin
            if (masked_req[i]) begin
                grant_masked[i] = 1'b1;
                break;
            end
        end
    end

    // Priority encoder for unmasked requests
    always_comb begin
        grant_unmasked = '0;
        for (int i = 0; i < NUM_CLIENTS; i++) begin
            if (unmasked_req[i]) begin
                grant_unmasked[i] = 1'b1;
                break;
            end
        end
    end

    // Check if any masked request exists
    assign mask_valid = |masked_req;

    // Select between masked and unmasked grant
    assign grant = mask_valid ? grant_masked : grant_unmasked;

    // Update priority mask for next cycle
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_mask <= '1;
        end else if (|grant) begin
            // Update mask to give priority to clients after the granted one
            priority_mask <= {NUM_CLIENTS{1'b1}} << (find_grant_position(grant) + 1);
            
            // If no higher priority requests, wrap around
            if (priority_mask == '0) begin
                priority_mask <= '1;
            end
        end
    end

    // Function to find the position of granted client
    function automatic int find_grant_position(logic [NUM_CLIENTS-1:0] grant_sig);
        for (int i = 0; i < NUM_CLIENTS; i++) begin
            if (grant_sig[i]) return i;
        end
        return 0;
    endfunction

endmodule
