module alu (
    input [31:0] A,
    input [31:0] B,
    input [2:0] op,
    output [31:0] ALU_out
);

    assign ALU_out = 
        (op == 3'b000) ? A + B :  // Suma (add)
        (op == 3'b001) ? A - B :  // Resta (sub)
        (op == 3'b010) ? A & B :  // AND (and)
        (op == 3'b011) ? A | B :  // OR (or)
        (op == 3'b100) ? A ^ B :  // XOR (xor)
                         32'd0;

endmodule