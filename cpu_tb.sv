// Testbench for the RV32I multi-cycle CPU
//
// A short test program with representative examples of each RV32I
// instruction class is loaded into instruction memory. The bench prints
// every register write as it happens (the simulation trace), then checks
// the final register, data memory, and LED register values once the
// program reaches its halt loop (jal x0, 0).

`timescale 1ns/1ps

`include "memory.sv"
`include "cpu.sv"
`include "control_unit.sv"
`include "immgen.sv"
`include "regfile.sv"
`include "alu.sv"
`include "branch_unit.sv"

module cpu_tb;

    logic clk = 0, reset = 1;
    always #5 clk = ~clk;

    logic [31:0] imem_address, imem_data_out;
    logic [31:0] dmem_address, dmem_data_in, dmem_data_out;
    logic        dmem_wren;
    logic [2:0]  mem_funct3;
    logic        mem_reset, led, red, green, blue;

    memory u_mem (
        .clk(clk), .funct3(mem_funct3), .dmem_wren(dmem_wren),
        .dmem_address(dmem_address), .dmem_data_in(dmem_data_in),
        .imem_address(imem_address), .imem_data_out(imem_data_out),
        .dmem_data_out(dmem_data_out), .reset(mem_reset),
        .led(led), .red(red), .green(green), .blue(blue)
    );

    cpu u_cpu (
        .clk(clk), .reset(reset),
        .imem_address(imem_address), .imem_data_out(imem_data_out),
        .dmem_address(dmem_address), .dmem_data_in(dmem_data_in),
        .dmem_wren(dmem_wren), .mem_funct3(mem_funct3),
        .dmem_data_out(dmem_data_out)
    );

    // Test program (address: assembly). Starts at 0x1000.
    logic [31:0] prog [0:53];

    initial begin
    // U-type
    prog[ 0] = 32'h123450b7;  // 1000: lui   x1, 0x12345
    prog[ 1] = 32'h00001117;  // 1004: auipc x2, 0x1
    // I-type ALU
    prog[ 2] = 32'h06400193;  // 1008: addi  x3, x0, 100
    prog[ 3] = 32'hff900213;  // 100c: addi  x4, x0, -7
    prog[ 4] = 32'h00022293;  // 1010: slti  x5, x4, 0
    prog[ 5] = 32'h00023313;  // 1014: sltiu x6, x4, 0
    prog[ 6] = 32'h0ff1c393;  // 1018: xori  x7, x3, 0xff
    prog[ 7] = 32'h0f027413;  // 101c: andi  x8, x4, 0xf0
    prog[ 8] = 32'h00419493;  // 1020: slli  x9, x3, 4
    prog[ 9] = 32'h01c25513;  // 1024: srli  x10, x4, 28
    prog[10] = 32'h40125593;  // 1028: srai  x11, x4, 1
    // R-type
    prog[11] = 32'h00418633;  // 102c: add   x12, x3, x4
    prog[12] = 32'h403206b3;  // 1030: sub   x13, x4, x3
    prog[13] = 32'h00a19733;  // 1034: sll   x14, x3, x10
    prog[14] = 32'h003227b3;  // 1038: slt   x15, x4, x3
    prog[15] = 32'h00323833;  // 103c: sltu  x16, x4, x3
    prog[16] = 32'h0041c8b3;  // 1040: xor   x17, x3, x4
    prog[17] = 32'h00a25933;  // 1044: srl   x18, x4, x10
    prog[18] = 32'h40a259b3;  // 1048: sra   x19, x4, x10
    prog[19] = 32'h0011ea33;  // 104c: or    x20, x3, x1
    prog[20] = 32'h00327ab3;  // 1050: and   x21, x4, x3
    // S-type stores
    prog[21] = 32'h10102023;  // 1054: sw    x1, 0x100(x0)
    prog[22] = 32'h10401223;  // 1058: sh    x4, 0x104(x0)
    prog[23] = 32'h10300323;  // 105c: sb    x3, 0x106(x0)
    prog[24] = 32'h104003a3;  // 1060: sb    x4, 0x107(x0)
    // I-type loads
    prog[25] = 32'h10002b03;  // 1064: lw    x22, 0x100(x0)
    prog[26] = 32'h10401b83;  // 1068: lh    x23, 0x104(x0)
    prog[27] = 32'h10405c03;  // 106c: lhu   x24, 0x104(x0)
    prog[28] = 32'h10700c83;  // 1070: lb    x25, 0x107(x0)
    prog[29] = 32'h10704d03;  // 1074: lbu   x26, 0x107(x0)
    // B-type: every taken branch skips a 'poison' addi x31, x31, 1
    prog[30] = 32'h00000f93;  // 1078: addi  x31, x0, 0     (clear poison counter)
    prog[31] = 32'h00318463;  // 107c: beq   x3, x3, +8     taken
    prog[32] = 32'h001f8f93;  // 1080: addi  x31, x31, 1    (poison)
    prog[33] = 32'h00319463;  // 1084: bne   x3, x3, +8     not taken
    prog[34] = 32'h00100d93;  // 1088: addi  x27, x0, 1     (must run)
    prog[35] = 32'h00419463;  // 108c: bne   x3, x4, +8     taken
    prog[36] = 32'h001f8f93;  // 1090: addi  x31, x31, 1    (poison)
    prog[37] = 32'h00324463;  // 1094: blt   x4, x3, +8     taken
    prog[38] = 32'h001f8f93;  // 1098: addi  x31, x31, 1    (poison)
    prog[39] = 32'h0041d463;  // 109c: bge   x3, x4, +8     taken
    prog[40] = 32'h001f8f93;  // 10a0: addi  x31, x31, 1    (poison)
    prog[41] = 32'h0041e463;  // 10a4: bltu  x3, x4, +8     taken
    prog[42] = 32'h001f8f93;  // 10a8: addi  x31, x31, 1    (poison)
    prog[43] = 32'h00327463;  // 10ac: bgeu  x4, x3, +8     taken
    prog[44] = 32'h001f8f93;  // 10b0: addi  x31, x31, 1    (poison)
    prog[45] = 32'h00300e13;  // 10b4: addi  x28, x0, 3
    prog[46] = 32'hfffe0e13;  // 10b8: addi  x28, x28, -1   (loop)
    prog[47] = 32'hfe0e1ee3;  // 10bc: bne   x28, x0, -4    backward, taken twice
    // J-type and jalr
    prog[48] = 32'h00800eef;  // 10c0: jal   x29, +8
    prog[49] = 32'h001f8f93;  // 10c4: addi  x31, x31, 1    (poison)
    prog[50] = 32'h00de8f67;  // 10c8: jalr  x30, 13(x29)   target 0x10d0 (lsb cleared)
    prog[51] = 32'h001f8f93;  // 10cc: addi  x31, x31, 1    (poison)
    // Memory-mapped LED register
    prog[52] = 32'hfe102e23;  // 10d0: sw    x1, -4(x0)     0xFFFFFFFC
    prog[53] = 32'h0000006f;  // 10d4: jal   x0, 0          halt
    end

    // Trace: print every register write
    always @(negedge clk)
        if (!reset && u_cpu.rf_we && u_cpu.rd != 0)
            $display("pc=%h  x%0d <= %h", u_cpu.pc, u_cpu.rd, u_cpu.rd_data);

    // Result checks
    int errors = 0;

    task check(input string name, input logic [31:0] got, input logic [31:0] expected);
        if (got === expected) $display("PASS  %s = %h", name, got);
        else begin
            $display("FAIL  %s = %h (expected %h)", name, got, expected);
            errors++;
        end
    endtask

    function logic [31:0] reg_val(input int r);
        return u_cpu.rf.regs[r];
    endfunction

    function logic [31:0] dmem_word(input logic [31:0] addr);
        return {u_mem.dmem3.memory[addr[11:2]], u_mem.dmem2.memory[addr[11:2]],
                u_mem.dmem1.memory[addr[11:2]], u_mem.dmem0.memory[addr[11:2]]};
    endfunction

    initial begin
        $dumpfile("cpu_tb.vcd");
        $dumpvars(0, cpu_tb);

        // memory_array clears itself at time 0, so load the program after that
        #1;
        for (int i = 0; i < 54; i++) begin
            u_mem.imem0.memory[i] = prog[i][7:0];
            u_mem.imem1.memory[i] = prog[i][15:8];
            u_mem.imem2.memory[i] = prog[i][23:16];
            u_mem.imem3.memory[i] = prog[i][31:24];
        end

        repeat (3) @(posedge clk);
        @(negedge clk) reset = 0;

        // run until the halt instruction is reached (or time out)
        fork
            wait (u_cpu.instr === 32'h0000006f);
            repeat (5000) @(posedge clk);
        join_any
        repeat (4) @(posedge clk);

        $display("\nU-type");
        check("lui   x1",                 reg_val(1),  32'h12345000);
        check("auipc x2",                 reg_val(2),  32'h00002004);
        $display("\nI-type ALU");
        check("addi  x3  (100)",          reg_val(3),  32'h00000064);
        check("addi  x4  (-7)",           reg_val(4),  32'hfffffff9);
        check("slti  x5",                 reg_val(5),  32'h00000001);
        check("sltiu x6",                 reg_val(6),  32'h00000000);
        check("xori  x7",                 reg_val(7),  32'h0000009b);
        check("andi  x8",                 reg_val(8),  32'h000000f0);
        check("slli  x9",                 reg_val(9),  32'h00000640);
        check("srli  x10",                reg_val(10), 32'h0000000f);
        check("srai  x11",                reg_val(11), 32'hfffffffc);
        $display("\nR-type");
        check("add   x12",                reg_val(12), 32'h0000005d);
        check("sub   x13",                reg_val(13), 32'hffffff95);
        check("sll   x14",                reg_val(14), 32'h00320000);
        check("slt   x15",                reg_val(15), 32'h00000001);
        check("sltu  x16",                reg_val(16), 32'h00000000);
        check("xor   x17",                reg_val(17), 32'hffffff9d);
        check("srl   x18",                reg_val(18), 32'h0001ffff);
        check("sra   x19",                reg_val(19), 32'hffffffff);
        check("or    x20",                reg_val(20), 32'h12345064);
        check("and   x21",                reg_val(21), 32'h00000060);
        $display("\nS-type stores");
        check("sw    -> mem[0x100]",      dmem_word(32'h100), 32'h12345000);
        check("sh+sb -> mem[0x104]",      dmem_word(32'h104), 32'hf964fff9);
        check("sw    -> LED reg",         u_mem.leds,         32'h12345000);
        $display("\nI-type loads");
        check("lw    x22",                reg_val(22), 32'h12345000);
        check("lh    x23",                reg_val(23), 32'hfffffff9);
        check("lhu   x24",                reg_val(24), 32'h0000fff9);
        check("lb    x25",                reg_val(25), 32'hfffffff9);
        check("lbu   x26",                reg_val(26), 32'h000000f9);
        $display("\nB-type");
        check("not-taken branch x27",     reg_val(27), 32'h00000001);
        check("backward loop x28",        reg_val(28), 32'h00000000);
        check("poison count x31",         reg_val(31), 32'h00000000);
        $display("\nJ-type / jalr");
        check("jal   x29 (link)",         reg_val(29), 32'h000010c4);
        check("jalr  x30 (link)",         reg_val(30), 32'h000010cc);
        check("halted at pc",             u_cpu.pc,    32'h000010d4);

        $display("\n%s (%0d failures)", errors == 0 ? "ALL TESTS PASSED" : "TESTS FAILED", errors);
        $finish;
    end

endmodule
