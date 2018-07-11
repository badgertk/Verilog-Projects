`include "config.v"
//-----------------------------------------
//            Pipelined MIPS
//-----------------------------------------
module MIPS (

    input RESET,
    input CLK,
    
    //The physical memory address we want to interact with
    output [31:0] data_address_2DM,
    //We want to perform a read?
    output MemRead_2DM,
    //We want to perform a write?
    output MemWrite_2DM,
    
    //Data being read
    input [31:0] data_read_fDM,
    //Data being written
    output [31:0] data_write_2DM,
    //How many bytes to write:
        // 1 byte: 1
        // 2 bytes: 2
        // 3 bytes: 3
        // 4 bytes: 0
    output [1:0] data_write_size_2DM,
    
    //Data being read
    input [255:0] block_read_fDM,
    //Data being written
    output [255:0] block_write_2DM,
    //Request a block read
    output dBlkRead,
    //Request a block write
    output dBlkWrite,
    //Block read is successful (meets timing requirements)
    input block_read_fDM_valid,
    //Block write is successful
    input block_write_fDM_valid,
    
    //Instruction to fetch
    output [31:0] Instr_address_2IM,
    //Instruction fetched at Instr_address_2IM    
    input [31:0] Instr1_fIM,
    //Instruction fetched at Instr_address_2IM+4 (if you want superscalar)
    input [31:0] Instr2_fIM,

    //Cache block of instructions fetched
    input [255:0] block_read_fIM,
    //Block read is successfull
    input block_read_fIM_valid,
    //Request a block read
    output iBlkRead,
    
    //Tell the simulator that everything's ready to go to process a syscall.
    //Make sure that all register data is flushed to the register file, and that 
    //all data cache lines are flushed and invalidated.
    output SYS
    );
    
	wire WIPE;
	assign WIPE = FLUSH_fROB || RESET;
	
//Connecting wires between ROB and IF
	wire 		Request_Alt_PC_ROB_IF;
	wire [31:0] Alt_PC_ROB_IF;
	
//Connecting wires between IF and FIFO

	wire [31:0] Instr_PC_IF_FIFO;

	wire [31:0] Instr_IF_FIFO;
	wire [31:0] Instr_PC_Plus4_IF_FIFO;
`ifdef USE_ICACHE
    wire        Instr1_Available_IF_FIFO;
`endif
	wire		IF_STALL;
	wire		ID_STALL;
	wire 		STALL_forIF;
	wire		STALL_forID;
	wire 		STALL_forID2;
	assign IF_STALL = !Instr1_Available_IF_FIFO;
	wire 		FIFO_STALL;
	

//Connecting wires between FIFO and ID

	wire [31:0] Instr_PC_FIFO_ID;

	wire [31:0] Instr_FIFO_ID;
	wire [31:0] Instr_PC_Plus4_FIFO_ID;
	
//Connecting Wires between IF and ROB
	wire [31: 0] Alt_PC_fROB;
	wire 		 request_Alt_PC_fROB;

    
//Connecting wires between IC and IF 
//(NOTE TO SELF; LEAVE THIS ALONE)
    wire [31:0] Instr_address_2IC/*verilator public*/;
    //Instr_address_2IC is verilator public so that sim_main can give accurate displays. 
    wire [31:0] Instr1_fIC;
`ifdef USE_ICACHE
    wire        Instr1_fIC_IsValid;
