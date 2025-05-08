
module signed_adder #(parameter N = 8) (
    input logic [N-1:0] a,
    input logic [N-1:0] b,
    output logic [N-1:0] sum,
    output logic ov, // Overflow flag
    output logic uv  // Underflow flag
);
    localparam logic [N-1:0] MAX_VALUE = (1 << (N-1)) - 1; // Maximum positive value
    localparam logic [N-1:0] MIN_VALUE = 1 << (N-1);       // Minimum negative value

    logic [N:0] extended_sum; // N+1 bits to check for overflow

    always_comb begin
        extended_sum = {a[N-1], a} + {b[N-1], b};

        // Calculate overflow and underflow flags
        ov = (extended_sum[N] == 1 && extended_sum[N-1] == 0);
        uv = (extended_sum[N] == 0 && extended_sum[N-1] == 1);

        // Set output based on flags
        if (ov) begin
            sum = MAX_VALUE; // Overflow, saturate to maximum value
        end else if (uv) begin
            sum = MIN_VALUE; // Underflow, saturate to minimum value
        end else begin
            sum = extended_sum[N-1:0]; // No overflow or underflow
        end
    end
endmodule
