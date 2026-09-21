module riscv (
    input clk,          // Reloj del procesador
    input rst,          // Reset del procesador
    input [31:0] instr  // Instrucción de entrada
);

    reg [31:0] IR; // Registro de instrucción
    always @(posedge clk) begin
        IR <= instr;
    end

    // Señales del registro de instrucción

    wire [6:0] funct7;
    wire [4:0] rs2;
    wire [4:0] rs1;
    wire [2:0] funct3;
    wire [4:0] rd;
    wire [6:0] opcode;

    // Campos de registro 

    assign funct7 = IR[31:25];
    assign rs2    = IR[24:20];
    assign rs1    = IR[19:15];
    assign funct3 = IR[14:12];
    assign rd     = IR[11:7];
    assign opcode = IR[6:0];

    // tipos de instruccion
    wire is_valid;
    wire is_r_instr;
    wire is_i_instr;
    wire is_s_instr;
    wire is_b_instr;
    wire is_u_instr;
    wire is_j_instr;

    // Verificación 

    assign is_valid   = (opcode[1:0] == 2'b11); 
    
    // Identificación del tipo

    assign is_r_instr = (opcode[6:2] == 5'b01100);
    assign is_i_instr = (opcode[6:2] == 5'b00000) | (opcode[6:2] == 5'b00100) | (opcode[6:2] == 5'b11001);
    assign is_s_instr = (opcode[6:2] == 5'b01000);
    assign is_b_instr = (opcode[6:2] == 5'b11000);
    assign is_u_instr = (opcode[6:2] == 5'b00101) | (opcode[6:2] == 5'b01101);
    assign is_j_instr = (opcode[6:2] == 5'b11011);

    // EXTRACCIÓN DEL VALOR INMEDIATO Y VALIDEZ
  
    wire [31:0] imm;
    wire imm_valid;

    // Valor

    assign imm[31:0] = 
        is_i_instr ? { {21{IR[31]}}, IR[30:20] } :
        is_s_instr ? { {21{IR[31]}}, IR[30:25], IR[11:7] } :
        is_b_instr ? { {20{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0 } :
        is_u_instr ? { IR[31:12], 12'b0 } :
        is_j_instr ? { {12{IR[31]}}, IR[19:12], IR[20], IR[30:21], 1'b0 } :
        32'b0;

    // El campo valido

    assign imm_valid = is_i_instr | is_s_instr | is_b_instr | is_u_instr | is_j_instr;


    // Salidas del register file
    wire [31:0] src1_value;
    wire [31:0] src2_value;

    // Operandos de entrada a la ALU
    wire [31:0] alu_a;
    wire [31:0] alu_b;

    // Salida de la ALU
    wire [31:0] alu_out;

    // Señales de control de la Unidad de Control (CU)
    wire wr_en;
    wire [10:0] dec_bits;
    wire [9:0]  dec_bits2;
    wire is_add, is_sub, is_and, is_or, is_xor;
    wire is_addi, is_xori, is_ori, is_andi;

    // CABLEADO 
    assign alu_a = src1_value; 
    
    // Reutilización de la ALU

    assign alu_b = imm_valid ? imm[31:0] : src2_value;

    // CONTROL UNIT (CU) - DECODIFICACIÓN DE OPERACIONES
    // Decodificador 

    assign dec_bits = {funct7[5], funct3, opcode};
    
    // Decodificador para instrucciones tipo I 
    assign dec_bits2 = {funct3, opcode};

    // Identificación de instrucciones tipo R 

    assign is_add = (dec_bits == 11'b0_000_0110011);
    assign is_sub = (dec_bits == 11'b1_000_0110011);
    assign is_xor = (dec_bits == 11'b0_100_0110011);
    assign is_or  = (dec_bits == 11'b0_110_0110011);
    assign is_and = (dec_bits == 11'b0_111_0110011);

    // Identificación de instrucciones tipo I 

    assign is_addi = (dec_bits2 == 10'b000_0010011);
    assign is_xori = (dec_bits2 == 10'b100_0010011);
    assign is_ori  = (dec_bits2 == 10'b110_0010011);
    assign is_andi = (dec_bits2 == 10'b111_0010011);

    // Habilitador de escritura 

    assign wr_en = (is_r_instr | is_i_instr | is_u_instr | is_j_instr) & is_valid;

    // Código de operación enviado a la ALU combinando ambas variantes (R e I)

    wire [2:0] alu_op;
    assign alu_op = (is_add | is_addi) ? 3'b000 :
                    (is_sub)           ? 3'b001 :
                    (is_and | is_andi) ? 3'b010 :
                    (is_or  | is_ori)  ? 3'b011 :
                    (is_xor | is_xori) ? 3'b100 : 3'b000;

    registerfile rv_rf (
        .clk(clk),
        .wr_en(wr_en),
        .wr_index(rd),
        .wr_data(alu_out),
        .rd_index1(rs1),
        .rd_data1(src1_value),
        .rd_index2(rs2),
        .rd_data2(src2_value)
    );

    // Instanciación de la ALU[cite: 6]
    alu rv_alu (
        .A(alu_a),
        .B(alu_b),
        .ALU_out(alu_out),
        .op(alu_op)
    );

endmodule