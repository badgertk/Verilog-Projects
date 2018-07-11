module PhysReg(
	input CLK,
	input RESET,
	
	input [31:0] Instr_PC_IN,
	input [5:0] Phys_RegisterA_IN,
	input [5:0] Phys_RegisterB_IN,
	input [31:0] Instr_IN, //is this necessary?
	input [31:0] Immediate_IN,
	input [5:0] Dest_Phys_Register_IN, //if this instruction doesn't write to the reg file, this value will be garbage.
	input [31:0] RegWriteData_IN,
	input RegWrite_IN, //is this metadata?
	input [5:0] ALU_Control_IN,
	input MemRead_IN,
	input MemWrite_IN,
	input [4:0] ShiftAmount_IN,
	input  	Jump_IN,
	input  	JumpRegister_IN,
	input  	ALUSrc_IN,
	input [5:0] ROB_index_IN,
	input [3:0] LSQ_index_IN,
	input EXE_STALL, 
	input IssueQ_STALL,
	
	output reg [31:0] Instr_PC_OUT,
	output reg [5:0] Phys_RegisterA_OUT,
	output reg [31:0] OperandA_OUT,
	output reg [5:0] Phys_RegisterB_OUT,
	output reg [31:0] OperandB_OUT,
	output reg [31:0] Instr_OUT,
	output reg [5:0] Dest_Phys_Register_OUT, //if this instruction doesn't write to the reg file, this value will be garbage.
	output reg [31:0] MemWriteData1_OUT,
	output reg RegWrite_OUT,
	output reg [5:0] ALU_Control_OUT,
	output reg MemRead_OUT,
	output reg MemWrite_OUT,
	output reg [4:0] ShiftAmount_OUT,
	output reg  	Jump_OUT,
	output reg  	JumpRegister_OUT,
	output reg [5:0] ROB_index_OUT,
	output reg [3:0] LSQ_index_OUT,
	output PhysReg_STALL_OUT, //to Issue Queue not to take anything out of issue queue
	
`ifdef HAS_FORWARDING
    //Bypass inputs for calculations that have completed EXE
    input [4:0]     BypassReg1_EXEID,
    input [31:0]    BypassData1_EXEID,
    input           BypassValid1_EXEID,
	
    //Bypass inputs for loads from memory (and previous-instruction EXE outputs)
    input [4:0]     BypassReg1_MEMID,
    input [31:0]    BypassData1_MEMID,
    input           BypassValid1_MEMID
`endif
	
);

wire [31:0]	OperandB;
wire [31:0] RegOperandA;
wire [31:0] RegOperandB;
assign OperandB = ALUSrc_IN?Immediate_IN: RegOperandB;
wire [31:0] RegData;
assign RegData = MemWrite_IN?RegOperandB:32'b0;
wire PhysReg_STALL;
assign PhysReg_STALL = EXE_STALL || IssueQ_STALL;

/* 	PhysRegFile #(
    .NUM_PHYS_REGS(64)
) */

PhysRegFile	ReadPhysReg ( //looks fine
		.CLK(CLK),
		.RESET(RESET),
		.RegA(Phys_RegisterA_IN),
		.RegB(Phys_RegisterB_IN),
		.RegC(0),
		.DataA(RegOperandA),
		.DataB(RegOperandB),
		.WriteReg(0),//?
		.WriteData(0),
		.RegWrite(0)
    );
	
	//check everything below this
