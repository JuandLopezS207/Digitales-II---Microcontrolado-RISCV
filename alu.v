module alu (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [3:0] op, // Ampliado a 4 bits para soportar todas las operaciones
    output reg [31:0] out
);

  
    // PASO 3: Cálculos previos de la ALU

    wire [4:0]  shamt;
    wire [63:0] a_ext;
    wire [31:0] sltu_result;
    wire [31:0] slt_result;

    // Valor del shift
    assign shamt = b[4:0];

    // Extensión de signo de la entrada 'a' para 64 bits (útil para SRA)
    assign a_ext = { {32{a[31]}}, a };

    // Valor obtenido por set if less than unsigned (sltu)
    assign sltu_result = {31'b0, a < b};

    // Valor obtenido por set if less than (signed)
    assign slt_result = (a[31] == b[31]) ? sltu_result : {31'b0, a[31]};
   



    // PASO 4 (Parte 1): Ampliar el MUX de la ALU
  
    always @(*) begin
        case (op)
            4'b0000: out = a + b;           // ADD / ADDI / LUI / AUIPC (Suman)
            4'b1000: out = a - b;           // SUB
            4'b0001: out = a << shamt;      // SLL / SLLI
            4'b0010: out = slt_result;      // SLT / SLTI
            4'b0011: out = sltu_result;     // SLTU / SLTIU
            4'b0100: out = a ^ b;           // XOR / XORI
            4'b0101: out = a >> shamt;      // SRL / SRLI
            4'b1101: out = a_ext >> shamt;  // SRA / SRAI (Aritmético usa a_ext)
            4'b0110: out = a | b;           // OR / ORI
            4'b0111: out = a & b;           // AND / ANDI
            default: out = 32'd0;
        endcase
    end
    
endmodule