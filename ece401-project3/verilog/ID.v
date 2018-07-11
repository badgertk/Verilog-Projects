`include "config.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:49:08 10/16/2013 
// Design Name: 
// Module Name:    ID2 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////


//TODO: Clean up
//All things regarding Register File must be removed.

module ID(
    input CLK,
    input RESET,
	//Instruction from Fetch
    input[31:0]Instr1_IN,
    //Instruction from Fetch is valid (set to 0 if we're waiting for some reason)
	 input STALL_forID,
	 input STALL_forID2,

	 //PC of instruction fetched
    input[31:0]Instr_PC_IN,
    //PC+4 of instruction fetched (needed for various things)
    input[31:0]Instr_PC_Plus4_IN,
    
    //Instruction being passed to EXE [debug]
     output reg [31:0]Instr1_OUT,
    //PC of instruction being passed to EXE [debug]
     output reg [31:0]Instr1_PC_OUT,
     //OperandB passed to EXE
    output reg [31:0]OperandB1_OUT, //only for immediate instr when ALUSrc1 = 1
     //RegisterA passed to EXE
    output reg [4:0]ReadRegisterA1_OUT,
     //RegisterB passed to EXE
    output reg [4:0]ReadRegisterB1_OUT,
     //Destination Register passed to EXE
    output reg [4:0]WriteRegister1_OUT,
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
	//Whether or not this is a jump instruction
	output reg Jump_OUT,
	//Whether or not this is a jump register instruction
	output reg JumpRegister_OUT,
	//Whether or not this is a syscall instruction
	 output reg SYS,
	 //Whether or not this instruction uses an immediate
	 output reg ALUSrc_OUT
	 
    );
	 
	 wire [5:0]	ALU_control1;	//async. ALU_Control output
	 wire			link1;			//whether this is a "And Link" instruction
	 wire			RegDst1;			//whether this instruction uses the "rd" register (Instr[15:11])
	 wire			jump1;			//whether we unconditionally jump
	 wire			branch1;			//whether we are branching
	 wire			MemRead1;		//whether this instruction is a load
	 wire			MemWrite1;		//whether this instruction is a store
	 wire			ALUSrc1;			//whether this instruction uses an immediate
	 wire			RegWrite1;		//whether we want to write to a register with this instruction (do_writeback)
	 wire			sign_or_zero_Flag1;	//If 1, we use sign-extended immediate; otherwise, 0-extended immediate.
	 wire			syscal1;			//If this instruction is a syscall
	 wire			comment1;
	 assign		comment1 = 1;
	 
	 wire [31:0]	OpB1;		//Operand B
	 
     wire [4:0]     rs1;     //also format1

     wire   [4:0]       rt1;
     wire [4:0]     rd1;
     wire [4:0]     shiftAmount1;
     wire [15:0]    immediate1;
	
	 
	 
     assign rs1 = Instr1_IN[25:21];
     assign rt1 = Instr1_IN[20:16];
     assign rd1 = Instr1_IN[15:11];
     assign shiftAmount1 = Instr1_IN[10:6];
     assign immediate1 = Instr1_IN[15:0];
	 
	 wire [31:0]    signExtended_immediate1;
     wire [31:0]    zeroExtended_immediate1;
     
     assign signExtended_immediate1 = {{16{immediate1[15]}},immediate1};
     assign zeroExtended_immediate1 = {{16{1'b0}},immediate1};
	 
	 wire ID_STALL;
	 assign ID_STALL = STALL_forID2 || STALL_forID;

/* //Begin branch/jump calculation this goes to EXEMEM
	
	wire [31:0] rsval_jump1;
	
	
`ifdef HAS_FORWARDING
RegValue3 RegJumpValue1 (
    .ReadRegister1(rs1), 
    .RegisterData1(rsRawVal1), 
    .WriteRegister1stPri1(BypassReg1_EXEID), 
    .WriteData1stPri1(BypassData1_EXEID),
	 .Valid1stPri1(BypassValid1_EXEID),
    .WriteRegister2ndPri1(BypassReg1_MEMID), 
    .WriteData2ndPri1(BypassData1_MEMID),
	 .Valid2ndPri1(BypassValid1_MEMID),
    .WriteRegister3rdPri1(WriteRegister1_IN), 
    .WriteData3rdPri1(WriteData1_IN),
	 .Valid3rdPri1(RegWrite1_IN),
    .Output1(rsval_jump1),
	 .comment(1'b0)
    );
`else
    assign rsval_jump1 = rsRawVal1;
`endif */

	wire [4:0] WriteRegister1;
	wire [4:0] RegA1;
	wire [4:0] RegB1;
	assign WriteRegister1 = RegDst1?rd1:(link1?5'd31:rt1); //okay
	//assign MemWriteData1 = Reg[WriteRegister1];		//What will be written by MEM
	assign RegA1 = link1?5'b00000:rs1;
	//When we branch/jump and link, OpB needs to store return address
	//Otherwise, if we have writeregister==rd, then rt is used for OpB.
	//if writeregister!=rd, then writeregister ==rt, and we use immediate instead.
	//not sure if accurate checks
	assign OpB1 = branch1?(link1?(Instr_PC_Plus4_IN+4):32'b0):(RegDst1?32'b0:(sign_or_zero_Flag1?signExtended_immediate1:zeroExtended_immediate1));  //the 32'b0 should never be selected anyway
	assign RegB1 = RegDst1?rt1:5'd0;
	 
always @(posedge CLK or negedge RESET) begin
	if(!RESET) begin
		Instr1_OUT <= 0;
		OperandB1_OUT <= 0;
		ReadRegisterA1_OUT <= 0;
		ReadRegisterB1_OUT <= 0;
		WriteRegister1_OUT <= 0;
		RegWrite1_OUT <= 0;
		ALU_Control1_OUT <= 0;
		MemRead1_OUT <= 0;
		MemWrite1_OUT <= 0;
		ShiftAmount1_OUT <= 0;
		Instr1_PC_OUT <= 0;
		SYS <= 0;
	$display("ID:RESET");
	end else if (CLK) begin
		if (!STALL_forID) begin
			//outputs <= something
			Instr1_PC_OUT <= Instr_PC_IN;
			Instr1_OUT <= Instr1_IN;
			OperandB1_OUT <= OpB1;
			ReadRegisterA1_OUT <= RegA1;
			ReadRegisterB1_OUT <=RegB1;
			WriteRegister1_OUT <=WriteRegister1;
			RegWrite1_OUT <= RegWrite1;
			ALU_Control1_OUT <= ALU_control1;
			MemRead1_OUT <= MemRead1;
			MemWrite1_OUT <= MemWrite1;
			ShiftAmount1_OUT <= shiftAmount1;
			Jump_OUT <= jump1;
			JumpRegister_OUT <= JumpRegister_OUT;
			SYS <= syscal1;
			ALUSrc_OUT <= ALUSrc1;
			
		end else begin
			//do nothing
		end
	end
end
	
	
	
	/* 
	end else begin
`ifdef USE_DCACHE
		if(STALL_fMEM) begin
			$display("ID[STALL_fMEM]:Instr1_OUT=%x,Instr1_PC_OUT=%x", Instr1_OUT, Instr1_PC_OUT);
		end else begin
`endif
`ifdef USE_ICACHE
            if (!STALL_fID) begin
		    $display("ID[FETCH_WAIT]");
            Instr1_OUT <= 0;
            OperandA1_OUT <= 0;
            OperandB1_OUT <= 0;
            ReadRegisterA1_OUT <= 0;
            ReadRegisterB1_OUT <= 0;
            WriteRegister1_OUT <= 0;
            MemWriteData1_OUT <= 0;
            RegWrite1_OUT <= 0;
            ALU_Control1_OUT <= 0;
            MemRead1_OUT <= 0;
            MemWrite1_OUT <= 0;
            ShiftAmount1_OUT <= 0;
			Instr1_PC_OUT <= 0;
		end else begin
`endif
			if(comment1) begin
				//enter $display statements here
			end
`ifdef USE_ICACHE
		end
`endif
`ifdef USE_DCACHE
		end
`endif
	end
end */
	
    Decoder #( //this stays 
    .TAG("1")
    )
    Decoder1 (
    .Instr(Instr1_IN), 
    .Instr_PC(Instr_PC_IN), 
    .Link(link1), 
    .RegDest(RegDst1), //this is an output
    .Jump(jump1), 
    .Branch(branch1), 
    .MemRead(MemRead1), 
    .MemWrite(MemWrite1), 
    .ALUSrc(ALUSrc1), 
    .RegWrite(RegWrite1), 
    .JumpRegister(JumpRegister_OUT), 
    .SignOrZero(sign_or_zero_Flag1), 
    .Syscall(syscal1), 
    .ALUControl(ALU_control1),
/* verilator lint_off PINCONNECTEMPTY */
    .MultRegAccess(),   //Needed for out-of-order
/* verilator lint_on PINCONNECTEMPTY */
     .comment1(1'b1)
    );

endmodule
