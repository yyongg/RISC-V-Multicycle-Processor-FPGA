// Flags after SUB (num_a - num_b):
//   BEQ  : zero              BNE  : ~zero
//   BLT  : negative^overflow BGE  : ~(negative^overflow)
//   BLTU : carry (borrow)    BGEU : ~carry

module alu#(
    parameter int BIT_LENGTH = 32,
    localparam int SHAMT = $clog2(BIT_LENGTH),
    localparam int MSB = BIT_LENGTH-1
)(
    input logic [3:0] opcode,
    input logic [MSB:0] num_a,
    input logic [MSB:0] num_b,

    output logic [MSB:0] result,
    output logic zero,
    output logic overflow,
    output logic negative,
    output logic carry
);
    logic [BIT_LENGTH:0] wide;
    logic [2*BIT_LENGTH-1:0] rot;
    logic [2*BIT_LENGTH-1:0] prod;

    // mux for ALU control
    always_comb begin
        overflow = 1'b0;
        carry = 1'b0;
        wide = 0;
        rot = 0;

        case (opcode)
            4'b0000: begin                                          // ADD
                // create an extra bit for carry
                wide = {1'b0, num_a} + {1'b0, num_b};
                result = wide[MSB:0];
                carry = wide[BIT_LENGTH];
                overflow = (num_a[MSB] == num_b[MSB]) && (result[MSB] != num_a[MSB]);
            end
            4'b0001: result = num_a << num_b[SHAMT-1:0];            // SLL
            4'b0010: result = $signed(num_a) < $signed(num_b);      // SLT
            4'b0011: result = num_a < num_b;                        // SLTU
            4'b0100: result = num_a ^ num_b;                        // XOR
            4'b0101: result = num_a >> num_b[SHAMT-1:0];            // SRL
            4'b0110: result = num_a | num_b;                        // OR (bitwise)
            4'b0111: result = num_a & num_b;                        // AND (bitwise)
            4'b1000: begin                                          // SUB
                // create an extra bit for carry
                wide = {1'b0, num_a} - {1'b0, num_b};
                result = wide[MSB:0];
                carry = wide[BIT_LENGTH];   // BORROW: 1 when num_a < num_b (unsigned)
                overflow = (num_a[MSB] != num_b[MSB]) && (result[MSB] != num_a[MSB]);
            end
            4'b1101: result = $signed(num_a) >>> num_b[SHAMT-1:0];  // SRA
            4'b1110: begin                                          // ROR: rotate right by num_b
                rot    = {num_a, num_a} >> num_b[SHAMT-1:0];
                result = rot[MSB:0];
            end
            4'b1111: begin                                          // ROL: rotate left by num_b
                rot    = {num_a, num_a} << num_b[SHAMT-1:0];
                result = rot[2*BIT_LENGTH-1:BIT_LENGTH];
            end
            default: result = num_a;                                // pass
        endcase

        zero = (result==0);
        negative = result[MSB];
    end
endmodule
