/**
NOTES:

example: add R1<- R2, R3

Metadata include the following:
	Instr, (yes)
	OperandB1(for immediates addi, lui, etc), 
	ReadRegisterA1, (R2)
	ReadRegisterB1, (R3)
	WriteRegister1, (R1)
	RegWrite, (1/0 defined by the type of instr)
	ALU_Control1, ("add")
	MemRead1, (loads)
	MemWrite1, (stores)
	Shift Amount, (sll,srl an immediate value)
	
	------------------------------------------------------------------------------
	I-type (whether or not this instruction uses an immediate) (???)
	
	ID outputs SYS and WANT_FREEZE.  What to do with those?
**/


module ID_RENAME_FIFO(
	input CLK,
	input RESET,
	input [31:0] PC_IN,
	//input [1000:0] metadata_IN,
	input [31:0] Instr_IN,
	input [31:0] OperandB_IN, //sign-extended value of the immediate for I-type instr such as addi, subi, etc
	input [4:0] ReadRegisterA1_IN, //operand source register 1
	input [4:0] ReadRegisterB1_IN, //operand source register 2
	input [4:0] WriteRegister1_IN, //destination register to write into
	input RegWrite_IN, //do we write to register?
	input [5:0] ALU_Control1_IN,
	input MemRead1_IN, //signal is high for load instrs
	input MemWrite1_IN, //signal is high for store instrs
	input [4:0] ShiftAmount1_IN, //used for sll,srl instrs
	input 		Jump_IN,
	input 		JumpRegister_IN,
	input ALUSrc_IN,
	input SYS_IN,
	
	output reg [31:0] PC_OUT,
	//output reg [1000:0] metadata_OUT,
	output reg [31:0] Instr_OUT,
	output reg [31:0] OperandB_OUT, //sign-extended value of the immediate for I-type instr such as addi, subi, etc
	output reg [4:0] ReadRegisterA1_OUT, //operand source register 1
	output reg [4:0] ReadRegisterB1_OUT, //operand source register 2
	output reg [4:0] WriteRegister1_OUT, //destination register to write into
	output reg RegWrite_OUT, //do we write to register?
	output reg [5:0] ALU_Control1_OUT,
	output reg MemRead1_OUT, //signal is high for load instrs
	output reg MemWrite1_OUT, //signal is high for store instrs
	output reg [4:0] ShiftAmount1_OUT, //used for sll,srl instrs
	output reg 		Jump_OUT,
	output reg 		JumpRegister_OUT,
	output reg 		ALUSrc_OUT,
	output reg		SYS_OUT,
	

	input STALL_ID_IN,
	output STALL_forRENAME, //this stalls when the queue is empty and cannot take something out
	output STALL_forID, //this stalls when the queue is full and cannot accept something in
	input STALL_RENAME_IN

);

reg [2:0] head;
reg [2:0] tail;
reg [31:0]		PC_Queue  		[7:0]; 
//reg [1000:0]		Metadata_Queue	[7:0];
reg [31:0] Instr_Queue [7:0];
reg [31:0] OperandB_Queue [7:0];
reg [4:0] ReadRegisterA1_Queue [7:0];
reg [4:0] ReadRegisterB1_Queue [7:0]; 
reg [4:0] WriteRegister1_Queue [7:0]; 
reg RegWrite_Queue [7:0]; 
reg [5:0] ALU_Control1_Queue [7:0];
reg MemRead1_Queue [7:0]; 
reg MemWrite1_Queue [7:0]; 
reg [4:0] ShiftAmount1_Queue [7:0];
reg Jump_Queue [7:0];
reg JumpRegister_Queue [7:0];
reg ALUSrc_Queue [7:0];
reg SYS_Queue [7:0];


wire empty;
wire full;
reg swap; //wire or reg?
integer i;
//assigns

assign empty = (head == tail && !swap)?1:0;
assign full = (head == tail && swap)?1:0;

