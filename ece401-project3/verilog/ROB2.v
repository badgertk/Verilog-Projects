//-----------------------------------------
//         		  ROB
//-----------------------------------------

`define LOG_ARCH    $clog2(NUM_ARCH_REGS)
`define LOG_PHYS    $clog2(NUM_PHYS_REGS)

module ROB #(
    parameter NUM_PHYS_REGS = 64
)
(
	input CLK,
	input RESET,
	
	input newEntry,
	//Does the instruction write a register?
	input regWrite_IN,
	output reg regWrite_OUT,
	//Architectural reg to write to
	input[4:0] writeArchReg_IN,
	output reg[4:0] writeArchReg_OUT,
	//Register of the phys register file to write
	input[5:0] writeRegPointer_IN,
	output reg [5:0] writeRegPointer_OUT,
	//instruction PC
	input[31:0] instructionPC_IN,
	output reg[31:0] instructionPC_OUT,
	//The PC of the instruction that has just been executed and can now be committed
	input[5:0] executedPosition,
	//will the Rename be providing a new entry this cycle?
	input Rename_STALL,
	//PC of the instruction that has just experienced an exception
	//input[5:0] exceptionPhysDestination,
	//Exception vector
	//input[5:0] exceptionVector,
	input Request_Alt_PC_IN,
	input [5:0] Alt_PC_position,
	input [31:0] Alt_PC_IN,
	output reg Request_Alt_PC_OUT,
	output reg [31:0] Alt_PC_OUT,
	output [5:0] ROBposition,
	
	input sys_IN,
	
	input FLUSH_IN,
	
	//FLUSH the pipeline
	output reg FLUSH_OUT,
	output reg ROB_STALL
);

reg[5:0] head;
reg[5:0] tail;

reg			regWrite	   [NUM_PHYS_REGS-1:0];
reg[5:0]	physRegPtrs	   [NUM_PHYS_REGS-1:0];
reg[4:0]	archReg		   [NUM_PHYS_REGS-1:0];
reg		    executed	   [NUM_PHYS_REGS-1:0];
//reg[5:0]	exceptions	   [NUM_PHYS_REGS-1:0];
reg[31:0]   PC			   [NUM_PHYS_REGS-1:0];
reg			request_Alt_PC [NUM_PHYS_REGS-1:0];
reg[31:0]   Alt_PC		   [NUM_PHYS_REGS-1:0];
reg			sysFlag		   [NUM_PHYS_REGS-1:0];

wire empty;
wire full;
reg swap;
integer i;

assign empty = (head == tail && !swap)?1:0;
assign full = (head == tail && swap)?1:0;

always @(posedge CLK or negedge RESET) begin
	if(!RESET) begin
		for(i = 0; i <= NUM_PHYS_REGS-1; i++) begin
			physRegPtrs[i] <= 0;
			archReg[i] <= 0;
			executed[i] <= 0;
			exceptions[i] <= 0;
			PC[i] <= 0;
			request_Alt_PC[i] <= 0;
			Alt_PC[i] <= 0;
		end
		swap <= 0;
		head <= 0;
		tail <= 0;
		FLUSH_OUT <= 0;
		ROB_STALL <= 0;
	end else if(CLK) begin
		if(FLUSH_IN) begin
			if(head == 6'b111111)begin
				tail <= 0;
				swap <= 1;
			end else begin
				tail <= head + 1;
				swap <= 0;
			end
			FLUSH_OUT <= 0;
			ROB_STALL <= 0;
		end else begin
			if(newExecuted) begin
				executed[executedPosition] <= 1;
			end
			//new ALt PC needed
			if(Request_Alt_PC_IN) begin
				request_Alt_PC[Alt_PC_position] <= 1;
				Alt_PC[Alt_PC_position] <= Alt_PC_IN;
			end
			if(sysFlag[head] == 1) begin
				if(executed[head] == 1) begin
					for(i = 0; i <= NUM_PHYS_REGS-1; i++) begin
						physRegPtrs[i] <= 0;
						archReg[i] <= 0;
						executed[i] <= 0;
						exceptions[i] <= 0;
						PC[i] <= 0;
						request_Alt_PC[i] <= 0;
						Alt_PC[i] <= 0;
					end
					swap <= 0;
					head <= 0;
					tail <= 0;
					FLUSH_OUT <= 1;
				end
			end else if (request_Alt_PC[head] == 1)begin
				FLUSH_OUT <= 1;
				Request_Alt_PC_OUT <= 1;
				Alt_PC_OUT <= Alt_PC[head];
				if(head == 6'd63) begin
					head <= 0;
					swap <= !swap;
				end else begin
					head <= head + 1;
				end
			end else if(executed[head] == 1) begin
				regWrite_OUT <= regWrite[head];
				writeArchReg_OUT <= archReg[head];
				writeRegPointer_OUT <= physRegPtrs[head];
				instructionPC_OUT <= PC[head];
				Request_Alt_PC_OUT <= 0;
				if(head == 6'd63) begin
					head <= 0;
					swap <= !swap;
				end else begin
					head <= head + 1;
				end
			end else begin
				regWrite_OUT <= 0;
				Request_Alt_PC_OUT <= 0;
			end
			if(!Rename_STALL) begin
				if(full) begin
					if(executed[head] == 1) begin
						regWrite[tail] <= regWrite_IN;
						physRegPtrs[tail] <= writeRegPointer_IN;
						archReg[tail] <= writeArchReg_IN;
						physReg
						PC[tail] <= instructionPC_IN;
						executed[tail] <= 0;
						request_Alt_PC[tail] <= 0;
						sysFlag[tail] <= sys_IN;
						ROBposition <= tail;
						ROB_FULL <= 0;
					end else begin
						ROB_FULL <= 1;
					end
				end
			end else begin
				ROB_FULL <= 0;
			end
		end
	end
end

endmodule

