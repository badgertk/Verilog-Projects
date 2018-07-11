`include "config.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:09:45 10/18/2013 
// Design Name: 
// Module Name:    EXE2 
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
module EXE(
    input CLK,
    input RESET,
	
`ifdef USE_DCACHE
	//this signal goes on when a memory instruction is accessing the memory
	//either the head of rob is a memory instruction that is being committed
	//or data cache miss occurred.
	 input MEM_STALL,
	 input LSQ_STALL,
`endif
	 //Current instruction [debug]
    input [31:0] Instr1_IN,
    //Current instruction's PC [debug]
    input [31:0] Instr1_PC_IN,
`ifdef HAS_FORWARDING
    //Register A (needed for forwarding)
    input [5:0] RegisterA1_IN,
`endif
    //Operand A (if already known)
    input [31:0] OperandA1_IN,
`ifdef HAS_FORWARDING
    //Register B (needed for forwarding)
    input [5:0] RegisterB1_IN,
`endif
    //Operand B (if already known)
    input [31:0] OperandB1_IN,
    //Destination register
    input [5:0] WriteRegister1_IN,
    //Data in MemWrite1 register
    input [31:0] MemWriteData1_IN,
    //We do a register write
    input RegWrite1_IN,
    //ALU Control signal
    input [5:0] ALU_Control1_IN, //send to mem doesn't actually mean anything
    //We read from memory (passed to MEM)
    input MemRead1_IN, 
    //We write to memory (passed to MEM)
    input MemWrite1_IN,
    //Shift amount (needed for shift operations)
    input [4:0] ShiftAmount1_IN,
	//also generated from Decode, add metadata registers for these in previous stages
	input Jump_IN,
	input JumpRegister_IN,
	input [5:0] ROB_index_IN,
	input [3:0] LSQ_index_IN,
	
	//tying outputs correctly RESOLVED!
    //Instruction [debug] to MEM
    output reg [31:0] Instr1_OUT, //same is input
    //PC [debug] to MEM
    output reg [31:0] Instr1_PC_OUT, //same as input
    //Our ALU results to MEM and LSQ
    output reg [31:0] ALU_result1_OUT, //generated here
    //What register gets the data (or store from) to MEM
    output reg [5:0] WriteRegister1_OUT, //same as input	
    //Data in WriteRegister1 (if known) to MEM
    output reg [31:0] MemWriteData1_OUT, //resolved goes to lsq
    //Whether we will write to a register
    output reg RegWrite1_OUT, //same as input
    //ALU Control (actually used by MEM)
    output reg [5:0] ALU_Control1_OUT, //same as input
    //We need to read from MEM (passed to MEM)
    output reg MemRead1_OUT, //same as input, send to mem doesn't actually mean anything
    //We need to write to MEM (passed to MEM)
    output reg MemWrite1_OUT, //same as input, send to mem doesn't actually mean anything
	output reg Request_Alt_PC_OUT, //to ROB
	output reg [31:0] Alt_PC_OUT, //to ROB
	output reg [5:0] ROB_index_OUT, //to ROB
	output reg [3:0] LSQ_index_OUT, //to LSQ
	output EXE_STALL //this only gets sent to phys reg
	
`ifdef HAS_FORWARDING
    ,
        
    //Bypass inputs for calculations that have completed MEM
	 input[4:0] BypassReg1_MEMEXE,
	 input[31:0] BypassData1_MEMEXE,
	 input BypassValid1_MEMEXE,
	 
    //Bypass outputs for calculations that have completed EXE  ?????????
	 output [31:0] ALU_result_async1,
	 output ALU_result_async_valid1
