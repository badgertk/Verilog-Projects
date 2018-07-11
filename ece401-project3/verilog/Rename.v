//-----------------------------------------
//           RENAME
//-----------------------------------------

module Rename(
    input CLK,
    input RESET,
    
    //Instruction being passed to EXE [debug]
    input  [31:0]Instr1_IN,
    //PC of instruction being passed to EXE [debug]
    input  [31:0]Instr1_PC_IN,
	input  [31:0]Immediate_IN,
     //RegisterA passed to EXE
    input  [4:0]ReadRegisterA1_IN,
     //RegisterB passed to EXE
    input  [4:0]ReadRegisterB1_IN,
     //Destination Register passed to EXE
    input [4:0]WriteRegister1_IN,
     //we'll be writing to a register... passed to EXE
    input RegWrite1_IN,
    //ALU control passed to EXE
    input [5:0]ALU_Control1_IN,
    //This is a memory read (passed to EXE)
    input MemRead1_IN,
    //This is a memory write (passed to EXE)
    input MemWrite1_IN,
    //Shift amount [for ALU functions] (passed to EXE)
    input [4:0]ShiftAmount1_IN,
	input 		Jump_IN,
	input 		JumpRegister_IN,
	input 		ALUSrc_IN,
	input		SYS_IN,
	input		IssueQ_STALL_IN,
	
	output reg  [31:0]Instr1_OUT,
    //PC of instruction being passed to EXE [debug]
    output reg  [31:0]Instr1_PC_OUT,
	output reg 	[31:0]Immediate_OUT,
     //OperandA passed to EXE
    output reg  [5:0]OperandA1Pointer_OUT,
     //OperandB passed to EXE
    output reg  [5:0]OperandB1Pointer_OUT,
     //RegisterA passed to EXE
    output reg  [4:0]ReadRegisterA1_OUT,
     //RegisterB passed to EXE
    output reg  [4:0]ReadRegisterB1_OUT,
     //Destination Register passed to EXE
    output reg [4:0]WriteRegister1_OUT,
	output reg [5:0]WriteRegister1Pointer_OUT,
     //we'll be writing to a register... passed to EXE
    output reg RegWrite1_OUT,
    //ALU control passed to EXE
    output reg [5:0]ALU_Control1_OUT,
    //This is a memory read (passed to EXE)
    output reg MemRead1_OUT,
    //This is a memory write (passed to EXE)
    output reg MemWrite1_OUT,
    //Shift amount [for ALU functions] (passed to EXE)
    output reg [4:0]ShiftAmount1_OUT,
	output reg OpAReady,
	output reg OpBReady,
	output reg 		Jump_OUT,
	output reg 		JumpRegister_OUT,
	output reg 		ALUSrc_OUT,
	output reg		SYS_OUT,
	
	input [5:0] issueBroadcast,
	
	input 		RRATcopy,
	
	input LSQ_STALL, //if the lsq is full
	input ROB_STALL, //if the rob is full
	output renameSTALL
    );
	

	
wire STALL;
assign STALL = renameSTALL | LSQ_STALL | ROB_STALL;
wire [5:0] OperandA1Pointer_OUT;
wire [5:0] OperandB1Pointer_OUT;
wire [5:0] freeToFRAT1;
	
	BusyBits BusyBits1(
	    .CLK(CLK),
		.RESET(RESET),
		.regBusy(freeToFRAT1),
		.regReady(issueBroadcast),		//broadcast from issue q
		.readyCheck1(OperandA1Pointer_OUT),
		.readyCheck2(OperandB1Pointer_OUT),
		.isReady1(OpAReady),		//Rename output
		.isReady2(OpBReady)			//rename output
	);
	
	FreeList FreeList1(
		.CLK(CLK),
		.RESET(RESET),
		.Request(Request1),
		.freeToFRAT(freeToFRAT1),
		.recycleReady(recycleReady1),
		.registerRecycle(registerRecycle1),
		.STALL(renameSTALL)
	);
	
	RAT #(
		.NUM_ARCH_REGS(35),
		.NUM_PHYS_REGS(64)
	) FRAT(	
		.CLK(CLK),
		.RESET(RESET),
        .RegA1(ReadRegisterA1_IN),
        .RegB1(ReadRegisterB1_IN),
        .DataPointerA1(OperandA1Pointer_OUT),
        .DataPointerB1(OperandB1Pointer_OUT),
		.WriteReg1(WriteRegister1_IN),
        .WriteDataPointer1(WriteRegister1Pointer_OUT),
		.Write1(RegWrite1_IN),
        .nextFree(freeToFRAT1),
		.regRecover_IN(), //[34:0],
		.regRecover_OUT()// [34:0]
	);

   always @(posedge CLK or negedge RESET) begin
		if(!RESET) begin
			Instr1_OUT <= 0;
			Instr1_PC_OUT <= 0;
			OperandA1Pointer_OUT <= 0;
			OperandB1Pointer_OUT <= 0;
			ReadRegisterA1_OUT <= 0;
			ReadRegisterB1_OUT <= 0;
			WriteRegister1_OUT <= 0;
			RegWrite1_OUT <= 0;
			ALU_Control1_OUT <= 0;
			MemRead1_OUT <= 0;
			MemWrite1_OUT <= 0;
			ShiftAmount1_OUT <= 0;
			renameSTALL <= 0;
			Immediate_OUT <= 0;
			Jump_OUT <= 0;
			JumpRegister_OUT <= 0;
			ALUSrc_OUT <= 0;
			SYS_OUT <= 0;
		end else if (CLK) begin
			if(!STALL) begin
				Instr1_OUT <= Instr1_IN;
				Instr1_PC_OUT <= Instr1_PC_IN;
				OperandA1Pointer_OUT <= OperandA1Pointer_OUT;
				OperandB1Pointer_OUT <= OperandB1Pointer_OUT;
				ReadRegisterA1_OUT <= ReadRegisterA1_IN;
				ReadRegisterB1_OUT <= ReadRegisterB1_IN;
				WriteRegister1_OUT <= WriteRegister1_IN;
				RegWrite1_OUT <= RegWrite1_IN;
				ALU_Control1_OUT <= ALU_Control1_IN;
				MemRead1_OUT <= MemRead1_IN;
				MemWrite1_OUT <= MemWrite1_IN;
				ShiftAmount1_OUT <= ShiftAmount1_IN;
				renameSTALL <= renameSTALL;
				Immediate_OUT <= Immediate_IN;
				Jump_OUT <= Jump_IN;
				JumpRegister_OUT <= JumpRegister_IN;
				ALUSrc_OUT <= ALUSrc_IN;
				SYS_OUT <= SYS_IN;
			end else begin
				//stall;
			end
		end
	end

endmodule