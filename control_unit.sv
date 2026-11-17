module control_unit(
    input logic [6:0] opcode,       // instr[6:0]
    input logic [2:0] funct3,       // instr[14:12]
    input logic [6:0] funct7,       // instr[31:25]

    output logic reg_write,         // Enables writing data back into the destination
                                    // register (rd) in the register file
    output logic mem_write,         // Enables a write operation to the data memory
    output logic mem_read,          // Instruction is a load (LW, LB, LH, etc.); tells the
                                    // FSM to wait a cycle for the synchronous memory read
    output logic branch,            // Instruction is a conditional branch (taken/not-taken
                                    // is decided by the branch unit)
    output logic jump,              // Instruction is JAL / JALR: redirect the PC to the jump
                                    // target and save the return address (PC + 4) into rd
    output logic is_jalr,           // Distinguishes JALR (target = (rs1 + imm) & ~1) from
                                    // JAL (target = PC + imm)
    output logic [1:0] alu_src_a,   // ALU operand A: 0 = rs1, 1 = PC (AUIPC), 2 = zero (LUI)
    output logic alu_src_b,         // ALU operand B: 0 = rs2, 1 = sign-extended immediate
    output logic [3:0] alu_ctrl,    // 4-bit ALU opcode, connected directly to alu.opcode
                                    // (equals {funct7[5], funct3} for R-type)
    output logic [1:0] result_src   // Write-back mux: 0 = ALU result, 1 = data memory,
                                    // 2 = PC + 4 (JAL / JALR)
);
    localparam logic [3:0] ALU_ADD = 4'b0000;
    localparam logic [3:0] ALU_SUB = 4'b1000;

    always_comb begin
        reg_write  = 1'b0;  mem_write = 1'b0;  mem_read = 1'b0;
        branch     = 1'b0;  jump      = 1'b0;  is_jalr  = 1'b0;
        alu_src_a  = 2'd0;  alu_src_b = 1'b0;
        alu_ctrl   = 4'b0000;
        result_src = 2'd0;

        case (opcode)
            // R-type ALU
            7'b0110011: begin
                reg_write = 1'b1;
                alu_ctrl  = {funct7[5], funct3};
            end

            // I-type ALU
            7'b0010011: begin
                reg_write = 1'b1;
                alu_src_b = 1'b1;
                // bit 30 picks SRAI vs SRLI; in other I-types it's part of the immediate
                alu_ctrl  = {(funct3 == 3'b101) & funct7[5], funct3};
            end

            // I-type Memory Load
            7'b0000011: begin
            end

            // I-type Indirect Jump
            7'b1100111: begin
            end

            // I-type System and CSR
            7'b1110011: begin
            end

            // I-type Memory Fence
            7'b0001111: begin
            end

            // S-type Memory Store
            7'b0100011: begin
            end

            // B-type Conditional Branches
            7'b1100011: begin
            end

            // U-type Load Upper Immediate
            7'b0110111: begin
            end

            // U-type Add Upper Immediate to PC
            7'b0010111: begin
            end

            // J-type Unconditional Jump & Link
            7'b1101111: begin
            end
        endcase
    end
endmodule