`endif
    );
	 

	 wire [31:0] A1;
	 wire [31:0] B1;
	 wire[31:0]ALU_result1;
	
	 wire STALL;
	 assign STALL = LSQ_STALL &&  (MemRead1_IN || MemWrite1_IN ) || MEM_STALL && RegWrite1_IN;
	 
	 wire comment1;
	 assign comment1 = 1;
	 
`ifdef HAS_FORWARDING
RegValue2 RegAValue(
    .ReadRegister1(RegisterA1_IN), 
    .RegisterData1(OperandA1_IN), 
    .WriteRegister1stPri1(WriteRegister1_OUT), 
    .WriteData1stPri1(ALU_result1_OUT), 
    .Valid1stPri1(RegWrite1_OUT && !(MemRead1_OUT || MemWrite1_OUT)), 
    .WriteRegister2ndPri1(BypassReg1_MEMEXE), 
    .WriteData2ndPri1(BypassData1_MEMEXE),
    .Valid2ndPri1(BypassValid1_MEMEXE),
    .Output1(A1),
	 .comment(1'b0)
    );

RegValue2 RegBValue(
    .ReadRegister1(RegisterB1_IN), 
    .RegisterData1(OperandB1_IN), 
    .WriteRegister1stPri1(WriteRegister1_OUT), 
    .WriteData1stPri1(ALU_result1_OUT), 
    .Valid1stPri1(RegWrite1_OUT && !(MemRead1_OUT || MemWrite1_OUT)), 
    .WriteRegister2ndPri1(BypassReg1_MEMEXE), 
    .WriteData2ndPri1(BypassData1_MEMEXE),
    .Valid2ndPri1(BypassValid1_MEMEXE), 
    .Output1(B1),
	 .comment(1'b0)
    );
`else
assign A1 = OperandA1_IN;
assign B1 = OperandB1_IN;
`endif

reg [31:0] HI/*verilator public*/;
reg [31:0] LO/*verilator public*/;
wire [31:0] HI_new1;
wire [31:0] LO_new1;
wire [31:0] new_HI;
wire [31:0] new_LO;
wire [31:0] Alt_PC;
wire 		Request_Alt_PC;

assign new_HI=HI_new1;
assign new_LO=LO_new1;

//there are three separate ALUs running in parallel: ALU, NextInstrCalculator, and BranchCompare
//ALU is for standard ALU usage (R types and I types)
//NextInstrCalculator generates Alt_PC for jumps and branches
//BranchCompare generates Req_Alt_PC for jumps and branches

//all std instrs, use this
ALU ALU1( //this goes to Mem or Regfile WB
	//if br or jump, ALU result is garbage, goes to MEM
	//MEM recognizes memory instructions based on MemRead MemWrite
    .aluResult(ALU_result1),
    .HI_OUT(HI_new1),
    .LO_OUT(LO_new1),
    .HI_IN(HI),
    .LO_IN(LO),
    .A(A1), 
    .B(B1), 
    .ALU_control(ALU_Control1_IN), 
    .shiftAmount(ShiftAmount1_IN), 
    .CLK(!CLK)
    );

wire [31:0] Instr_PC_Plus4;
assign Instr_PC_Plus4 = Instr1_PC_IN + 32'd4;
//if jump or branch, use these two
NextInstructionCalculator NIA1 ( //generates Alt_PC signal...this goes to ROB
    .Instr_PC_Plus4(Instr_PC_Plus4),
    .Instruction(Instr1_IN), 
    .Jump(Jump_IN), //is this jump instr
    .JumpRegister(JumpRegister_IN), //is this jump register instr?
    .RegisterValue(OperandA1_IN), //jump register instr, need value in said register
    .NextInstructionAddress(Alt_PC), //alt pc calculation, if req_alt_pc = 0, this value is meaningless
	 .Register(RegisterA1_IN)
    );
	
	
compare branch_compare1 ( //generates Req_Alt_PC signal accommodates non taken branches and non branches in general... this goes to ROB
    .Jump(Jump_IN),
    .OpA(A1),
    .OpB(B1),
    .Instr_input(Instr1_IN), 
    .taken(Request_Alt_PC)
    );
	
	
//choose which of the three ALU output to take: not even necessary!

wire [31:0] MemWriteData1;

`ifdef HAS_FORWARDING
RegValue2 MemoryDataValue(
    .ReadRegister1(WriteRegister1_IN), 
    .RegisterData1(MemWriteData1_IN), 
    .WriteRegister1stPri1(WriteRegister1_OUT), 
    .WriteData1stPri1(ALU_result1_OUT), 
    .Valid1stPri1(RegWrite1_OUT && !(MemRead1_OUT || MemWrite1_OUT)), 
    .WriteRegister2ndPri1(BypassReg1_MEMEXE), 
    .WriteData2ndPri1(BypassData1_MEMEXE),
    .Valid2ndPri1(BypassValid1_MEMEXE), 
    .Output1(MemWriteData1),
	 .comment(1'b0)
    );

	assign ALU_result_async1 = ALU_result1;
	assign ALU_result_async_valid1 = RegWrite1_IN && !(MemRead1_IN || MemWrite1_IN);
`else
assign MemWriteData1 = MemWriteData1_IN;
`endif

always @(posedge CLK or negedge RESET) begin
	if(!RESET) begin
		Instr1_OUT <= 0;
		Instr1_PC_OUT <= 0;
		ALU_result1_OUT <= 0;
		WriteRegister1_OUT <= 0;
		MemWriteData1_OUT <= 0;
		RegWrite1_OUT <= 0;
		ALU_Control1_OUT <= 0;
		MemRead1_OUT <= 0;
		MemWrite1_OUT <= 0;
		Request_Alt_PC_OUT <= 0;
		Alt_PC_OUT <= 0;
		ROB_index_OUT <= 0;
		LSQ_index_OUT <= 
		EXE_STALL <= 0;
		$display("EXE:RESET");
	end else if(CLK) begin
       HI <= new_HI;
       LO <= new_LO;
`ifdef USE_DCACHE
		if(MEM_STALL) begin //replace with stall from LSQ
            $display("EXE[MEM_STALL]:Instr1_OUT=%x,Instr1_PC_OUT=%x", Instr1_OUT, Instr1_PC_OUT);
		end else if (LSQ_STALL) begin
			$display("EXE[LSQ_STALL]: ");
		end else begin
`endif
            Instr1_OUT <= Instr1_IN;
            Instr1_PC_OUT <= Instr1_PC_IN;
            ALU_result1_OUT <= ALU_result1;
            WriteRegister1_OUT <= WriteRegister1_IN;
            MemWriteData1_OUT <= MemWriteData1;
            RegWrite1_OUT <= RegWrite1_IN;
            ALU_Control1_OUT <= ALU_Control1_IN;
            MemRead1_OUT <= MemRead1_IN;
            MemWrite1_OUT <= MemWrite1_IN;
			Request_Alt_PC_OUT <= Request_Alt_PC;
			Alt_PC_OUT <= Alt_PC;
			ROB_index_OUT <= ROB_index_IN;
			LSQ_index_OUT <= LSQ_index_IN;
			EXE_STALL <= STALL; 
			
			if(comment1) begin
                $display("EXE:Instr1=%x,Instr1_PC=%x,ALU_result1=%x; Write?%d to %d",Instr1_IN,Instr1_PC_IN,ALU_result1, RegWrite1_IN, WriteRegister1_IN);
                //$display("EXE:ALU_Control1=%x; MemRead1=%d; MemWrite1=%d (Data:%x)",ALU_Control1_IN, MemRead1_IN, MemWrite1_IN, MemWriteData1);
                //$display("EXE:OpA1=%x; OpB1=%x; HI=%x; LO=%x", A1, B1, new_HI,new_LO);
			end
`ifdef USE_DCACHE
		end
`endif
	end
end

endmodule
