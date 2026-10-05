module rom4096x32 (
    input wire [11:0] addr, // Dirección de 12 bits
    output reg [31:0] data  // Instrucción de 32 bits
);
    always @(*) begin
        case (addr)
            // Programa while
            12'd0: data = 32'h000001B3; // add x3, x0, x0   (x3 = 0)
            12'd1: data = 32'h000002B3; // add x5, x0, x0   (x5 = 0)
            12'd2: data = 32'h00500313; // addi x6, x0, 5   (x6 = 5)
            12'd3: data = 32'h005181B3; // do1: add x3, x3, x5 (x3 = x3 + x5) 
            12'd4: data = 32'h00128293; // addi x5, x5, 1   (x5++)
            12'd5: data = 32'hFE62CCE3; // blt x5, x6, do1  (salta a do1 si x5 < x6)
            12'd6: data = 32'h00018633; // finwhile: add x12, x3, x0 (x12 = x3)
            default: data = 32'h00000013; // nop (addi x0, x0, 0)
        endcase
    end
endmodule