//always @ blocks
always@(PC_IN) begin
	if(!STALL_ID_IN && !STALL_RENAME_IN) begin
		assign STALL_forID = 0;
		assign STALL_forRENAME = 0;
		if (empty) begin //do i need to move head and tail pointers???
			assign PC_OUT = PC_IN;
			//assign Metadata_OUT = Metadata_IN;
			assign Instr_OUT = Instr_IN;
			assign OperandB_OUT = OperandB_IN;
			assign ReadRegisterA1_OUT = ReadRegisterA1_IN;
			assign ReadRegisterB1_OUT = ReadRegisterB1_IN;
			assign WriteRegister1_OUT = WriteRegister1_IN;
			assign RegWrite_OUT = RegWrite_IN;
			assign ALU_Control1_OUT = ALU_Control1_IN;
			assign MemRead1_OUT = MemRead1_IN;
			assign MemWrite1_OUT = MemWrite1_IN;
			assign ShiftAmount1_OUT = ShiftAmount1_IN;

		end else begin //normal execution
			//take something out of queue
			assign PC_OUT = PC_Queue[head];
			//assign Metadata_OUT = Metadata_Queue[head];
			assign Instr_OUT = Instr_Queue [head];
			assign OperandB_OUT = OperandB_Queue [head];
			assign ReadRegisterA1_OUT = ReadRegisterA1_Queue [head];
			assign ReadRegisterB1_OUT = ReadRegisterB1_Queue [head]; 
			assign WriteRegister1_OUT = WriteRegister1_Queue [head]; 
			assign RegWrite_OUT = RegWrite_Queue [head]; 
			assign ALU_Control1_OUT = ALU_Control1_Queue [head];
			assign MemRead1_OUT = MemRead1_Queue [head]; 
			assign MemWrite1_OUT = MemWrite1_Queue [head];
			assign ShiftAmount1_OUT = ShiftAmount1_Queue [head];
			
			//put something into the queue (this probably goes into @posedge block)
			assign PC_Queue[tail] = PC_IN;
			//assign Metadata_Queue[tail] = Metadata_IN;
			assign Instr_Queue [tail] = Instr_IN;
			assign OperandB_Queue [tail] = OperandB_IN;
			assign ReadRegisterA1_Queue [tail] = ReadRegisterA1_IN;
			assign ReadRegisterB1_Queue [tail] = ReadRegisterB1_IN; 
			assign WriteRegister1_Queue [tail] = WriteRegister1_IN; 
			assign RegWrite_Queue [tail] = RegWrite_IN; 
			assign ALU_Control1_Queue [tail] = ALU_Control1_IN;
			assign MemRead1_Queue [tail] = MemRead1_IN; 
			assign MemWrite1_Queue [tail] = MemWrite1_IN; 
			assign ShiftAmount1_Queue [tail] = ShiftAmount1_IN;

		end
	end

	if(!STALL_ID_IN && STALL_RENAME_IN) begin
		if (full) begin
			assign STALL_forID = 1;
			assign STALL_forRENAME = 0;
		end else begin
			assign STALL_forID = 0;
			assign STALL_forRENAME = 0;

			//put something into the queue (this probably goes into @posedge block)
			assign PC_Queue[tail] = PC_IN;
			//assign Metadata_Queue[tail] = Metadata_IN;
			assign Instr_Queue [tail] = Instr_IN;
			assign OperandB_Queue [tail] = OperandB_IN;
			assign ReadRegisterA1_Queue [tail] = ReadRegisterA1_IN;
			assign ReadRegisterB1_Queue [tail] = ReadRegisterB1_IN; 
			assign WriteRegister1_Queue [tail] = WriteRegister1_IN; 
			assign RegWrite_Queue [tail] = RegWrite_IN; 
			assign ALU_Control1_Queue [tail] = ALU_Control1_IN;
			assign MemRead1_Queue [tail] = MemRead1_IN; 
			assign MemWrite1_Queue [tail] = MemWrite1_IN; 
			assign ShiftAmount1_Queue [tail] = ShiftAmount1_IN;


		end
	end

	if(STALL_ID_IN && !STALL_RENAME_IN) begin
		if (empty) begin
			assign STALL_forID = 0;
			assign STALL_forRENAME = 1;
		end else begin
			assign STALL_forID = 0;
			assign STALL_forRENAME = 0;
			//take something out of queue
			assign PC_OUT = PC_Queue[head];
			//assign Metadata_OUT = Metadata_Queue[head];
			assign Instr_OUT = Instr_Queue [head];
			assign OperandB_OUT = OperandB_Queue [head];
			assign ReadRegisterA1_OUT = ReadRegisterA1_Queue [head];
			assign ReadRegisterB1_OUT = ReadRegisterB1_Queue [head]; 
			assign WriteRegister1_OUT = WriteRegister1_Queue [head]; 
			assign RegWrite_OUT = RegWrite_Queue [head]; 
			assign ALU_Control1_OUT = ALU_Control1_Queue [head];
			assign MemRead1_OUT = MemRead1_Queue [head]; 
			assign MemWrite1_OUT = MemWrite1_Queue [head];
			assign ShiftAmount1_OUT = ShiftAmount1_Queue [head];			

		end
	end

	if(STALL_ID_IN && STALL_RENAME_IN) begin
		assign STALL_forID = 1;
		assign STALL_forRENAME = 1;
		//both prev and next stage stalled, do nothing
	end

