`include "memory.sv"
`include "cpu.sv"
`include "control_unit.sv"
`include "immgen.sv"
`include "regfile.sv"
`include "alu.sv"
`include "branch_unit.sv"

module top (
    input  logic clk,
    input  logic SW,          // active-low button
    output logic LED, RGB_R, RGB_G, RGB_B
);
    logic [31:0] imem_address, imem_data_out;
    logic [31:0] dmem_address, dmem_data_in, dmem_data_out;
    logic        dmem_wren;
    logic [2:0]  mem_funct3;
    logic        led, red, green, blue, mem_reset_unused;

    memory #(
        .IMEM_INIT_FILE_PREFIX("program/prog"),
        .DMEM_INIT_FILE_PREFIX("")
    ) mem (
        .clk(clk), .funct3(mem_funct3), .dmem_wren(dmem_wren),
        .dmem_address(dmem_address), .dmem_data_in(dmem_data_in),
        .imem_address(imem_address), .imem_data_out(imem_data_out),
        .dmem_data_out(dmem_data_out), .reset(mem_reset_unused),
        .led(led), .red(red), .green(green), .blue(blue)
    );

    // Power-on reset: iCE40 block RAM reads are not valid for a few microseconds
    // after configuration, so hold the CPU in reset for ~2.7 ms (2^15 cycles at 12 MHz).
    logic [15:0] por_count = 0;
    logic        cpu_reset;
    always_ff @(posedge clk)
        if (!por_count[15]) por_count <= por_count + 1;
    assign cpu_reset = ~por_count[15];

    cpu core (
        .clk(clk), .reset(cpu_reset),
        .imem_address(imem_address), .imem_data_out(imem_data_out),
        .dmem_address(dmem_address), .dmem_data_in(dmem_data_in),
        .dmem_wren(dmem_wren), .mem_funct3(mem_funct3),
        .dmem_data_out(dmem_data_out)
    );

    // LEDs on the board are active low
    assign LED   = ~led;
    assign RGB_R = ~red;
    assign RGB_G = ~green;
    assign RGB_B = ~blue;
endmodule