`ifdef HAS_FORWARDING
RegValue3 RegAValue1 (
    .ReadRegister1(Phys_RegisterA_IN), 
    .RegisterData1(RegOperandA), 
    .WriteRegister1stPri1(BypassReg1_EXEID), 
    .WriteData1stPri1(BypassData1_EXEID),
	 .Valid1stPri1(BypassValid1_EXEID),
    .WriteRegister2ndPri1(BypassReg1_MEMID), 
    .WriteData2ndPri1(BypassData1_MEMID),
	 .Valid2ndPri1(BypassValid1_MEMID),
    .WriteRegister3rdPri1(Dest_Phys_Register_IN), 
    .WriteData3rdPri1(WriteData1_IN),
	 .Valid3rdPri1(RegWrite1_IN),
    .Output1(rsval1),
	 .comment(1'b0)
    );
RegValue3 RegBValue1 (
    .ReadRegister1(Phys_RegisterB_IN), 
    .RegisterData1(RegOperandB), 
    .WriteRegister1stPri1(BypassReg1_EXEID), 
    .WriteData1stPri1(BypassData1_EXEID),
     .Valid1stPri1(BypassValid1_EXEID),
    .WriteRegister2ndPri1(BypassReg1_MEMID), 
    .WriteData2ndPri1(BypassData1_MEMID),
     .Valid2ndPri1(BypassValid1_MEMID),
    .WriteRegister3rdPri1(Dest_Phys_Register_IN), 
    .WriteData3rdPri1(WriteData1_IN),
     .Valid3rdPri1(RegWrite1_IN),
    .Output1(rtval1),
	 .comment(1'b0)
    );
`else
assign rsval1 = rsRawVal1;
assign rtval1 = rtRawVal1;
`endif

	
`ifdef HAS_FORWARDING
RegValue3 RegWriteValue1 (
    .ReadRegister1(Dest_Phys_Register_IN), 
    .RegisterData1(RegWriteData_IN), 
    .WriteRegister1stPri1(BypassReg1_EXEID), 
    .WriteData1stPri1(BypassData1_EXEID),
	 .Valid1stPri1(BypassValid1_EXEID),
    .WriteRegister2ndPri1(BypassReg1_MEMID), 
    .WriteData2ndPri1(BypassData1_MEMID),
	 .Valid2ndPri1(BypassValid1_MEMID),
    .WriteRegister3rdPri1(Dest_Phys_Register_IN), 
    .WriteData3rdPri1(WriteData1_IN),
	 .Valid3rdPri1(RegWrite1_IN),
    .Output1(MemWriteData1),
	 .comment(1'b0)
    );
`else
    assign MemWriteData1 = WriteRegisterRawVal1;
`endif
//check everything above this	

always@(posedge CLK or negedge RESET) begin
	if (!RESET) begin
		Instr_PC_OUT <= 0;
		Phys_RegisterA_OUT <= 0;
		OperandA_OUT <= 0;
		Phys_RegisterB_OUT <= 0;
		OperandB_OUT <= 0;
		Instr_OUT <= 0;
		Dest_Phys_Register_OUT <= 0;
		RegWrite_OUT <= 0;
		ALU_Control_OUT <= 0;
		MemRead_OUT <= 0;
		MemWrite_OUT <= 0;
		ShiftAmount_OUT <= 0;
		Jump_OUT <= 0;
		JumpRegister_OUT <= 0;
		ROB_index_OUT <= 0;
		LSQ_index_OUT <= 0;
		PhysReg_STALL_OUT <= 0;
	
	end else if (CLK) begin
		if (ALUSrc_IN == 1) begin // this still needs more work
				Phys_RegisterB_OUT <= Phys_RegisterB_IN; //not useful, will take immediate value
				OperandB_OUT <= OperandB;
				Dest_Phys_Register_OUT <= Phys_RegisterB_IN; 
				MemWriteData1_OUT <= RegData;
		end else begin //
				Phys_RegisterB_OUT <= Phys_RegisterB_IN;
				OperandB_OUT <= OperandB;
				Dest_Phys_Register_OUT <= Dest_Phys_Register_IN; 
				MemWriteData1_OUT <= RegData;
		end
		Instr_PC_OUT <= Instr_PC_IN;
		Phys_RegisterA_OUT <= Phys_RegisterA_IN;
		OperandA_OUT <= RegOperandA;
		Instr_OUT <= Instr_IN;

		RegWrite_OUT <= RegWrite_IN;
		ALU_Control_OUT <= ALU_Control_IN;
		MemRead_OUT <= MemRead_IN;
		MemWrite_OUT <= MemWrite_IN;
		ShiftAmount_OUT <= ShiftAmount_IN;
		Jump_OUT <= Jump_IN;
		JumpRegister_OUT <= JumpRegister_IN;

		ROB_index_OUT <= ROB_index_IN;
		LSQ_index_OUT <= LSQ_index_IN;
		PhysReg_STALL_OUT <= PhysReg_STALL; //handle this later
	end //stalls?


end

endmodule