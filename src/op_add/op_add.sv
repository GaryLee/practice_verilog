module op_add #(
    parameter N        = 16,
    parameter SATURATE = 1,
    parameter SIGNED   = 1
) (
    input  logic [N-1:0]  a,
    input  logic [N-1:0]  b,
    output logic [N-1:0]  result,
    output logic          ov,
    output logic          uv
);

    generate
        if (SIGNED) begin : gen_signed
            // ---- Signed path ----
            logic signed [N:0] sum_ext;  // (N+1)-bit to capture overflow

            always_comb begin
                sum_ext = $signed(a) + $signed(b);

                // Positive overflow:  sum_ext > 2^(N-1)-1
                // Negative overflow:  sum_ext < -2^(N-1)
                // Detected by: sum_ext[N] != sum_ext[N-1]
                //   positive overflow when sum_ext[N]==0 && sum_ext[N-1]==1
                //   negative overflow when sum_ext[N]==1 && sum_ext[N-1]==0

                if (sum_ext[N] != sum_ext[N-1]) begin
                    if (~sum_ext[N]) begin
                        // Positive overflow (sum_ext positive but too large)
                        ov = 1'b1;
                        uv = 1'b0;
                        if (SATURATE)
                            result = {1'b0, {(N-1){1'b1}}};  //  2^(N-1)-1
                        else
                            result = sum_ext[N-1:0];
                    end else begin
                        // Negative overflow (underflow)
                        ov = 1'b0;
                        uv = 1'b1;
                        if (SATURATE)
                            result = {1'b1, {(N-1){1'b0}}};  // -2^(N-1)
                        else
                            result = sum_ext[N-1:0];
                    end
                end else begin
                    ov     = 1'b0;
                    uv     = 1'b0;
                    result = sum_ext[N-1:0];
                end
            end

        end else begin : gen_unsigned
            // ---- Unsigned path ----
            logic [N:0] sum_ext;  // (N+1)-bit to capture carry-out

            always_comb begin
                sum_ext = {1'b0, a} + {1'b0, b};

                if (sum_ext[N]) begin
                    // Unsigned positive overflow (carry out)
                    ov = 1'b1;
                    uv = 1'b0;  // unsigned can't underflow on addition
                    if (SATURATE)
                        result = {N{1'b1}};  // 2^N - 1
                    else
                        result = sum_ext[N-1:0];
                end else begin
                    ov     = 1'b0;
                    uv     = 1'b0;
                    result = sum_ext[N-1:0];
                end
            end
        end
    endgenerate

endmodule