end

always@(posedge CLK or negedge RESET) begin
	if(!RESET) begin
		head <= 3'b0;
		tail <= 3'b0;
/* 		for (i = 0; i<= 7; i++) begin
			PC_Queue[i] <= 32'b0;
			//Metadata_Queue[i] <= 1000b'0;			

			Instr_Queue [i] <= 32'b0;
			OperandB_Queue [i] <= 32'b0;
			ReadRegisterA1_Queue [i] <= 5'b0;
			ReadRegisterB1_Queue [i] <= 5'b0; 
			WriteRegister1_Queue [i] <= 5'b0; 
			RegWrite_Queue [i] <= 0; 
			ALU_Control1_Queue [i] <= 6'b0;
			MemRead1_Queue [i] <= 0; 
			MemWrite1_Queue [i] <= 0; 
			ShiftAmount1_Queue [i] <= 5'b0;


		end */
	end else if (CLK) begin 
		if(!STALL_ID_IN && !STALL_RENAME_IN) begin //normal execution
			if (empty) begin //include First Word Fall Through
				$display("QUEUE: queue was empty, something was put in queue and immediately taken out.");
			end
			else begin
				//update head of queue
				if (head == 3'b111) begin
					head <= 3'b000;
					swap <= !swap;
				end else begin
					head <= head + 1;
				end
				//update the tail of the queue
				if (tail == 3'b111) begin
					tail <= 3'b000;
					swap <= !swap;
				end else begin
					tail <= tail + 1;
				end
				$display("QUEUE: Instruction PC %x was taken out.  Instruction PC %x was put in.", PC_OUT, PC_IN);
			end
		end
		
		if(!STALL_ID_IN && STALL_RENAME_IN) begin //evaluate full, if not, put in, else do nothing
			//$display("QUEUE: XXXX.");
			//update the tail of the queue
				if (tail == 3'b111) begin
					tail <= 3'b000;
					swap <= !swap;
				end else begin
					tail <= tail + 1;
				end
		end
		
		if(STALL_ID_IN && !STALL_RENAME_IN) begin //evaluate empty, if not, take out, else do nothing
			//$display("QUEUE: XXXX.");
						//update head of queue
				if (head == 3'b111) begin
					head <= 3'b000;
					swap <= !swap;
				end else begin
					head <= head + 1;
				end
		end
		
		if(STALL_ID_IN && STALL_RENAME_IN) begin //stall
			$display("QUEUE: both stages on either side have stalled.");
		end
	end
end

endmodule