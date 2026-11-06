module alu#(
    parameter int BIT_LENGTH = 8,
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
    logic [2*BIT_LENGTH-1:0] prod;

    // mux for ALU control
    always_comb begin
        overflow = 1'b0;
        negative = 1'b0;
        carry = 1'b0;
        wide = 0;
        prod = 0;
        result = num_a;

        case (opcode)
            4'b0000: begin  // ADD
                wide = {1'b0, num_a} + {1'b0, num_b};   // create an extra bit for carry
                result = wide[MSB:0];
                carry = wide[BIT_LENGTH];
                overflow = (num_a[MSB] == num_b[MSB]) && (result[MSB] != num_a[MSB]);
            end
            4'b0001: result = num_a << num_b[4:0]; // SLL
            4'b0010: result = $signed(num_a) < $signed(num_b); // SLT
            4'b0011: result = num_a < num_b; // SLTU
            4'b0100: result = num_a ^ num_b; // XOR
            4'b0101: result = num_a >> num_b[4:0]; // SRL
            4'b0110: result = num_a | num_b; // OR (bitwise)
            4'b0111: result = num_a & num_b; // AND (bitwise)
            4'b1000: begin  // SUB
                wide = {1'b0, num_a} - {1'b0, num_b};   // create an extra bit for carry
                result = wide[MSB:0];
                carry = wide[BIT_LENGTH];
                overflow = (num_a[MSB] != num_b[MSB]) && (result[MSB] != num_a[MSB]);
            end
            4'b1001: begin  // MUL
                prod = num_a*num_b;
                result = prod[MSB:0];
                carry = |prod[2*BIT_LENGTH-1:BIT_LENGTH];
                overflow = carry;
            end
            4'b1010: begin  // MULH
                prod = num_a*num_b;
                result = prod[2*BIT_LENGTH-1:BIT_LENGTH];
            end
            4'b1011: begin end
            4'b1100: begin end
            4'b1101: begin end
            4'b1110: result = {num_a[0],num_a[BIT_LENGTH-1:1]}; // rotate right (ROR)
            4'b1111: result = {num_a[BIT_LENGTH-2:0], num_a[BIT_LENGTH-1]}; // rotate left (ROL)
            default: result = num_a; // pass
        endcase

        zero = result==0;
    end

    assign negative = result[0];
endmodule
