module registerfile (
    input wire clk,
    input wire we,
    input wire [4:0] waddr,
    input wire [4:0] raddr1,
    input wire [4:0] raddr2,
    input wire [31:0] wdata,
    output wire [31:0] rdata1,
    output wire [31:0] rdata2
);
    reg [31:0] mem [0:31];

    // Inicialización a 0 de todos los registros para evitar x (rojo) en la simulación
    integer k;
    initial begin
        for (k = 0; k < 32; k = k + 1) begin
            mem[k] = 32'd0;
        end
    end

    // Escritura sincrónica (el registro x0 siempre se mantiene en 0)
    always @(posedge clk) begin
        if (we && (waddr != 5'd0)) begin
            mem[waddr] <= wdata;
        end
    end

    // Lectura combinacional
    assign rdata1 = (raddr1 == 5'd0) ? 32'd0 : mem[raddr1];
    assign rdata2 = (raddr2 == 5'd0) ? 32'd0 : mem[raddr2];

endmodule