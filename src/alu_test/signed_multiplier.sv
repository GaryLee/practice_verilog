/**
 * @file signed_multiplier.sv Signed multiplication module with saturation supported.
 * 
 * This module implements a signed multiplier with overflow and underflow detection.
 * It takes two signed N-bit inputs and produces a signed N-bit output.
 * The module also provides overflow and underflow flags.
 */
module signed_multiplier #(parameter N = 8) (
    input logic signed [N-1:0] a,
    input logic signed [N-1:0] b,
    output logic signed [N-1:0] product,
    output logic ov, // Overflow flag
    output logic uv  // Underflow flag
);
    localparam logic signed [N-1:0] MAX_VALUE = (1 << (N-1)) - 1; // Maximum positive value
    localparam logic signed [N-1:0] MIN_VALUE = -(1 << (N-1));    // Minimum negative value

    logic signed [2*N-1:0] extended_product; // 2N bits to check for overflow

    always_comb begin
        extended_product = a * b;

        // Calculate overflow and underflow flags
        ov = (extended_product[2*N-1] == 0 && extended_product[2*N-2:N-1] != 0); // Overflow check for positive result
        uv = (extended_product[2*N-1] == 1 && extended_product[2*N-2:N-1] != {N-1{1'b1}}); // Underflow check for negative result

        // Set output based on flags
        if (ov) begin
            product = MAX_VALUE; // Overflow, saturate to max value
        end else if (uv) begin
            product = MIN_VALUE; // Underflow, saturate to min value
        end else begin
            product = extended_product[N-1:0]; // No overflow or underflow
        end
    end
endmodule
