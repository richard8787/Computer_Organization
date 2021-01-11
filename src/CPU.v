// Please include verilog file if you write module in other file
`include "Decoder.v";
module CPU(
    input             clk,
    input             rst,
    input      [31:0] data_out,
    input      [31:0] instr_out,
    output reg        instr_read,
    output reg        data_read,
    output reg [31:0] instr_addr,
    output reg [31:0] data_addr,
    output reg [3:0]  data_write,
    output reg [31:0] data_in
);

reg [31:0] pc;		
reg [31:0] register_file [31:0];
reg [31:0] rs1;
reg [31:0] rs2;
reg [4:0] rd;
reg [2:0] state;

wire [6:0] opcode;
wire [2:0] funct3;
wire [6:0] funct7;
wire [31:0] imm;
Decoder s(
	.instr_out(instr_out),
	.opcode(opcode),
	.funct3(funct3),
	.funct7(funct7),
	.imm(imm)
);

initial begin
    pc = 32'd0;
	data_read = 1'b0;
	data_write = 4'd0;
	data_addr = 32'd0;
	data_in = 32'd0;
	instr_read = 1'b0;
    instr_addr = 32'd0;
	register_file[0]=32'd0;
    state = 3'd0;
end

always@(posedge clk or posedge rst) begin
if(rst) begin //if rst to do zero
	pc = 32'd0;
	data_read = 1'b0;
	data_write = 4'd0;
	data_addr = 32'd0;
	data_in = 32'd0;
	instr_read = 1'b0;
    instr_addr = 32'd0;
	register_file[0]=32'd0;
	state = 3'd0;
end
case (state)
     3'd0: begin
		instr_addr = pc;
		instr_read = 1'b1;
		register_file[0] = 32'd0;
		state = 3'd1;
	end
	3'd1: begin //do nothing(for waiting instr_out)
		state = 3'd2;
	end   
    3'd2: begin
		pc = pc + 4;
		rs1 = register_file[instr_out[19:15]];
		rs2 = register_file[instr_out[24:20]];
		rd = instr_out[11:7];
		data_read = 1'b0;
		data_write = 4'd0;	
		
		case(opcode)
			7'b0110011: begin
				case(funct3)
					3'b000: begin
						case(funct7)
							7'b0000000: begin //add
								register_file[rd] = $signed(rs1) + $signed(rs2); 
							end
							7'b0100000: begin //sub
							register_file[rd] = $signed(rs1) - $signed(rs2);
							end
						endcase
					end
					3'b001: begin //sll
						register_file[rd] = rs1 << rs2[4:0];
					end
					3'b010: begin //slt
						register_file[rd] = $signed(rs1) < $signed(rs2) ? 32'd1 : 32'd0;
					end
					3'b011: begin //sltu
						register_file[rd] = rs1 < rs2 ? 32'd1 : 32'd0;
					end
					3'b100: begin //xor
						register_file[rd] = rs1 ^ rs2;
					end
					3'b101: begin
						case(funct7)
							7'b0000000: begin //srl
								register_file[rd] = rs1 >> rs2[4:0];
							end
							7'b0100000: begin //sra
								register_file[rd] = $signed(rs1) >>> rs2[4:0];
							end
						endcase
					end
					3'b110: begin //or
						register_file[rd] = rs1 | rs2;
					end
					3'b111: begin //and
						register_file[rd] = rs1 & rs2;
					end
				endcase
			end

			7'b0000011: begin //load (wait the data_out then do)
				data_addr = $signed(rs1) + $signed(imm);
				data_read = 1'b1;
			end

			7'b0010011: begin
				case(funct3)
					3'b000: begin //addi
						register_file[rd] = $signed(rs1) + $signed(imm);
					end
					3'b010: begin //slti
						register_file[rd] = $signed(rs1) < $signed(imm) ? 32'd1 : 32'd0;
					end
					3'b011: begin //sltiu
						register_file[rd] = rs1 < imm ? 32'd1 : 32'd0;
					end
					3'b100: begin //xori
						register_file[rd] = rs1 ^ imm;
					end
					3'b110: begin //ori
						register_file[rd] = rs1 | imm;
					end
					3'b111: begin //andi
						register_file[rd] = rs1 & imm;
					end
					3'b001: begin //slli
						register_file[rd] = rs1 << instr_out[24:20];
					end
					3'b101: begin 
						case(funct7)
							7'b0000000: begin //srli
								register_file[rd] = rs1 >> instr_out[24:20];
							end
							7'b0100000: begin //srai
								register_file[rd] = $signed(rs1) >>> instr_out[24:20];
							end
						endcase
					end
				endcase
			end

			7'b1100111: begin //jalr
				register_file[rd] = pc;
				pc = $signed(imm) + $signed(rs1);
			end

			7'b0100011: begin //store
				data_addr = $signed(rs1) + $signed(imm);
				case(data_addr[1:0]) //check site
					2'b00: begin //if %4==0
						data_in = rs2;
						case(funct3)
							3'b010:begin
								data_write = 4'b1111; //sw
							end
							3'b000:begin
								data_write = 4'b0001; //sb
							end
							3'b001:begin
								data_write = 4'b0011; //sh
							end
						endcase
					end
					2'b01: begin //if %4==1
						data_in = {rs2[23:0],8'd0};
						case(funct3)
							3'b010:begin
								data_write = 4'b1110; //sw
							end
							3'b000:begin
								data_write = 4'b0010; //sb
							end
							3'b001:begin
								data_write = 4'b0110; //sh
							end
						endcase
					end
					2'b10: begin //if %4==2
						data_in = {rs2[15:0],16'd0};
						case(funct3)
							3'b010:begin
								data_write = 4'b1100; //sw
							end
							3'b000:begin
								data_write = 4'b0100; //sb
							end
							3'b001:begin
								data_write = 4'b1100; //sh
							end
						endcase
					end
					2'b11: begin //if %4==3
						data_in = {rs2[7:0],24'd0};
						case(funct3)
							3'b010:begin
								data_write = 4'b1000; //sw
							end
							3'b000:begin
								data_write = 4'b1000; //sb
							end
							3'b001:begin
								data_write = 4'b1000; //sh
							end
						endcase
					end
				endcase
			end

			7'b1100011: begin
				case(funct3)
					3'b000: begin //beq
						pc = rs1 == rs2 ? instr_addr + $signed(imm) : pc;
					end
					3'b001: begin //bne
						pc = rs1 != rs2 ? instr_addr + $signed(imm) : pc;
					end
					3'b100: begin //blt
						pc = $signed(rs1) < $signed(rs2) ? instr_addr + $signed(imm) : pc;
					end
					3'b101: begin //bge
						pc = $signed(rs1) >= $signed(rs2) ? instr_addr + $signed(imm) : pc;
					end
					3'b110: begin //bltu
						pc = rs1 < rs2 ? instr_addr + $signed(imm) : pc;
					end
					3'b111: begin //bgeu
						pc = rs1 >= rs2 ? instr_addr + $signed(imm) : pc;
					end
				endcase
			end
			
			7'b0010111: begin //auipc
				register_file[rd] = $signed(instr_addr)  + $signed(imm);
			end

			7'b0110111: begin //lui
				register_file[rd] = imm;
			end

			7'b1101111: begin //jal
				register_file[rd] = pc;
				pc = $signed(instr_addr) + $signed(imm);
			end
		endcase

		if(data_read) begin //load
			state = 3'd3;
		end
		else begin
			state = 3'd0; //the others
		end
	end
    3'd3: begin //do nothing(for waiting data_out)
		data_read = 1'b0;
		state = 3'd4;
	end
    3'd4: begin //load
		case(funct3)
			3'b010: begin //lw
				register_file[rd] = data_out;
			end
			3'b000: begin //lb
				register_file[rd] = {{24{data_out[7]}},data_out[7:0]};
			end
			3'b001: begin //lh
				register_file[rd] = {{16{data_out[15]}},data_out[15:0]};
			end
			3'b100: begin //lbu
				register_file[rd] = {24'd0,data_out[7:0]};
			end
			3'b101: begin //lhu
				register_file[rd] = {16'd0,data_out[15:0]};
			end
		endcase
		state =3'd0;
	end
endcase
end
endmodule