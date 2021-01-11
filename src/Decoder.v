module Decoder(
	input [31:0] instr_out,
	output reg [6:0] opcode,
	output reg [2:0] funct3,
	output reg [6:0] funct7,
	output reg [31:0] imm
);

always @ (instr_out) begin
	opcode = instr_out[6:0];
	funct3 = instr_out[14:12];
	funct7 = instr_out[31:25];
	case(opcode)
		7'b0000011: begin //lw lb lh lbu lhu
			imm = $signed(instr_out) >>> 20;
		end
		7'b0010011: begin //addi slti sltiu xori ori andi slli srli srai
			imm = $signed(instr_out) >>> 20;	
		end 
		7'b1100111: begin //jalr
			imm = $signed(instr_out) >>> 20;	
		end  
		7'b0100011: begin //sw sb sh
			imm = $signed({instr_out[31:25], instr_out[11:7], 20'd0}) >>> 20;
		end
		7'b1100011: begin //beq bne blt bge bltu bgeu
			imm = $signed({instr_out[31], instr_out[7], instr_out[30:25], instr_out[11:8], 20'd0}) >>> 19;
		end
		7'b0010111: begin //auipc
			imm = {instr_out[31:12], 12'd0};
		end
		7'b0110111: begin //lui
			imm = {instr_out[31:12], 12'd0};
		end
		7'b1101111: begin //jal
			imm = $signed({instr_out[31], instr_out[19:12], instr_out[20], instr_out[30:21], 12'd0}) >>> 11;
		end
		default: begin //add sub sll slt sltu xor srl sra or and
			imm = 7'b0000000;
		end
	endcase
end

endmodule