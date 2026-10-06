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

    reg [31:0] pc;
    assign iaddr = pc;

    reg state_fetch, state_decode, state_execute;

    always @(negedge clk) begin
        if (rst) begin
            state_fetch   <= 1'b1;
            state_decode  <= 1'b0;
            state_execute <= 1'b0;
        end else begin
            state_fetch   <= state_execute;
            state_decode  <= state_fetch;
            state_execute <= state_decode;
        end
    end

    reg [31:0] IR;
    always @(posedge clk) begin
        if (rst) IR <= 32'd0;
        else if (state_fetch) IR <= instr;
    end

    wire [6:0] opcode = IR[6:0];
    wire [4:0] rd     = IR[11:7];
    wire [2:0] funct3 = IR[14:12];
    wire [4:0] rs1    = IR[19:15];
    wire [4:0] rs2    = IR[24:20];
    wire [6:0] funct7 = IR[31:25];


    // PASO 1: Decodificación de instrucciones
    wire is_r_instr = (opcode == 7'b0110011);
    wire is_i_instr = (opcode == 7'b0010011);
    wire is_b_instr = (opcode == 7'b1100011);
    wire is_j_instr = (opcode == 7'b1101111);
    
    // Nuevas instrucciones tipo U
    wire is_lui   = (opcode == 7'b0110111);
    wire is_auipc = (opcode == 7'b0010111);
    wire is_u_instr = is_lui | is_auipc;

    // Bit 5 de funct7 para diferenciar instrucciones (ej. SRL vs SRA, ADD vs SUB)
    wire funct7_5 = IR[30]; 
    

    wire is_beq  = is_b_instr & (funct3 == 3'b000);
    wire is_bne  = is_b_instr & (funct3 == 3'b001);
    wire is_blt  = is_b_instr & (funct3 == 3'b100);
    wire is_bge  = is_b_instr & (funct3 == 3'b101);
    wire is_bltu = is_b_instr & (funct3 == 3'b110);
    wire is_bgeu = is_b_instr & (funct3 == 3'b111);

    // Formatos de Inmediatos
    wire [31:0] i_imm = {{20{IR[31]}}, IR[31:20]};
    wire [31:0] b_imm = {{20{IR[31]}}, IR[7], IR[30:25], IR[11:8], 1'b0};
    wire [31:0] j_imm = {{12{IR[31]}}, IR[19:12], IR[20], IR[30:21], 1'b0};
    
    // Inmediato tipo U: Desplazado 12 bits a la izquierda como dicta la guía
    wire [31:0] u_imm = {IR[31:12], 12'b0};

    // Habilitar escritura en registro (ahora incluye is_u_instr)
    wire wr_en = (is_r_instr | is_i_instr | is_j_instr | is_u_instr) & (rd != 5'd0);
    wire [31:0] src1_value, src2_value;
    wire [31:0] alu_out;
    wire [31:0] wdata = is_j_instr ? (pc + 32'd4) : alu_out;

    registerfile rf (
        .clk(clk),
        .we(wr_en & state_execute),
        .waddr(rd),
        .raddr1(rs1),
        .raddr2(rs2),
        .wdata(wdata),
        .rdata1(src1_value),
        .rdata2(src2_value)
    );

   
    // PASO 2: Generar la señal 'op' de la ALU

    // El bit más significativo del op (op[3]) depende de funct7_5.
    // Solo aplica para tipo R y para la instrucción SRAI (tipo I, funct3=101).
    wire use_funct7_5 = (is_r_instr) | (is_i_instr & (funct3 == 3'b101));
    wire op_bit3 = use_funct7_5 & funct7_5;
    
    // Si es R o I, pasamos {op_bit3, funct3}. Si es LUI/AUIPC pasa 0000 (Suma).
    wire [3:0] alu_op = (is_r_instr | is_i_instr) ? {op_bit3, funct3} : 4'b0000;
  


    // PASO 4 (Parte 2): Multiplexores A y B de la ALU

    wire [31:0] alu_a;
    wire [31:0] alu_b;

    // Si es LUI, A=0. Si es AUIPC, A=PC. De lo contrario, A=src1_value.
    assign alu_a = is_lui ? 32'd0 : (is_auipc ? pc : src1_value);

    // Si es U-Type usa u_imm. Si es I-Type usa i_imm. De lo contrario usa src2_value.
    wire [31:0] imm = is_u_instr ? u_imm : i_imm;
    assign alu_b = (is_i_instr | is_u_instr) ? imm : src2_value;

    alu cpu_alu (
        .a(alu_a),
        .b(alu_b),
        .op(alu_op),
        .out(alu_out)
    );
    

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

    always @(posedge clk) begin
        if (rst) pc <= 32'd0;
        else if (state_execute) pc <= next_pc;
    end

    assign daddr     = 32'd0;
    assign ddata_out = 32'd0;
    assign dwr_en    = 1'b0;
    assign drd_en    = 1'b0;

endmodule