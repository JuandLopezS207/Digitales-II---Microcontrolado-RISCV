module registerfile(
    input clk,
    input wr_en,
    input [4:0] wr_index,
    input [31:0] wr_data,
    input [4:0] rd_index1,
    input [4:0] rd_index2,
    output [31:0] rd_data1,
    output [31:0] rd_data2
);

    // Memoria de 32 posiciones de 32 bits
    reg [31:0] mem [0:31];

    // Lógica de lectura combinacional (dual-port)
    // El registro x0 (dirección 0) siempre se lee cero
    assign rd_data1 = (rd_index1 == 5'b00000) ? 32'd0 : mem[rd_index1];
    assign rd_data2 = (rd_index2 == 5'b00000) ? 32'd0 : mem[rd_index2];

    // Lógica de escritura secuencial / sincrónica
    always @(posedge clk) begin
        // Si la escritura está habilitada y no se intenta escribir en x0
        if (wr_en && (wr_index != 5'b00000)) begin
            mem[wr_index] <= wr_data;
        end
    end

endmodule