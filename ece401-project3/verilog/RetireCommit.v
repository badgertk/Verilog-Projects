/**************************************
* Module: RetireCommit
* Date:2013-12-10  
* Author: isaac     
*
* Description: Handles commits to the ROB, and retires instructions from the ROB.
*
* This is the last stop of this train. All passengers must exit.
***************************************/
`define LOG_PHYS    $clog2(NUM_PHYS_REGS)
module  RetireCommit #(
    parameter NUM_PHYS_REGS = 64
    /* You may want more parameters here */
)
(
	input CLK,
	input RESET,
	//add store inputs/outputs
	input renameStalling,
	input regWrite,
	input [4:0] archRegWrite,
	input [5:0] physRegWrite,
	input [31:0] instrPC_IN,
	input ready, 						//new
	input [5:0] destinationReady,
	output [5:0] RRAT_to_FRAT [31:0],
	input rAltPC_toROB,
	input [5:0] Alt_PC_Position1,		//new
	input [31:0] AltPC_toROB,
	output rAltPC_toIF,
	output [31:0] AltPC_toIF,
	output [5:0] ROBposition1,			//new
	input sys1,							//new
	input store,
	input load,
	
    output ROB_FULL,
    output FLUSH
);/*verilator public_module*/

reg FLUSH_ROB;

wire [4:0] writeArchReg;
wire 		write;
wire [5:0]	writePhysReg;


RAT #(
    .NUM_ARCH_REGS(35),
    .NUM_PHYS_REGS(NUM_PHYS_REGS)
    /* Maybe Others? */
)RRAT(
    .CLK(CLK),
    .RESET(RESET),
    .RegA1(),
    .RegB1(),
    .DataPointerA1(),//unneeded output
    .DataPointerB1(),//unneeded output
    .WriteReg1(writeArchReg), 
    .WriteDataPointer1(),//unneeded output
    .Write1(write),
    .nextFree(writePhysReg),
	.regRecover_IN(),
	.regRecover_OUT(RRAT_to_FRAT)
);

//stores
ROB #(
	.NUM_PHYS_REGS(NUM_PHYS_REGS)
)ROB1(
	.CLK(CLK),
	.RESET(RESET),
	.regWrite_IN(regWrite),
	.regWrite_OUT(write),
	.writeArchReg_IN(archRegWrite),
	.writeArchReg_OUT(writeArchReg),
	.writeRegPointer_IN(physRegWrite),
	.writeRegPointer_OUT(writePhysReg),
	.instructionPC_IN(instrPC_IN),
	.instructionPC_OUT(),
	.newExecuted(ready),
	.executedPosition(destinationReady),
	.Rename_STALL(renameStalling),
	.Request_Alt_PC_IN(rAltPC_toROB),
	.Alt_PC_Position(Alt_PC_Position1),	
	.Alt_PC_IN(AltPC_toROB),
	.Request_Alt_PC_OUT(rAltPC_toIF),
	.Alt_PC_OUT(AltPC_toIF),
	.ROBposition(ROBposition1),
    .store_IN(store),
	.load_IN(load),
	.sys_IN(sys1),					
	.FLUSH_IN(FLUSH_ROB),			
	.FLUSH_OUT(FLUSH),
	.ROB_STALL(ROB_FULL)
);

always @ (posedge CLK) begin
	FLUSH_ROB <= FLUSH; 
end

endmodule

