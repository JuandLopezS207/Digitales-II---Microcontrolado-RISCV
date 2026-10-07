module rom4096x32 (
    input wire clk,         // Añadida entrada de reloj para hacerla sincrónica
    input wire [11:0] addr, 
    output reg [31:0] data  
);
    // Memoria RAM/ROM de 4096 posiciones de 32 bits
    reg [31:0] mem [0:4095];

    // Inicialización cargando el archivo hex
    initial begin
        // Lee el archivo hexadecimal y lo carga en la memoria
        $readmemh("test_program.hex", mem);
    end

    // Lectura sincrónica (dependiente del reloj)
    always @(posedge clk) begin
        data <= mem[addr];
    end
endmodule