`endif
    wire [31:0] Instr2_fIC;
    wire        Instr2_fIC_IsValid;
`ifdef USE_ICACHE
    Cache #(
    .CACHENAME("I$1")
    ) ICache(
        .CLK(CLK),
        .RESET(RESET),
        .Read1(1'b1),
        .Write1(1'b0),
        .Flush1(1'b0),
        .Address1(Instr_address_2IC),
        .WriteData1(32'd0),
        .WriteSize1(2'd0),
        .ReadData1(Instr1_fIC),
        .OperationAccepted1(Instr1_fIC_IsValid),
        .ReadData2(Instr2_fIC),
        .DataValid2(Instr2_fIC_IsValid),
        .read_2DM(iBlkRead),
/* verilator lint_off PINCONNECTEMPTY */
        .write_2DM(),
/* verilator lint_on PINCONNECTEMPTY */
        .address_2DM(Instr_address_2IM),
/* verilator lint_off PINCONNECTEMPTY */
        .data_2DM(),
/* verilator lint_on PINCONNECTEMPTY */
        .data_fDM(block_read_fIM),
        .dm_operation_accepted(block_read_fIM_valid)
    );
    /*verilator lint_off UNUSED*/
    wire [31:0] unused_i1;
    wire [31:0] unused_i2;
    /*verilator lint_on UNUSED*/
    assign unused_i1 = Instr1_fIM;
    assign unused_i2 = Instr2_fIM;
`else
    assign Instr_address_2IM = Instr_address_2IC;
    assign Instr1_fIC = Instr1_fIM;
`ifdef USE_ICACHE
    assign Instr1_fIC_IsValid = 1'b1;
`endif
    assign Instr2_fIC = Instr2_fIM;
    assign Instr2_fIC_IsValid = 1'b1;
    assign iBlkRead = 1'b0;
    /*verilator lint_off UNUSED*/
    wire [255:0] unused_i1;
    wire unused_i2;
    /*verilator lint_on UNUSED*/
    assign unused_i1 = block_read_fIM;
    assign unused_i2 = block_read_fIM_valid;
`endif
`ifdef SUPERSCALAR
`else
    /*verilator lint_off UNUSED*/
    wire [31:0] unused_i3;
    wire unused_i4;
    /*verilator lint_on UNUSED*/
    assign unused_i3 = Instr2_fIC;
    assign unused_i4 = Instr2_fIC_IsValid;
`endif

    IF IF(
        .CLK(CLK),
        .RESET(WIPE), //?
        .Instr1_OUT(Instr_IF_FIFO),
        .Instr_PC_OUT(Instr_PC_IF_FIFO),
        .Instr_PC_Plus4(Instr_PC_Plus4_IF_FIFO),
`ifdef USE_ICACHE
        .Instr1_Available(Instr1_Available_IF_FIFO),
`endif
        .STALL(STALL_forIF),//was previously STALL_IDIF
        .Request_Alt_PC(Request_Alt_PC_ROB_IF),//comes from ROB
        .Alt_PC(Alt_PC_ROB_IF),//comes from ROB
        .Instr_address_2IM(Instr_address_2IC),
        .Instr1_fIM(Instr1_fIC)
`ifdef USE_ICACHE
        ,
        .Instr1_fIM_IsValid(Instr1_fIC_IsValid)
`endif
    );
 
	IF_ID_FIFO IF_ID_FIFO(
		.CLK(CLK),
		.RESET(WIPE),
		.PC_IN(Instr_PC_IF_FIFO),
		.Instr_IN(Instr_IF_FIFO),
		.Instr_PC_Plus4_IN(Instr_PC_Plus4_IF_FIFO),

		.PC_OUT(Instr_PC_FIFO_ID),
		.Instr_OUT(Instr_FIFO_ID),
		.Instr_PC_Plus4_OUT(Instr_PC_Plus4_FIFO_ID),

		.STALL_IF_IN(IF_STALL),
		.STALL_forIF(STALL_forIF),
		.STALL_forID(STALL_forID),
		.STALL_ID_IN(ID_STALL)

	);
 
`ifdef USE_DCACHE
	wire        MEM_STALL;
`endif

    wire [4:0]  WriteRegister1_MEMWB;
	wire [31:0] WriteData1_MEMWB;
	wire        RegWrite1_MEMWB;
	
	wire [31:0] Instr1_IDEXE;
    wire [31:0] Instr1_PC_IDEXE;
	wire [31:0] OperandA1_IDEXE;
	wire [31:0] OperandB1_IDEXE;
`ifdef HAS_FORWARDING
    wire [4:0]  RegisterA1_IDEXE;
    wire [4:0]  RegisterB1_IDEXE;
`endif
    wire [4:0]  WriteRegister1_IDEXE;
    wire [31:0] MemWriteData1_IDEXE;
    wire        RegWrite1_IDEXE;
    wire [5:0]  ALU_Control1_IDEXE;
    wire        MemRead1_IDEXE;
    wire        MemWrite1_IDEXE;
    wire [4:0]  ShiftAmount1_IDEXE;
    
`ifdef HAS_FORWARDING
    wire [4:0]  BypassReg1_EXEID;
    wire [31:0] BypassData1_EXEID;
    wire        BypassValid1_EXEID;
    
    wire [4:0]  BypassReg1_MEMID;
    wire [31:0] BypassData1_MEMID;
    wire        BypassValid1_MEMID;
`endif
    
//wires connecting ID and FIFO
	wire [31:0]	Instr_ID_FIFO;
	wire [31:0]	Instr_PC_ID_FIFO;
	wire [31:0]	OperandB1_ID_FIFO;
	wire [4:0]	RegisterA1_ID_FIFO;
	wire [4:0]	RegisterB1_ID_FIFO;
	wire [4:0]	WriteRegister1_ID_FIFO;
	wire 		RegWrite1_ID_FIFO;
	wire [5:0]	ALU_Control1_ID_FIFO;
	wire 		MemRead1_ID_FIFO;
	wire 		MemWrite1_ID_FIFO;
	wire [4:0]	ShiftAmount1_ID_FIFO;
	wire 		Jump_ID_FIFO;
	wire		Jump_Register_ID_FIFO;
	wire 		SYS_ID_FIFO;
	wire		ALUSrc_ID_FIFO;

//wires connecting FIFO and RENAME
	wire [31:0]	Instr_PC_FIFO_RENAME;
	wire [31:0]	Instr_FIFO_RENAME;
	wire [31:0]	Immediate_FIFO_RENAME;
	wire [4:0]	RegisterA1_FIFO_RENAME;
	wire [4:0]	RegisterB1_FIFO_RENAME;
	wire [4:0]	WriteRegister1_FIFO_RENAME;
	wire 		RegWrite1_FIFO_RENAME;
	wire [5:0]	ALU_Control1_FIFO_RENAME;
	wire 		MemRead1_FIFO_RENAME;
	wire 		MemWrite1_FIFO_RENAME;
	wire [4:0]	ShiftAmount1_FIFO_RENAME;
	wire		Jump_FIFO_RENAME;
	wire		Jump_Register_FIFO_RENAME;
	wire		SYS_FIFO_RENAME;
	wire		ALUSrc_FIFO_RENAME;
	wire 		STALL_forRENAME;
		
	wire 		RENAME_STALL;
	
	
	ID ID( //this module has undergone drastic changes, all things pertaining to the reg file will be removed.
		.CLK(CLK),
		.RESET(WIPE),
		.Instr1_IN(Instr_FIFO_ID),
		.STALL_forID(STALL_forID), //change
		.STALL_forID2(STALL_forID2),
		.Instr_PC_IN(Instr_PC_FIFO_ID),
		.Instr_PC_Plus4_IN(Instr_PC_Plus4_FIFO_ID),
		.Instr1_OUT(Instr_ID_FIFO),
        .Instr1_PC_OUT(Instr_PC_ID_FIFO),
		.OperandB1_OUT(OperandB1_ID_FIFO),
`ifdef HAS_FORWARDING
		.ReadRegisterA1_OUT(RegisterA1_ID_FIFO),
		.ReadRegisterB1_OUT(RegisterB1_ID_FIFO),
`else
/* verilator lint_off PINCONNECTEMPTY */
        .ReadRegisterA1_OUT(),
        .ReadRegisterB1_OUT(),
/* verilator lint_on PINCONNECTEMPTY */
`endif
		.WriteRegister1_OUT(WriteRegister1_ID_FIFO),
		.RegWrite1_OUT(RegWrite1_ID_FIFO),
		.ALU_Control1_OUT(ALU_Control1_ID_FIFO),
		.MemRead1_OUT(MemRead1_ID_FIFO),
		.MemWrite1_OUT(MemWrite1_ID_FIFO),
		.ShiftAmount1_OUT(ShiftAmount1_ID_FIFO),
		.Jump_OUT(Jump_ID_FIFO),
		.JumpRegister_OUT(Jump_Register_ID_FIFO),
		.ALUSrc_OUT(ALUSrc_ID_FIFO),
		
		.SYS(SYS_ID_FIFO)
	);
	
	ID_RENAME_FIFO ID_RENAME_FIFO(
		.CLK(CLK),
		.RESET(WIPE),
		.PC_IN(Instr_PC_ID_FIFO),
		//input [1000:0] metadata_IN,
		.Instr_IN(Instr_ID_FIFO),
		.OperandB_IN(OperandB1_ID_FIFO),
		.ReadRegisterA1_IN(RegisterA1_ID_FIFO), 
		.ReadRegisterB1_IN(RegisterB1_ID_FIFO),
		.WriteRegister1_IN(WriteRegister1_ID_FIFO),
		.RegWrite_IN(RegWrite1_ID_FIFO),
		.ALU_Control1_IN(ALU_Control1_ID_FIFO),
		.MemRead1_IN(MemRead1_ID_FIFO),
		.MemWrite1_IN(MemWrite1_ID_FIFO),
		.ShiftAmount1_IN(ShiftAmount1_ID_FIFO),
		.Jump_IN(Jump_ID_FIFO),
		.JumpRegister_IN(Jump_Register_ID_FIFO),
		.ALUSrc_IN(ALUSrc_ID_FIFO),
		.SYS_IN(SYS_ID_FIFO),
	
		.PC_OUT(Instr_PC_FIFO_RENAME),
		//output reg [1000:0] metadata_OUT,
		.Instr_OUT(Instr_FIFO_RENAME),
		.OperandB_OUT(Immediate_FIFO_RENAME),
		.ReadRegisterA1_OUT(RegisterA1_FIFO_RENAME),
		.ReadRegisterB1_OUT(RegisterB1_FIFO_RENAME),
		.WriteRegister1_OUT(WriteRegister1_FIFO_RENAME),
		.RegWrite_OUT(RegWrite1_FIFO_RENAME),
		.ALU_Control1_OUT(ALU_Control1_FIFO_RENAME),
		.MemRead1_OUT(MemRead1_FIFO_RENAME),
		.MemWrite1_OUT(MemWrite1_FIFO_RENAME),
		.ShiftAmount1_OUT(ShiftAmount1_FIFO_RENAME),
		.Jump_OUT(Jump_FIFO_RENAME),
		.JumpRegister_OUT(Jump_Register_FIFO_RENAME),
		.ALUSrc_OUT(ALUSrc_FIFO_RENAME),
		.SYS_OUT(SYS_FIFO_RENAME),

		.STALL_ID_IN(ID_STALL),
		.STALL_forRENAME(STALL_forRENAME),
		.STALL_forID(STALL_forID2),
		.STALL_RENAME_IN(RENAME_STALL)

	);
	
//wires connecting Rename and Issue Queue
	wire 		Dest_Phys_Register_ISSUEQ; //also to phys reg
	wire		Instr1_PC_RENAME_ISSUEQ;
	wire		OperandA1Pointer_RENAME_ISSUEQ;
	wire 		OpA_BusyBit;
	wire 		OperandB1Pointer_RENAME_ISSUEQ;
	wire 		OpB_BusyBit;
	//metadata
	wire 		Instr1_RENAME_ISSUEQ;
	wire		Immediate_RENAME_ISSUEQ;
	wire		WriteRegister1Pointer_RENAME_ISSUEQ;
	wire 		RegWrite1_RENAME_ISSUEQ;
	wire 		ALU_Control1_RENAME_ISSUEQ;
	wire 		MemRead1_RENAME; //also to rob and lsq
	wire 		MemWrite1_RENAME; //also to rob and lsq
	wire		ShiftAmount1_RENAME_ISSUEQ;
	wire		Jump_RENAME_ISSUEQ;
	wire 		JumpRegister_RENAME_ISSUEQ;
	wire 		ALUSrc_RENAME_ISSUEQ;



//wires connecting Rename and Reorder Buffer
	wire [5:0] RRAT_to_FRAT1 [31:0];
	wire		SYS_RENAME_ROB;
	wire 		ReadRegisterA1_RENAME_ROB;
	wire 		ReadRegisterB1_RENAME_ROB;
	wire 		WriteRegister1_RENAME_ROB;

//wires connecting rename and load/store queue

//wires connecting Issue Queue and Phys Reg File
	wire [31:0] Instr_PC_ISSUEQ_PhysReg;
	wire [5:0] 	Phys_RegisterA_ISSUEQ_PhysReg;
	wire [5:0] 	Phys_RegisterB_ISSUEQ_PhysReg;
	wire [31:0] Instr_ISSUEQ_PhysReg;
	wire [31:0] Immediate_ISSUEQ_PhysReg;
	wire 		RegWrite_ISSUEQ_PhysReg;
	wire [5:0] 	ALU_Control_ISSUEQ_PhysReg;
	wire 		MemRead_ISSUEQ_PhysReg;
	wire 		MemWrite_ISSUEQ_PhysReg;
	wire [4:0] 	ShiftAmount_ISSUEQ_PhysReg;
	wire  		Jump_ISSUEQ_PhysReg;
	wire  		JumpRegister_ISSUEQ_PhysReg;
	wire  		ALUSrc_ISSUEQ_PhysReg;
	wire 		SYS_ISSUEQ_PhysReg;
	wire [5:0] 	ROB_index_ISSUEQ_PhysReg;
	wire [3:0] 	LSQ_index_ISSUEQ_PhysReg;
	wire 		CannotIssue;
	wire 		CannotDispatch;
	wire 		PhysReg_STALL;
	wire 		STALL_fLSQ;
	
	Rename Rename(
		.CLK(CLK),
		.RESET(WIPE),
		
		.Instr1_IN(Instr_FIFO_RENAME),
		.Instr1_PC_IN(Instr_PC_FIFO_RENAME),
		.Immediate_IN(Immediate_FIFO_RENAME),
		.ReadRegisterA1_IN(RegisterA1_FIFO_RENAME),
		.ReadRegisterB1_IN(RegisterB1_FIFO_RENAME),
		.WriteRegister1_IN(WriteRegister1_FIFO_RENAME),
		.RegWrite1_IN(RegWrite1_FIFO_RENAME),
		.ALU_Control1_IN(ALU_Control1_FIFO_RENAME),
		.MemRead1_IN(MemRead1_FIFO_RENAME),
		.MemWrite1_IN(MemWrite1_FIFO_RENAME),
		.ShiftAmount1_IN(ShiftAmount1_FIFO_RENAME),
		.Jump_IN(Jump_FIFO_RENAME),
		.JumpRegister_IN(Jump_Register_FIFO_RENAME),
		.ALUSrc_IN(ALUSrc_FIFO_RENAME),
		.SYS_IN(SYS_FIFO_RENAME),
		.IssueQ_STALL_IN(CannotDispatch),
		//.STALL_forRENAME(STALL_forRENAME),

		.Instr1_OUT(Instr1_RENAME_ISSUEQ),
		.Instr1_PC_OUT(Instr1_PC_RENAME_ISSUEQ),
		.Immediate_OUT(Immediate_RENAME_ISSUEQ),
		.OperandA1Pointer_OUT(OperandA1Pointer_RENAME_ISSUEQ),
		.OperandB1Pointer_OUT(OperandB1Pointer_RENAME_ISSUEQ),
		.ReadRegisterA1_OUT(ReadRegisterA1_RENAME_ROB),
		.ReadRegisterB1_OUT(ReadRegisterB1_RENAME_ROB),
		.WriteRegister1_OUT(WriteRegister1_RENAME_ROB),
		.WriteRegister1Pointer_OUT(WriteRegister1Pointer_RENAME_ISSUEQ),
		.RegWrite1_OUT(RegWrite1_RENAME_ISSUEQ),
		.ALU_Control1_OUT(ALU_Control1_RENAME_ISSUEQ),
		.MemRead1_OUT(MemRead1_RENAME),
		.MemWrite1_OUT(MemWrite1_RENAME),
		.ShiftAmount1_OUT(ShiftAmount1_RENAME_ISSUEQ),
		.Jump_OUT(Jump_FIFO_RENAME),
		.JumpRegister_OUT(Jump_Register_FIFO_RENAME),
		.ALUSrc_OUT(ALUSrc_FIFO_RENAME),
		.SYS_OUT(SYS_RENAME_ROB), //TO ROB
		
		.OpAReady(OpA_BusyBit), //to Issue Queue
		.OpBReady(OpB_BusyBit), //to Issue Queue
		
		.issueBroadcast(Dest_Phys_Register_ISSUEQ), //from Issue Queue
		
		.RRATcopy(RRAT_to_FRAT1),
		
		.LSQ_STALL(STALL_fLSQ), //MUST BE ADDED TO RENAME MODULE
		.ROB_STALL(STALL_fROB),
		.renameSTALL(RENAME_STALL) //worry about stalls later
	);
	
//wires connecting issue queue and reorder buffer
	wire [5:0]		ROB_index_ROB_ISSUEQ;
	
//wire connecting issue queue and load/store queue
	wire [3:0]		LSQ_index_LSQ_ISSUEQ;
	
	
	Issue_Queue_Select_Logic IssueQ(
		.CLK(CLK),
		.RESET(WIPE),
		
		.Instr_PC_IN(Instr1_PC_RENAME_ISSUEQ),
		.Phys_RegisterA_IN(OperandA1Pointer_RENAME_ISSUEQ),
		.Phys_RegisterA_Ready_IN(OpA_BusyBit),
		.Phys_RegisterB_IN(OperandB1Pointer_RENAME_ISSUEQ),
		.Phys_RegisterB_Ready_IN(OpB_BusyBit),

		//metadata
		.Instr_IN(Instr1_RENAME_ISSUEQ),
		.Immediate_IN(Immediate_RENAME_ISSUEQ),
		.Dest_Phys_Register_IN(WriteRegister1Pointer_RENAME_ISSUEQ),
		.RegWrite_IN(RegWrite1_RENAME_ISSUEQ),
		.ALU_Control_IN(ALU_Control1_RENAME_ISSUEQ),
		.MemRead_IN(MemRead1_RENAME),
		.MemWrite_IN(MemWrite1_RENAME),
		.ShiftAmount_IN(ShiftAmount1_RENAME_ISSUEQ),
		.Jump_IN(Jump_RENAME_ISSUEQ),
		.JumpRegister_IN(JumpRegister_RENAME_ISSUEQ),
		.ALUSrc_IN(ALUSrc_RENAME_ISSUEQ),
		.ROB_index_IN(ROB_index_ROB_ISSUEQ),
		.LSQ_index_IN(LSQ_index_LSQ_ISSUEQ),
		
		.Instr_PC_OUT(Instr_PC_ISSUEQ_PhysReg),
		.Phys_RegisterA_OUT(Phys_RegisterA_ISSUEQ_PhysReg),
		.Phys_RegisterB_OUT(Phys_RegisterB_ISSUEQ_PhysReg),

		//metadata
		.Instr_OUT(Instr_ISSUEQ_PhysReg),
		.Immediate_OUT(Immediate_ISSUEQ_PhysReg),
		.Dest_Phys_Register_OUT(Dest_Phys_Register_ISSUEQ),
		.RegWrite_OUT(RegWrite_ISSUEQ_PhysReg),
		.ALU_Control_OUT(ALU_Control_ISSUEQ_PhysReg),
		.MemRead_OUT(MemRead_ISSUEQ_PhysReg),
		.MemWrite_OUT(MemWrite_ISSUEQ_PhysReg),
		.ShiftAmount_OUT(ShiftAmount_ISSUEQ_PhysReg),
		.Jump_OUT(Jump_ISSUEQ_PhysReg),
		.JumpRegister_OUT(JumpRegister_ISSUEQ_PhysReg),
		.ALUSrc_OUT(ALUSrc_ISSUEQ_PhysReg),
		.ROB_index_OUT(ROB_index_ISSUEQ_PhysReg),
		.LSQ_index_OUT(LSQ_index_ISSUEQ_PhysReg),
		
		.RENAME_STALL(RENAME_STALL),
		.IssueQ_STALL_forRegFile(CannotIssue),
		.IssueQ_STALL_forRename(CannotDispatch)
		
	);

//-----------------------------------------------------------------------------------
//                EVERYTHING UNDERNEATH THIS NEEDS TO BE CHECKED FOR FORWARDING
//-----------------------------------------------------------------------------------	
//PhysRegFile --> EXE --> LSQ --> MEM

//wires connecting Phys Reg File and EXE

 	wire [31:0] Instr1_PhysReg_EXE;
    wire [31:0] Instr1_PC_PhysReg_EXE;
	wire [31:0] OperandA1_PhysReg_EXE;
	wire [31:0] OperandB1_PhysReg_EXE;
`ifdef HAS_FORWARDING //believe this is all the forwarding needed?
    wire [5:0]  RegisterA1_PhysReg_EXE;
    wire [5:0]  RegisterB1_PhysReg_EXE;
`endif
    wire [5:0]  WriteRegister1_PhysReg_EXE;
    wire [31:0] MemWriteData1_PhysReg_EXE;
    wire        RegWrite1_PhysReg_EXE;
    wire [5:0]  ALU_Control1_PhysReg_EXE;
    wire        MemRead1_PhysReg_EXE;
    wire        MemWrite1_PhysReg_EXE;
    wire [4:0]  ShiftAmount1_PhysReg_EXE;
	wire		Jump_PhysReg_EXE;
	wire		JumpRegister_PhysReg_EXE;
	wire [5:0]	ROB_index_PhysReg_EXE;
	wire [3:0]	LSQ_index_PhysReg_EXE;
	wire 		EXE_STALL_EXE_PhysReg;


	wire [31:0] Instr1_EXEMEM;
	wire [31:0] Instr1_PC_EXEMEM;
	wire [31:0] ALU_result1_EXEMEM;
    wire [4:0]  WriteRegister1_EXEMEM;
    wire [31:0] MemWriteData1_EXEMEM;
    wire        RegWrite1_EXEMEM;
    wire [5:0]  ALU_Control1_EXEMEM;
    wire        MemRead1_EXEMEM;
    wire        MemWrite1_EXEMEM;
`ifdef HAS_FORWARDING //not quite sure what this is
    wire [31:0] ALU_result_async1;
    wire        ALU_result_async_valid1;
`endif

PhysReg PhysReg(
	.CLK(CLK),
	.RESET(WIPE),
	
	.Instr_PC_IN(Instr_PC_ISSUEQ_PhysReg),
	.Phys_RegisterA_IN(Phys_RegisterA_ISSUEQ_PhysReg),
	.Phys_RegisterB_IN(Phys_RegisterB_ISSUEQ_PhysReg),
	.Instr_IN(Instr_ISSUEQ_PhysReg), 
	.Immediate_IN(Immediate_ISSUEQ_PhysReg),
	.Dest_Phys_Register_IN(Dest_Phys_Register_ISSUEQ), 
	.RegWriteData_IN(0), //wb???
	.RegWrite_IN(RegWrite_ISSUEQ_PhysReg), 
	.ALU_Control_IN(ALU_Control_ISSUEQ_PhysReg),
	.MemRead_IN(MemRead_ISSUEQ_PhysReg),
	.MemWrite_IN(MemWrite_ISSUEQ_PhysReg),
	.ShiftAmount_IN(ShiftAmount_ISSUEQ_PhysReg),
	.Jump_IN(Jump_ISSUEQ_PhysReg),
	.JumpRegister_IN(JumpRegister_ISSUEQ_PhysReg),
	.ALUSrc_IN(ALUSrc_ISSUEQ_PhysReg),
	.ROB_index_IN(ROB_index_ISSUEQ_PhysReg),
	.LSQ_index_IN(LSQ_index_ISSUEQ_PhysReg),
	.EXE_STALL(EXE_STALL_EXE_PhysReg), 
	.IssueQ_STALL(CannotIssue),
	
	.Instr_PC_OUT(Instr1_PC_PhysReg_EXE),
	.Phys_RegisterA_OUT(RegisterA1_PhysReg_EXE),
	.OperandA_OUT(OperandA1_PhysReg_EXE),
	.Phys_RegisterB_OUT(RegisterB1_PhysReg_EXE),
	.OperandB_OUT(OperandB1_PhysReg_EXE),
	.Instr_OUT(Instr1_PhysReg_EXE),
	.Dest_Phys_Register_OUT(WriteRegister1_PhysReg_EXE),
	.MemWriteData1_OUT(MemWriteData1_PhysReg_EXE),
	.RegWrite_OUT(RegWrite1_PhysReg_EXE),
	.ALU_Control_OUT(ALU_Control1_PhysReg_EXE),
	.MemRead_OUT(MemRead1_PhysReg_EXE),
	.MemWrite_OUT(MemWrite1_PhysReg_EXE),
	.ShiftAmount_OUT(ShiftAmount1_PhysReg_EXE),
	.Jump_OUT(Jump_PhysReg_EXE),
	.JumpRegister_OUT(JumpRegister_PhysReg_EXE),
	.ROB_index_OUT(ROB_index_PhysReg_EXE),
	.LSQ_index_OUT(LSQ_index_PhysReg_EXE),
	.PhysReg_STALL_OUT(PhysReg_STALL)
);



//wires connecting EXE to LSQ
	wire [3:0]	LSQ_index_EXE_LSQ;
	wire LSQ_Issue;
		
//wires connecting EXE and reorder buffer
	wire 		Request_Alt_PC_EXE_ROB; //to ROB
	wire [31:0]	Alt_PC_EXE_ROB; //to ROB
	wire [5:0]	ROB_index_EXE_ROB; //to ROB

	
	//i/o s look okay
	EXE EXE(
		.CLK(CLK),
		.RESET(WIPE),
`ifdef USE_DCACHE
		.MEM_STALL(LSQ_Issue), //lsq has priority
		.LSQ_STALL(STALL_fLSQ), //lsq full and exe has mem instr
`endif
		.Instr1_IN(Instr1_PhysReg_EXE),
		.Instr1_PC_IN(Instr1_PC_PhysReg_EXE),
`ifdef HAS_FORWARDING
		.RegisterA1_IN(RegisterA1_PhysReg_EXE),
`endif
		.OperandA1_IN(OperandA1_PhysReg_EXE),
`ifdef HAS_FORWARDING
		.RegisterB1_IN(RegisterB1_PhysReg_EXE),
`endif
		.OperandB1_IN(OperandB1_PhysReg_EXE),
		.WriteRegister1_IN(WriteRegister1_PhysReg_EXE), 
		.MemWriteData1_IN(MemWriteData1_PhysReg_EXE),
		.RegWrite1_IN(RegWrite1_PhysReg_EXE),
		.ALU_Control1_IN(ALU_Control1_PhysReg_EXE),
		.MemRead1_IN(MemRead1_PhysReg_EXE),
		.MemWrite1_IN(MemWrite1_PhysReg_EXE),
		.ShiftAmount1_IN(ShiftAmount1_PhysReg_EXE),
		.Jump_IN(Jump_PhysReg_EXE),
		.JumpRegister_IN(JumpRegister_PhysReg_EXE),
		.ROB_index_IN(ROB_index_PhysReg_EXE),
		.LSQ_index_IN(LSQ_index_PhysReg_EXE), 
		
		.Instr1_OUT(Instr1_EXE),// both lsq and mem
		.Instr1_PC_OUT(Instr1_PC_EXE), //both lsq and mem
		.ALU_result1_OUT(ALU_result1_EXE), //both lsq and mem
		.WriteRegister1_OUT(WriteRegister1_EXE_MEM), //mem
		.MemWriteData1_OUT(MemWriteData1_EXE_LSQ), //to lsq
		.RegWrite1_OUT(RegWrite1_EXE_MEM), //mem
		.ALU_Control1_OUT(ALU_Control1_EXE), //both
		.MemRead1_OUT(MemRead1_EXE_LSQ), //lsq
		.MemWrite1_OUT(MemWrite1_EXE_LSQ), //lsq
		.Request_Alt_PC_OUT(Request_Alt_PC_EXE_ROB), //to ROB
		.Alt_PC_OUT(Alt_PC_EXE_ROB), //to ROB
		.ROB_index_OUT(ROB_index_EXE_ROB), //to ROB
		.LSQ_index_OUT(LSQ_index_EXE_LSQ), //to LSQ
		.EXE_STALL(EXE_STALL_EXE_PhysReg) //to Phys Reg
`ifdef HAS_FORWARDING //need to deal with bypassing for WB stage
		,
		.BypassReg1_MEMEXE(WriteRegister1_MEMWB),
		.BypassData1_MEMEXE(WriteData1_MEMWB),
		.BypassValid1_MEMEXE(RegWrite1_MEMWB),
		.ALU_result_async1(ALU_result_async1),
		.ALU_result_async_valid1(ALU_result_async_valid1)
`endif
	);
	
`ifdef HAS_FORWARDING
    assign BypassReg1_EXEID = WriteRegister1_PhysReg_EXE;
    assign BypassData1_EXEID = ALU_result_async1;
    assign BypassValid1_EXEID = ALU_result_async_valid1;
`endif
    //note to self: DO NOT TOUCH THIS
    wire [31:0] data_write_2DC/*verilator public*/;
    wire [31:0] data_address_2DC/*verilator public*/;
    wire [1:0]  data_write_size_2DC/*verilator public*/;
    wire [31:0] data_read_fDC/*verilator public*/;
    wire        read_2DC/*verilator public*/;
    wire        write_2DC/*verilator public*/;
    //No caches, so:
    /* verilator lint_off UNUSED */
    wire        flush_2DC/*verilator public*/;
    /* verilator lint_on UNUSED */
    wire        data_valid_fDC /*verilator public*/;
`ifdef USE_DCACHE
    Cache #(
    .CACHENAME("D$1")
    ) DCache(
        .CLK(CLK),
        .RESET(RESET),
        .Read1(read_2DC),
        .Write1(write_2DC),
        .Flush1(flush_2DC),
        .Address1(data_address_2DC),
        .WriteData1(data_write_2DC),
        .WriteSize1(data_write_size_2DC),
        .ReadData1(data_read_fDC),
        .OperationAccepted1(data_valid_fDC),
/* verilator lint_off PINCONNECTEMPTY */
        .ReadData2(),
        .DataValid2(),
/* verilator lint_on PINCONNECTEMPTY */
        .read_2DM(dBlkRead),
        .write_2DM(dBlkWrite),
        .address_2DM(data_address_2DM),
        .data_2DM(block_write_2DM),
        .data_fDM(block_read_fDM),
        .dm_operation_accepted((dBlkRead & block_read_fDM_valid) | (dBlkWrite & block_write_fDM_valid))
    );
    assign MemRead_2DM = 1'b0;
    assign MemWrite_2DM = 1'b0;
    assign data_write_2DM = 32'd0;
    assign data_write_size_2DM = 2'b0;
    /*verilator lint_off UNUSED*/
    wire [31:0] unused_d1;
    /*verilator lint_on UNUSED*/
    assign unused_d1 = data_read_fDM;
`else
    assign data_write_2DM = data_write_2DC;
    assign data_address_2DM = data_address_2DC;
    assign data_write_size_2DM = data_write_size_2DC;
    assign data_read_fDC = data_read_fDM;
    assign MemRead_2DM = read_2DC;
    assign MemWrite_2DM = write_2DC;
    assign data_valid_fDC = 1'b1;
     
    assign dBlkRead = 1'b0;
    assign dBlkWrite = 1'b0;
    assign block_write_2DM = block_read_fDM;
    /*verilator lint_off UNUSED*/
    wire unused_d1;
    wire unused_d2;
    /*verilator lint_on UNUSED*/
    assign unused_d1 = block_read_fDM_valid;
    assign unused_d2 = block_write_fDM_valid;
`endif
     //wires associated with the LSQ
	 wire memInstr_toLSQ_fRENAME;
	 assign memInstr_toLSQ_fRENAME = MemWrite1_RENAME || MemRead1_RENAME;
	 wire memAddressCalulated ;
	 assign memAddressCalulated = MemRead1_EXE_LSQ || MemWrite1_EXE_LSQ;
	 wire LSQposition_toISSUEQ;
	 wire modifiedLSQFLUSH; //needs to be connected to ROB
	 wire headStore; // needs to be connected to ROB
	 wire[3:0] LSQdest; // needs to be connected to EXE
	 wire[31:0] address_toMEM_fLSQ;	//must connect
	 wire[31:0] data_toMEM_fLSQ;	//must connect
	 wire[31:0] PC_toMEM_fLSQ;		//must connect
	 wire[31:0] instr_toMEM_fLSQ;	//must connect
	 wire[5:0] ALUcntrl_toMEM_fLSQ;	//must connect
	LoadStoreQ LoadStoreQ(
		.CLK(CLK),
		.RESET(WIPE),
		.FLUSH_IN(FLUSH_fROB),
		.FLUSH_SAVE(modifiedLSQFLUSH),			//for when there is a mem instruction at the head of the ROB and we're flushing because of a branch misprediction (not because of a syscall) -- from ROB
		.newEntry(memInstr_toLSQ_fRENAME),			//do we want a new entry in the LSQ this cycle	-- from rename 
		.newReady(headStore),			//did a store just reach the head of the ROB?	-- from ROB
		.addressEntry(memAddressCalulated),		//was a mem address just calculated? -- from EXE
		.address_IN(ALU_result1_EXE),			//what is the mem address that was calculated? -- from EXE
		.data_IN(MemWriteData1_EXE_LSQ),				//data to write to mem to be stored in the LSQ -- from EXE
		.memWrite(MemWrite1_RENAME),			//is this a store instr? -- from rename
		.writePosition(LSQdest),		//position in the LSQ associated with the calculated address  -- from EXE
		.Q_position(LSQposition_toISSUEQ),			//where we placed the new entry -- to ISSUE Q
		.address_OUT(address_toMEM_fLSQ),			//mem address for a memRequest -- to MEM
		.data_OUT(data_toMEM_fLSQ),			//data to write to mem for the memRequest -- to MEM
		.memRequest(LSQ_Issue),			//SEPARATE for READ/WRITE do we want to request a read/write from MEM -- to MEM
		.PC_IN(Instr1_PC_RENAME_ISSUEQ),				//PC of the new entry -- from rename
		.PC_OUT(PC_toMEM_fLSQ),                //PC of the leaving entry -- to MEM
		.instr_IN(Instr1_RENAME_ISSUEQ),			//the instr of the new entry -- from rename
		.instr_OUT(instr_toMEM_fLSQ),			//the instr of the leaving entry -- to MEM
		.ALUcntrl_IN(ALU_Control1_FIFO_RENAME),			//the ALU control of the new entry -- from rename
		.ALUcntrl_OUT(ALUcntrl_toMEM_fLSQ),		//the ALU control of the leaving entry -- to MEM
		.LS_FULL(STALL_fLSQ)				//LSQ full so stall -- to rename
	);
    
	wire 		STALL_fMEM;
	
    MEM MEM(
        .CLK(CLK),
        .RESET(WIPE),
        .Instr1_IN(Instr1_EXEMEM),
        .Instr1_PC_IN(Instr1_PC_EXEMEM),
        .ALU_result1_IN(ALU_result1_EXEMEM),
        .WriteRegister1_IN(WriteRegister1_EXEMEM),
        .MemWriteData1_IN(MemWriteData1_EXEMEM),
        .RegWrite1_IN(RegWrite1_EXEMEM),
        .ALU_Control1_IN(ALU_Control1_EXEMEM),
        .MemRead1_IN(MemRead1_EXEMEM),
        .MemWrite1_IN(MemWrite1_EXEMEM),
        .WriteRegister1_OUT(WriteRegister1_MEMWB),
        .RegWrite1_OUT(RegWrite1_MEMWB),
        .WriteData1_OUT(WriteData1_MEMWB),
        .data_write_2DM(data_write_2DC),
        .data_address_2DM(data_address_2DC),
        .data_write_size_2DM(data_write_size_2DC),
        .data_read_fDM(data_read_fDC),
        .MemRead_2DM(read_2DC),
        .MemWrite_2DM(write_2DC)
`ifdef USE_DCACHE
        ,
        .MemFlush_2DM(flush_2DC),
        .data_valid_fDM(data_valid_fDC),
        .Mem_Needs_Stall(STALL_fMEM)
`endif
`ifdef HAS_FORWARDING
        ,
        .WriteData1_async(BypassData1_MEMID)
`endif
    );
     
`ifdef HAS_FORWARDING
    assign BypassReg1_MEMID = WriteRegister1_EXEMEM;
`ifdef USE_DCACHE
    assign BypassValid1_MEMID = RegWrite1_EXEMEM && !STALL_fMEM;
`else
    assign BypassValid1_MEMID = RegWrite1_EXEMEM;
`endif
`endif
    
`ifdef OUT_OF_ORDER
	wire STALL_fROB;
	wire FLUSH_fROB;

    RetireCommit #(
		.NUM_PHYS_REGS(64)
	)RetireCommit(
	.CLK(CLK),
	.RESET(RESET),
	.renameStalling(RENAME_STALL),		//is Rename trying to make an entry to the ROB this cycle?	-- from Rename
	.regWrite(RegWrite1_RENAME_ISSUEQ),			//does this cycle's ROB entry write to a register? -- from Rename
	.archRegWrite(WriteRegister1_RENAME_ROB),		//arch reg that this cycle's ROB entry wants to write to -- from Rename
	.physRegWrite(WriteRegister1Pointer_RENAME_ISSUEQ),		//phys reg that this cycle's ROB entry wants to write to -- from Rename
	.instrPC_IN(Instr1_PC_RENAME_ISSUEQ),			//PC of this cycle's ROB entry -- From Rename
	.ready(),				//from MEM
	.destinationReady(),	//from MEM
	.RRAT_to_FRAT(RRAT_to_FRAT1),		//a copy of the RRAT sent to the FRAT in case of flushes -- to Rename
	.rAltPC_toROB(Request_Alt_PC_EXE_ROB),		//request_Alt_PC to be stored in the ROB -- from EXE?
	.Alt_PC_Position1(),	//from EXE
	.AltPC_toROB(Alt_PC_EXE_ROB),			//Alt_PC to be stored in the ROB -- from EXE?
	.rAltPC_toIF(Request_Alt_PC_ROB_IF),			//request_Alt_PC sent to IF to get back on course -- to IF?
	.AltPC_toIF(Alt_PC_ROB_IF),			//Alt_PC sent to IF to get back on course -- to IF?
	.ROBposition1(ROB_index_ROB_ISSUEQ),	
	.sys1(SYS_RENAME_ROB),
	.store(MemWrite1_RENAME),
	.load(MemRead1_RENAME),	
	.ROB_FULL(STALL_fROB),			//ROB is full so stall -- to Rename?
    .FLUSH(FLUSH_fROB)				//Something went wrong so flush the pipeline -- to everywhere?
    );
	

`endif
endmodule
