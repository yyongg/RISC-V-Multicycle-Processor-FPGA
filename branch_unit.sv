module branch_unit(
    input  logic [2:0] funct3,
    input  logic zero, negative, overflow, carry,
    output logic take_branch
);
// BEQ=zero, BNE=~zero, BLT=n^v, BGE=~(n^v), BLTU=carry, BGEU=~carry
// funct3[2:1] picks the condition, funct3[0] inverts it
    logic cond;
    always_comb begin
        case (funct3[2:1])
            2'b00:   cond = zero;                 // BEQ / BNE
            2'b10:   cond = negative ^ overflow;  // BLT / BGE
            2'b11:   cond = carry;                // BLTU / BGEU
            default: cond = 1'b0;
        endcase
    end
    assign take_branch = cond ^ funct3[0];
endmodule
