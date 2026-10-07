module riscv (
    input wire clk,
    input wire rst,
    input wire [31:0] instr,
    output wire [31:0] iaddr,
    output wire [31:0] daddr,
    input wire [31:0] ddata_in,
    output wire [31:0] ddata_out,
    output wire dwr_en,
    output wire drd_en
);


    // 1. Contador de Programa (PC) y Control de Estados (4 ciclos de reloj)
  
    reg [31:0] pc;
    assign iaddr = pc;

    // Contador en anillo para la máquina de estados de 4 pasos (Fetch, Decode, Execute, Execute2)
    reg state_fetch, state_decode, state_execute, state_execute2;

    always @(negedge clk) begin
        if (rst) begin
            state_fetch    <= 1'b1;
            state_decode   <= 1'b0;
            state_execute  <= 1'b0;
            state_execute2 <= 1'b0;

        end else begin
            state_fetch    <= state_execute2;
            state_decode   <= state_fetch;
            state_execute  <= state_decode;
            state_execute2 <= state_execute;
        end
    end

    // Registro de Instrucción (IR)
    reg [31:0] IR;
    always @(posedge clk) begin
        if (rst) IR <= 32'd0;
        else if (state_fetch) IR <= instr;
    end

    // ------------------------------------------------------------------------
    // 2. Decodificación de Campos e Instrucciones (Requeridas por la Guía)
    // ------------------------------------------------------------------------
    wire [6:0] opcode = IR[6:0];
    wire [4:0] rd     = IR[11:7];
    wire [2:0] funct3 = IR[14:12];
    wire [4:0] rs1    = IR[19:15];
    wire [4:0] rs2    = IR[24:20];
    wire [6:0] funct7 = IR[31:25];
    wire funct7_5     = IR[30]; // Bit 30 para diferenciar ADD/SUB, SRL/SRA

    // Decodificación por familias de instrucción
    wire is_r_instr = (opcode == 7'b0110011);
    wire is_i_instr = (opcode == 7'b0010011);
    wire is_b_instr = (opcode == 7'b1100011);
    wire is_j_instr = (opcode == 7'b1101111);
    wire is_lui     = (opcode == 7'b0110111);
    wire is_auipc   = (opcode == 7'b0010111);
    wire is_u_instr = is_lui | is_auipc;

    // Señales específicas requeridas para GTKWave (Figura 17)
    wire is_add     = is_r_instr & (funct3 == 3'b000) & (~funct7_5); // Instrucción ADD
    wire is_addi    = is_i_instr & (funct3 == 3'b000);               // Instrucción ADDI
    wire is_load    = (opcode == 7'b0000011);                        // LB, LH, LW, LBU, LHU
    wire is_s_instr = (opcode == 7'b0100011);                        // SB, SH, SW

    // Decodificación de Saltos Condicionales (Branches)
    wire is_beq  = is_b_instr & (funct3 == 3'b000);
    wire is_bne  = is_b_instr & (funct3 == 3'b001);
    wire is_blt  = is_b_instr & (funct3 == 3'b100);
    wire is_bge  = is_b_instr & (funct3 == 3'b101);
    wire is_bltu = is_b_instr & (funct3 == 3'b110);
    wire is_bgeu = is_b_instr & (funct3 == 3'b111);

    // ------------------------------------------------------------------------
    // 3. Formatos de Inmediatos
    // ------------------------------------------------------------------------
    wire [31:0] i_imm = {{20{IR[31]}}, IR[31:20]};
    wire [31:0] s_imm = {{20{IR[31]}}, IR[31:25], IR[11:7]};
    wire [31:0] b_imm = {{20{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0};
    wire [31:0] u_imm = {IR[31:12], 12'b0};
    wire [31:0] j_imm = {{12{IR[31]}}, IR[19:12], IR[20], IR[30:21], 1'b0};

    // ------------------------------------------------------------------------
    // 4. Banco de Registros (Register File) y MUX de Escritura
    // ------------------------------------------------------------------------
    // Permite escribir si es Tipo R, I, J, U o Carga (LOAD), excluyendo x0
    wire wr_en = (is_r_instr | is_i_instr | is_j_instr | is_u_instr | is_load) & (rd != 5'd0);
    wire [31:0] src1_value, src2_value;
    wire [31:0] alu_out;

    // MUX de selección de datos a escribir en el Register File (Figura 16)
    wire [31:0] wdata = is_j_instr ? (pc + 32'd4) : 
                        (is_load   ? ddata_in : alu_out);

    registerfile rf (
        .clk(clk),
        .we(wr_en & state_execute2), // La escritura en el RF ocurre en state_execute2
        .waddr(rd),
        .raddr1(rs1),
        .raddr2(rs2),
        .wdata(wdata),
        .rdata1(src1_value),
        .rdata2(src2_value)
    );

    // ------------------------------------------------------------------------
    // 5. Control y Multiplexores de la ALU
    // ------------------------------------------------------------------------
    wire use_funct7_5 = (is_r_instr) | (is_i_instr & (funct3 == 3'b101));
    wire op_bit3 = use_funct7_5 & funct7_5;
    
    // Para R e I se toma {op_bit3, funct3}. Para LOAD, STORE, LUI, AUIPC se fuerza a 0000 (Suma)
    wire [3:0] alu_op = (is_r_instr | is_i_instr) ? {op_bit3, funct3} : 4'b0000;

    // MUX Operando A de la ALU
    wire [31:0] alu_a;
    assign alu_a = is_lui ? 32'd0 : (is_auipc ? pc : src1_value);

    // MUX Operando B de la ALU
    wire [31:0] imm = is_u_instr ? u_imm :
                      is_s_instr ? s_imm : i_imm; // i_imm sirve tanto para Tipo-I como para LOAD

    wire [31:0] alu_b;
    assign alu_b = (is_i_instr | is_load | is_s_instr | is_u_instr) ? imm : src2_value;

    alu cpu_alu (
        .a(alu_a),
        .b(alu_b),
        .op(alu_op),
        .out(alu_out)
    );

    // ------------------------------------------------------------------------
    // 6. Interfaz con la Memoria de Datos (DMEM)
    // ------------------------------------------------------------------------
    assign daddr     = alu_out;     // Dirección calculada por la ALU (rs1 + imm)
    assign ddata_out = src2_value;  // Dato a almacenar proviene de rs2

    // Control de lectura y escritura condicionado a los ciclos de ejecución (Execute / Execute2)
    assign dwr_en    = is_s_instr & (state_execute | state_execute2);
    assign drd_en    = is_load    & (state_execute | state_execute2);

    // ------------------------------------------------------------------------
    // 7. Lógica de Saltos y Actualización del PC
    // ------------------------------------------------------------------------
    wire cond_beq  = (src1_value == src2_value);
    wire cond_bne  = (src1_value != src2_value);
    wire cond_blt  = (src1_value < src2_value) ^ (src1_value[31] != src2_value[31]);
    wire cond_bge  = (src1_value >= src2_value) ^ (src1_value[31] != src2_value[31]);
    wire cond_bltu = (src1_value < src2_value);
    wire cond_bgeu = (src1_value >= src2_value);

    wire taken_br = (is_beq  & cond_beq)  |
                    (is_bne  & cond_bne)  |
                    (is_blt  & cond_blt)  |
                    (is_bge  & cond_bge)  |
                    (is_bltu & cond_bltu) |
                    (is_bgeu & cond_bgeu) |
                    is_j_instr;

    wire [31:0] br_tgt_pc = pc + (is_j_instr ? j_imm : b_imm);
    wire [31:0] next_pc   = taken_br ? br_tgt_pc : (pc + 32'd4);

    // Actualización del PC en el flanco de subida al finalizar el ciclo de ejecución
    always @(posedge clk) begin
        if (rst) pc <= 32'd0;
        else if (state_execute2) pc <= next_pc;
    end

endmodule