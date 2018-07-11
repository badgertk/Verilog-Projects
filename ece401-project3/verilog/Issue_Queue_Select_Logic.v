module Issue_Queue_Select_Logic(
	input CLK,
	input RESET,
	
	input [31:0] Instr_PC_IN,
	input [5:0] Phys_RegisterA_IN,
	input 		Phys_RegisterA_Ready_IN,
	input [5:0] Phys_RegisterB_IN,
	input		Phys_RegisterB_Ready_IN,
	//metadata
	input [31:0] Instr_IN, //is this necessary?
	input [31:0] Immediate_IN,
	input [5:0] Dest_Phys_Register_IN, //if this instruction doesn't write to the reg file, this value will be garbage.
	input RegWrite_IN, //is this metadata?
	input [5:0] ALU_Control_IN,
	input MemRead_IN,
	input MemWrite_IN,
	input [4:0] ShiftAmount_IN,
	input 		Jump_IN,
	input 		JumpRegister_IN,
	input 		ALUSrc_IN,
	input [5:0] ROB_index_IN, //this comes from ROB
	input [3:0] LSQ_index_IN, //this comes from LSQ
	
	output [31:0] Instr_PC_OUT,
	output [5:0] Phys_RegisterA_OUT,
	output [5:0] Phys_RegisterB_OUT,
	//metadata
	output [31:0] Instr_OUT, //is this necessary?
	output [31:0] Immediate_OUT,
	output [5:0] Dest_Phys_Register_OUT, //if this instruction doesn't write to the reg file, this value will be garbage.
	output RegWrite_OUT, //is this metadata?
	output [5:0] ALU_Control_OUT,
	output MemRead_OUT,
	output MemWrite_OUT,
	output [4:0] ShiftAmount_OUT,
	output  	Jump_OUT,
	output  	JumpRegister_OUT,
	output  	ALUSrc_OUT,
	output [5:0] ROB_index_OUT,
	output [3:0] LSQ_index_OUT,
	
	
	input RENAME_STALL,
	output IssueQ_STALL_forRegFile,
	output IssueQ_STALL_forRename

);

//TODO:add stall handling

//wires connecting Issue_Queue and Wakeup_Select
wire [3:0] select_index_WSIQ;
wire [15:0] select_array_IQWS;
wire 		CanIssue;

//wires connecting Issue_Queue and Select_Vacancy
wire [15:0] vacancy_array_IQSV;
wire [3:0] vacancy_index_SVIQ;
wire		CanDispatch;

assign IssueQ_STALL_forRegFile = !CanIssue;
assign IssueQ_STALL_forRename = !CanDispatch;

Wakeup_Select Wakeup_Select(
	.request_IN(select_array_IQWS),
	.Issue_OUT(CanIssue),
	.grant_index_OUT(select_index_WSIQ)
);

Select_Vacancy Select_Vacancy(
	.request_IN(vacancy_array_IQSV),
	.Dispatch_OUT(CanDispatch),
	.grant_index_OUT(vacancy_index_SVIQ)
);


Issue_Queue Issue_Queue(
	.CLK(CLK),
	.RESET(RESET),
	
	.PC_IN(Instr_PC_IN),
	.src1_IN(Phys_RegisterA_IN),
	.busybit_src1_IN(Phys_RegisterA_Ready_IN),
	.src2_IN(Phys_RegisterB_IN),
	.busybit_src2_IN(Phys_RegisterB_Ready_IN),
	//metadata
	.Instr_IN(Instr_IN), //is this necessary?
	.Immediate_IN(Immediate_IN),
	.dest_IN(Dest_Phys_Register_IN),
	.RegWrite_IN(RegWrite_IN), //is this metadata?
	.ALU_Control_IN(ALU_Control_IN),
	.MemRead_IN(MemRead_IN),
	.MemWrite_IN(MemWrite_IN),
	.ShiftAmount_IN(ShiftAmount_IN),
	.Jump_IN(Jump_IN),
	.JumpRegister_IN(JumpRegister_IN),
	.ALUSrc_IN(ALUSrc_IN),
	.ROB_index_IN(ROB_index_IN),
	.LSQ_index_IN(LSQ_index_IN),
	
	.PC_OUT(Instr_PC_OUT),
	.src1_OUT(Phys_RegisterA_OUT),
	.src2_OUT(Phys_RegisterB_OUT),
	//metadata
	.Instr_OUT(Instr_OUT), //is this necessary?
	.Immediate_OUT(Immediate_OUT),
	.dest_OUT(Dest_Phys_Register_OUT), //if this instruction doesn't write to the reg file, this value will be garbage.
	.RegWrite_OUT(RegWrite_OUT), //is this metadata?
	.ALU_Control_OUT(ALU_Control_OUT),
	.MemRead_OUT(MemRead_OUT),
	.MemWrite_OUT(MemWrite_OUT),
	.ShiftAmount_OUT(ShiftAmount_OUT),
	.Jump_OUT(Jump_OUT),
	.JumpRegister_OUT(JumpRegister_OUT),
	.ALUSrc_OUT(ALUSrc_OUT),
	.ROB_index_OUT(ROB_index_OUT),
	.LSQ_index_OUT(LSQ_index_OUT),
	
	//connect to wakeupselect
	.Issue_IN(CanIssue),
	.grant_select_index(select_index_WSIQ), 
	.issue_select_array(select_array_IQWS), 
	
	//connect to selectvacancy
	.Dispatch_IN(CanDispatch),
	.grant_vacancy_index(vacancy_index_SVIQ), 
	.issue_vacancy_array(vacancy_array_IQSV)
);

endmodule