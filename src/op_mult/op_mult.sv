module op_mult #(
    parameter N        = 16,
    parameter SATURATE = 1,
    parameter SIGNED   = 1
) (
    input  logic [N-1:0]     a,
    input  logic [N-1:0]     b,
    output logic [2*N-1:0]   result,
    output logic             ov
);

    // -----------------------------------------------------------------
    // Internal signals: use an extra bit to reliably detect overflow
    // -----------------------------------------------------------------
    localparam W = 2 * N;  // output width

    generate
        if (SIGNED) begin : gen_signed
            // ---- Signed path ----
            // Extend to (2N+1) bits so we can detect overflow
            logic signed [W:0] product_ext;  // 2N+1 bits
            logic signed [W-1:0] product;     // 2N bits

            always_comb begin
                product_ext = $signed(a) * $signed(b);  // (2N+1)-bit result
                product     = product_ext[W-1:0];

                // Positive overflow:  product_ext > max positive of 2N-bit signed
                // Negative overflow:  product_ext < min negative of 2N-bit signed
                // Equivalently: overflow if product_ext[W] != product_ext[W-1]
                if (product_ext[W] != product_ext[W-1]) begin
                    ov = 1'b1;
                    if (SATURATE) begin
                        if (product_ext[W]) // negative overflow
                            result = {1'b1, {(W-1){1'b0}}};  // -2^(2N-1)
                        else                // positive overflow
                            result = {1'b0, {(W-1){1'b1}}};  //  2^(2N-1)-1
                    end else begin
                        result = product;
                    end
                end else begin
                    ov     = 1'b0;
                    result = product;
                end
            end

        end else begin : gen_unsigned
            // ---- Unsigned path ----
            // N-bit unsigned * N-bit unsigned fits exactly in 2N bits,
            // so overflow is inherently impossible. Keep the logic for
            // completeness / future-proofing if someone changes widths.
            logic [W:0] product_ext;  // 2N+1 bits
            logic [W-1:0] product;

            always_comb begin
                product_ext = a * b;  // zero-extended multiply
                product     = product_ext[W-1:0];

                if (product_ext[W]) begin  // bit beyond 2N is set
                    ov = 1'b1;
                    if (SATURATE)
                        result = {W{1'b1}};  // 2^(2N)-1
                    else
                        result = product;
                end else begin
                    ov     = 1'b0;
                    result = product;
                end
            end
        end
    endgenerate

endmodule
