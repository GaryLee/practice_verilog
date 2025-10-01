module round_robin_arbiter #(
    parameter int NUM_PORTS = 4,
    parameter int PORT_WIDTH = $clog2(NUM_PORTS)
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [NUM_PORTS-1:0]    req,        // Request signals
    output logic [NUM_PORTS-1:0]    grant,      // Grant signals
    output logic [PORT_WIDTH-1:0]   grant_id,   // Granted port ID
    output logic                    grant_valid // Grant valid signal
);

    // Internal signals
    logic [NUM_PORTS-1:0] priority_mask;
    logic [NUM_PORTS-1:0] masked_req;
    logic [NUM_PORTS-1:0] unmasked_req;
    logic [NUM_PORTS-1:0] grant_masked;
    logic [NUM_PORTS-1:0] grant_unmasked;
    logic                 no_req_masked;

    // Priority mask register - tracks next priority to serve
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_mask <= '1;  // All ports have priority on reset
        end else if (grant_valid) begin
            // Update priority mask: granted port and lower priority ports lose priority
            priority_mask <= priority_mask & ~((grant - 1'b1) | grant);
            
            // If all ports lose priority, reset mask
            if ((priority_mask & ~((grant - 1'b1) | grant)) == '0) begin
                priority_mask <= '1;
            end
        end
    end

    // Generate masked requests
    assign masked_req = req & priority_mask;
    assign unmasked_req = req;

    // Check if there are any masked requests
    assign no_req_masked = (masked_req == '0);

    // Priority encoder for masked requests
    always_comb begin
        grant_masked = '0;
        for (int i = 0; i < NUM_PORTS; i++) begin
            if (masked_req[i]) begin
                grant_masked[i] = 1'b1;
                break;
            end
        end
    end

    // Priority encoder for unmasked requests
    always_comb begin
        grant_unmasked = '0;
        for (int i = 0; i < NUM_PORTS; i++) begin
            if (unmasked_req[i]) begin
                grant_unmasked[i] = 1'b1;
                break;
            end
        end
    end

    // Select final grant signal
    assign grant = no_req_masked ? grant_unmasked : grant_masked;
    assign grant_valid = |req;

    // Generate grant ID
    always_comb begin
        grant_id = '0;
        for (int i = 0; i < NUM_PORTS; i++) begin
            if (grant[i]) begin
                grant_id = i[PORT_WIDTH-1:0];
                break;
            end
        end
    end

endmodule

// Alternative implementation using more synthesizable approach
module round_robin_arbiter_v2 #(
    parameter NUM_PORTS = 4,
    parameter PORT_WIDTH = $clog2(NUM_PORTS)
) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [NUM_PORTS-1:0]    req,
    output logic [NUM_PORTS-1:0]    grant,
    output logic [PORT_WIDTH-1:0]   grant_id,
    output logic                    grant_valid
);

    // Round robin pointer
    logic [PORT_WIDTH-1:0] rr_ptr;
    
    // Rotated request and grant vectors
    logic [NUM_PORTS-1:0] req_rotated;
    logic [NUM_PORTS-1:0] grant_rotated;
    
    // Update round robin pointer
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rr_ptr <= '0;
        end else if (grant_valid) begin
            if (rr_ptr == NUM_PORTS - 1) begin
                rr_ptr <= '0;
            end else begin
                rr_ptr <= rr_ptr + 1'b1;
            end
        end
    end
    
    // Rotate request vector based on round robin pointer
    always_comb begin
        for (int i = 0; i < NUM_PORTS; i++) begin
            req_rotated[i] = req[(i + rr_ptr) % NUM_PORTS];
        end
    end
    
    // Priority encoder for rotated requests
    always_comb begin
        grant_rotated = '0;
        for (int i = 0; i < NUM_PORTS; i++) begin
            if (req_rotated[i]) begin
                grant_rotated[i] = 1'b1;
                break;
            end
        end
    end
    
    // Rotate grant vector back to original positions
    always_comb begin
        for (int i = 0; i < NUM_PORTS; i++) begin
            grant[i] = grant_rotated[(i - rr_ptr + NUM_PORTS) % NUM_PORTS];
        end
    end
    
    // Generate grant valid and grant ID
    assign grant_valid = |req;
    
    always_comb begin
        grant_id = '0;
        for (int i = 0; i < NUM_PORTS; i++) begin
            if (grant[i]) begin
                grant_id = i[PORT_WIDTH-1:0];
                break;
            end
        end
    end

endmodule

// Testbench
module tb_round_robin_arbiter;
    parameter NUM_PORTS = 4;
    parameter PORT_WIDTH = $clog2(NUM_PORTS);

    logic                    clk;
    logic                    rst_n;
    logic [NUM_PORTS-1:0]    req;
    logic [NUM_PORTS-1:0]    grant;
    logic [PORT_WIDTH-1:0]   grant_id;
    logic                    grant_valid;

    // Instantiate the arbiter
    round_robin_arbiter #(
        .NUM_PORTS(NUM_PORTS)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .req(req),
        .grant(grant),
        .grant_id(grant_id),
        .grant_valid(grant_valid)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        // Initialize
        rst_n = 0;
        req = 4'b0000;
        
        // Reset
        repeat(2) @(posedge clk);
        rst_n = 1;
        
        // Test case 1: All ports request simultaneously
        @(posedge clk);
        req = 4'b1111;
        repeat(8) @(posedge clk);
        
        // Test case 2: Partial port requests
        req = 4'b1010;
        repeat(4) @(posedge clk);
        
        // Test case 3: Single port request
        req = 4'b0100;
        repeat(2) @(posedge clk);
        
        // Test case 4: No requests
        req = 4'b0000;
        repeat(2) @(posedge clk);
        
        // Test case 5: Intermittent requests
        req = 4'b1001;
        repeat(3) @(posedge clk);
        req = 4'b0110;
        repeat(3) @(posedge clk);
        
        $finish;
    end

    // Monitor outputs
    always @(posedge clk) begin
        if (grant_valid) begin
            $display("Time: %0t, REQ: %b, GRANT: %b, GRANT_ID: %0d", 
                     $time, req, grant, grant_id);
        end
    end

    // Check for multiple grants (should never happen)
    always @(posedge clk) begin
        if (grant_valid && $countones(grant) > 1) begin
            $error("Multiple grants detected at time %0t: GRANT = %b", $time, grant);
        end
    end

endmodule

