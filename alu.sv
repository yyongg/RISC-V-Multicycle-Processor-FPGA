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
        case (opcode)
            4'b0000: begin  // addition
                wide = {1'b0, num_a} + {1'b0, num_b};   // create an extra bit for carry
                result = wide[MSB:0];
                carry = wide[BIT_LENGTH];
                overflow = (num_a[MSB] == num_b[MSB]) && (result[MSB] != num_a[MSB]);
            end

            4'b0001: begin  // subtraction
                wide = {1'b0, num_a} - {1'b0, num_b};   // create an extra bit for carry
                result = wide[MSB:0];
                carry = wide[BIT_LENGTH];
                overflow = (num_a[MSB] != num_b[MSB]) && (result[MSB] != num_a[MSB]);
            end
            4'b0010: result = num_a * num_b; // multiplicatiion
            4'b0011: result = num_a / num_b; // division
            4'b0100: result = num_a & num_b; // bitwise AND
            4'b0101: result = num_a | num_b; // bitwise OR
            4'b0110: result = num_a ^ num_b; // bitwise XOR
            4'b0111: result = ~(num_a | num_b); // bitwise NOR
            4'b1000: result = !num_a; // bitwise invert operand A
            4'b1001: result = ~(num_a & num_b); // bitwise NAND
            4'b1010: result = num_a << 1; // shift left
            4'b1011: result = num_b >> 1; // shift right 1
            4'b1100: result = {num_a[BIT_LENGTH-2:0], num_a[BIT_LENGTH-1]}; // rotate left (ROL)
            4'b1101: result = {num_a[0],num_a[BIT_LENGTH-1:1]}; // rotate right (ROR)
            4'b1110: result = 0; // compare
            4'b1111: result = num_a; // pass
            default: result = 0;
        endcase
    end

    assign zero = result == 0;
    assign negative = result[0]
endmodule
