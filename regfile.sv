module regfile(
    input  logic clk, we,
    input  logic [4:0] rs1_addr, rs2_addr, rd_addr,
    input  logic [31:0] rd_data,
    output logic [31:0] rs1_data, rs2_data      // combinational read
);
endmodule
