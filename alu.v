module alu (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [2:0] op,
    output reg [31:0] out
);
    always @(*) begin
        case (op)
            3'b000: out = a + b;       // Suma
            3'b001: out = a - b;       // Resta
            3'b010: out = a & b;       // AND
            3'b011: out = a | b;       // OR
            3'b100: out = a ^ b;       // XOR
            3'b101: out = a << b[4:0]; // Desplazamiento Izquierda
            3'b110: out = a >> b[4:0]; // Desplazamiento Derecha
            default: out = 32'd0;
        endcase
    end
endmodule