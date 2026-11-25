module regfile(
    input  logic clk, we,
    input  logic [4:0] rs1_addr, rs2_addr, rd_addr,
    input  logic [31:0] rd_data,
    output logic [31:0] rs1_data, rs2_data      // combinational read
);
// writes on posedge when we && rd_addr != 0; x0 always reads 0
    logic [31:0] regs [32];

    always_ff @(posedge clk)
        if (we && rd_addr != 5'd0) regs[rd_addr] <= rd_data;

    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : regs[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : regs[rs2_addr];
endmodule
