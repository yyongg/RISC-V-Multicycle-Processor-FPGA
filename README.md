# Control Unit
## Instructions
| Format | Functional Group | 7-Bit Binary Opcode | Hex | Example Instructions |
|--------|------------------|---------------------|-----|----------------------|
| R-Type | Register-to-register ALU math | `0110011` | `0x33` | `add`, `sub`, `sll`, `xor`, `and` |
| I-Type | Immediate ALU math | `0010011` | `0x13` | `addi`, `slti`, `xori`, `ori`, `andi` |
| I-Type | Memory loads | `0000011` | `0x03` | `lb`, `lh`, `lw`, `lbu`, `lhu` |
| I-Type | Indirect jump | `1100111` | `0x67` | `jalr` |
| I-Type | System & CSR instructions | `1110011` | `0x73` | `ecall`, `ebreak`, `csrrw` |
| I-Type | Memory ordering (Fence) | `0001111` | `0x0F` | `fence`, `fence.i` |
| S-Type | Memory stores | `0100011` | `0x23` | `sb`, `sh`, `sw` |
| B-Type | Conditional branches | `1100011` | `0x63` | `beq`, `bne`, `blt`, `bge` |
| U-Type | Load upper immediate | `0110111` | `0x37` | `lui` |
| U-Type | Add upper immediate to PC | `0010111` | `0x17` | `auipc` |
| J-Type | Unconditional jump & link | `1101111` | `0x6F` | `jal` |


## Decoder
| Instruction | opcode | reg_write | mem_write | alu_src_a | alu_src_b | alu_ctrl | result_src | other |
|-------------|--------|-----------|-----------|-----------|-----------|----------|------------|-------|
| R-type | `0110011` | 1 | 0 | rs1 | rs2 | `{f7[5], f3}` | ALU | |
| I-type ALU | `0010011` | 1 | 0 | rs1 | imm | `{f3==101 ? f7[5] : 0, f3}` | ALU | |
| Load | `0000011` | 1 | 0 | rs1 | imm | ADD | MEM | `mem_read` |
| Store | `0100011` | 0 | 1 | rs1 | imm | ADD | — | |
| Branch | `1100011` | 0 | 0 | rs1 | rs2 | SUB | — | `branch` |
| JAL | `1101111` | 1 | 0 | — | — | — | PC+4 | `jump`, target = PC+imm |
| JALR | `1100111` | 1 | 0 | rs1 | imm | ADD | PC+4 | `jump`, target = `ALU & ~1` |
| LUI | `0110111` | 1 | 0 | 0 | imm | ADD | ALU | |
| AUIPC | `0010111` | 1 | 0 | PC | imm | ADD | ALU | |
| FENCE / ECALL | `0001111` / `1110011` | 0 | 0 | | | | | treat as NOP |
| anything else | | 0 | 0 | | | | | default: nothing written |

# Immediate Generator
## Reconstruction of Immediate from Instruction
| Format | Instruction Bits Used | Output Construction (32-bit) | Purpose |
|--------|----------------------|-------------------------------|---------|
| I-type | `inst[31:20]` | `{20{inst[31]}, inst[31:20]}` | ALU immediates, loads (LW), JALR |
| S-type | `inst[31:25]`, `inst[11:7]` | `{20{inst[31]}, inst[31:25], inst[11:7]}` | Store offsets (SW, SB) |
| B-type | `inst[31]`, `inst[7]`, `inst[30:25]`, `inst[11:8]` | `{19{inst[31]}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0}` | Conditional branch offsets (BEQ, BNE) |
| U-type | `inst[31:12]` | `{inst[31:12], 12'b0}` | Upper 20-bit constants (LUI, AUIPC) |
| J-type | `inst[31]`, `inst[19:12]`, `inst[20]`, `inst[30:21]` | `{11{inst[31]}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0}` | Unconditional jump offsets (JAL) |
