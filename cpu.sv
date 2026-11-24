// RV32I multi-cycle CPU
// FETCH -> DECODE -> EXECUTE -> (MEM, loads only) -> FETCH

module cpu (
    input  logic        clk,
    input  logic        reset,          // active-high synchronous reset
    // instruction memory
    output logic [31:0] imem_address,
    input  logic [31:0] imem_data_out,
    // data memory
    output logic [31:0] dmem_address,
    output logic [31:0] dmem_data_in,
    output logic        dmem_wren,
    output logic [2:0]  mem_funct3,     // -> memory.funct3 (access size / signedness)
    input  logic [31:0] dmem_data_out
);
    localparam logic [31:0] PC_RESET = 32'h0000_1000;

    typedef enum logic [1:0] { FETCH, DECODE, EXECUTE, MEM } state_t;
    state_t state = FETCH;

    logic [31:0] pc    = PC_RESET;
    logic [31:0] instr = 32'h0000_0013;   // NOP (addi x0, x0, 0)

    // instruction fields
    logic [6:0] opcode, funct7;
    logic [2:0] funct3;
    logic [4:0] rs1, rs2, rd;
    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    // control
    logic       reg_write, mem_write, mem_read, branch, jump, is_jalr, alu_src_b;
    logic [1:0] alu_src_a, result_src;
    logic [3:0] alu_ctrl;

    control_unit cu (
        .opcode(opcode), .funct3(funct3), .funct7(funct7),
        .reg_write(reg_write), .mem_write(mem_write), .mem_read(mem_read),
        .branch(branch), .jump(jump), .is_jalr(is_jalr),
        .alu_src_a(alu_src_a), .alu_src_b(alu_src_b),
        .alu_ctrl(alu_ctrl), .result_src(result_src)
    );

    // immediate
    logic [31:0] imm;
    immgen ig (.inst(instr), .imm(imm));

    // register file
    logic [31:0] rs1_data, rs2_data, rd_data;
    logic        rf_we;

    regfile rf (
        .clk(clk), .we(rf_we),
        .rs1_addr(rs1), .rs2_addr(rs2), .rd_addr(rd),
        .rd_data(rd_data),
        .rs1_data(rs1_data), .rs2_data(rs2_data)
    );

    // ALU
    logic [31:0] alu_a, alu_b, alu_result;
    logic        zero, overflow, negative, carry;

    always_comb begin
        case (alu_src_a)
            2'd0:    alu_a = rs1_data;
            2'd1:    alu_a = pc;        // AUIPC
            default: alu_a = 32'd0;     // LUI
        endcase
    end
    assign alu_b = alu_src_b ? imm : rs2_data;

    alu alu_i (
        .opcode(alu_ctrl), .num_a(alu_a), .num_b(alu_b),
        .result(alu_result), .zero(zero), .overflow(overflow),
        .negative(negative), .carry(carry)
    );

    // branch decision
    logic take_branch;
    branch_unit bu (
        .funct3(funct3), .zero(zero), .negative(negative),
        .overflow(overflow), .carry(carry), .take_branch(take_branch)
    );

    // next PC
    logic [31:0] pc_plus4, pc_target, pc_next;
    assign pc_plus4  = pc + 32'd4;
    assign pc_target = pc + imm;                    // branches and JAL

    always_comb begin
        if (jump && is_jalr)            pc_next = alu_result & ~32'd1;  // JALR
        else if (jump)                  pc_next = pc_target;            // JAL
        else if (branch && take_branch) pc_next = pc_target;            // taken branch
        else                            pc_next = pc_plus4;
    end

    // write-back
    always_comb begin
        case (result_src)
            2'd0:    rd_data = alu_result;
            2'd1:    rd_data = dmem_data_out;
            2'd2:    rd_data = pc_plus4;
            default: rd_data = alu_result;
        endcase
    end

    // write rd at the end of EXECUTE (non-loads) or at the end of MEM (loads)
    assign rf_we = reg_write &&
                   (((state == EXECUTE) && !mem_read) || (state == MEM));

    // memory interface
    assign imem_address = pc;
    assign dmem_address = alu_result;
    assign dmem_data_in = rs2_data;
    assign mem_funct3   = funct3;
    assign dmem_wren    = mem_write && (state == EXECUTE);   // write exactly once

    // FSM
    always_ff @(posedge clk) begin
        if (reset) begin
            state <= FETCH;
            pc    <= PC_RESET;
            instr <= 32'h0000_0013;
        end else begin
            case (state)
                FETCH:   state <= DECODE;          // imem latches mem[pc] this edge
                DECODE: begin
                    instr <= imem_data_out;        // instruction is valid now
                    state <= EXECUTE;
                end
                EXECUTE: begin
                    if (mem_read) begin
                        state <= MEM;              // dmem latches the load this edge
                    end else begin
                        pc    <= pc_next;
                        state <= FETCH;
                    end
                end
                MEM: begin
                    pc    <= pc_plus4;             // rd is written by rf_we this edge
                    state <= FETCH;
                end
                default: state <= FETCH;
            endcase
        end
    end

endmodule