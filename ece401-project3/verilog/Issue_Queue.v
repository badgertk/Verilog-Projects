/**
NOTES:

Metadata include the following: (??)
	Instr, OperandA1, OperandB1, ReadRegisterA1, ReadRegisterB1, WriteRegister1, MemWriteData1, RegWrite, ALU_Control1, MemRead1, MemWrite1, ShiftAmount1
	
TODO:
	Handle Stall signals
**/


module Issue_Queue(
	input CLK,
	input RESET,

	input [31:0] PC_IN,
	//input [1000:0] metadata_IN,
	input [31:0] Instr_IN,
	input [31:0] Immediate_IN,
	input [5:0] dest_IN,
	input RegWrite_IN,
	input [5:0] ALU_Control_IN,
	input MemRead_IN,
	input MemWrite_IN,
	input [4:0] ShiftAmount_IN,
	input Jump_IN,
	input JumpRegister_IN,
	input ALUSrc_IN,
	input [5:0] ROB_index_IN,
	input [3:0] LSQ_index_IN,
	
	input [5:0] src1_IN,
	input 		busybit_src1_IN,
	input [5:0] src2_IN,
	input 		busybit_src2_IN,
	//and other things to be stored in metadata reg
	
	output reg [31:0] PC_OUT,
	//output reg [1000:0] metadata_OUT,
	output reg [31:0] Instr_OUT,
	output reg [31:0] Immediate_OUT,
	output reg 	RegWrite_OUT,
	output reg [5:0] ALU_Control_OUT,
	output reg MemRead_OUT,
	output reg MemWrite_OUT,
	output reg [4:0] ShiftAmount_OUT,
	output reg Jump_OUT,
	output reg JumpRegister_OUT,
	output reg ALUSrc_OUT,
	output reg [5:0] ROB_index_OUT,
	output reg [3:0] LSQ_index_OUT,
	
	output reg [5:0] src1_OUT,
	output reg [5:0] src2_OUT,
	output reg [5:0] dest_OUT,
	
	input Issue_IN,
	input [3:0] grant_select_index, //receive from Wakeup & Select AT THE BEGINNING OF CLOCK CYCLE
	output [15:0] issue_select_array, //to Wakeup & Select
	
	input Dispatch_IN,
	input [3:0] grant_vacancy_index, // select_vacancy tells you which slot in the issue queue is filled up with new instr
	output [15:0] issue_vacancy_array

	//stall signals on hold...
/* 	input STALL_??_IN,
	output STALL_fRENAME, //this stalls when the queue is empty and cannot take something out
	output STALL_f??, //this stalls when the queue is full and cannot accept something in
	input STALL_RENAME_IN */

);

reg				vacant			[15:0];
reg [31:0]		PC_Queue  		[15:0]; 

reg [5:0]		src1 [15:0]; //physical register for operand1
reg [5:0]		src2 [15:0]; //physical register for operand2
reg				src1_ready [15:0];
reg 			src2_ready [15:0];
reg				ready [15:0];

reg [5:0]		dest [15:0]; //physica register for destination
//reg [1000:0]	Metadata[15:0]; //placeholder
reg [31:0]		Instr_Queue [15:0];
reg [31:0]		Immediate_Queue [15:0];
reg				RegWrite_Queue [15:0];
reg [5:0]		ALU_Control_Queue [15:0];
reg				MemRead_Queue [15:0];
reg				MemWrite_Queue [15:0];
reg [4:0]		ShiftAmount_Queue [15:0];
reg 			Jump_Queue [15:0];
reg 			JumpRegister_Queue [15:0];
reg 			ALUSrc_Queue [15:0];
reg [5:0] 		ROB_index_Queue [15:0];
reg [3:0] 		LSQ_index_Queue [15:0];

wire Dispatch;
wire Issue;

integer i;
//assigns
assign Issue = Issue_IN;
assign Dispatch = Dispatch_IN;


always@(Issue or Dispatch) begin //maybe this is wrong?
	assign issue_select_array = ready;
	assign issue_vacancy_array = vacant;
end

always@(posedge CLK or negedge RESET) begin
	if (!RESET) begin
		for (i = 0; i<= 15; i++) begin
/* 			vacant[i] <= 1;
			PC_Queue[i] <= 32'b0;
			src1[i] <= 6'b0;
			src2[i] <= 6'b0;
			src1_ready[i] <= 0;
			src2_ready[i] <= 0;
			ready[i] <= 0;
			dest[i] <= 6'b0;
			Metadata[i] <= 1001'b0; */
		end

	end else if (CLK) begin
		//evaluate Issue and Dispatch
		for (i = 0; i<=15; i++) begin
			ready[i] <= src1_ready[i] & src2_ready[i];
		end
		
		if (Issue && Dispatch) begin
			if (RegWrite_Queue[grant_select_index] == 1) begin //look through everything in the queue
				for (i =0; i<= 15; i++) begin 
					if (src1[i] == dest[grant_select_index]) begin //first source matches destination reg on bus
						if (src1_ready[i] == 0) begin //was not ready, depended on this
							src1_ready[i] <= 1;
						end else begin //it was already ready, did not depend on instruction on broadcast
							// do nothing
						end
					end
					if (src2[i] == dest[grant_select_index]) begin //second source matches destination reg on bus
						if (src2_ready[i] == 0) begin //was not ready, depended on this
							src2_ready[i] <= 1;
						end else begin //it was already ready, did not depend on instruction on broadcast
							// do nothing
						end
					end
				end
			end

			//looked through everything, now move out regardless of no matches (meaning no dependencies)
			//take some more metadata out
			
			PC_OUT = PC_Queue[grant_select_index];
			src1_OUT = src1[grant_select_index];
			src2_OUT = src2[grant_select_index];
			dest_OUT = dest[grant_select_index];
			
			Instr_OUT = Instr_Queue [grant_select_index];
			Immediate_OUT = Immediate_Queue [grant_select_index];
			RegWrite_OUT = RegWrite_Queue [grant_select_index];
			ALU_Control_OUT = ALU_Control_Queue [grant_select_index];
			MemRead_OUT = MemRead_Queue [grant_select_index];
			MemWrite_OUT = MemWrite_Queue [grant_select_index];
			ShiftAmount_OUT = ShiftAmount_Queue [grant_select_index];
			Jump_OUT = Jump_Queue [grant_select_index];
			JumpRegister_OUT = JumpRegister_Queue [grant_select_index];
			ALUSrc_OUT <= ALUSrc_Queue [grant_select_index];
			ROB_index_OUT <= ROB_index_Queue [grant_select_index];
			LSQ_index_OUT <= LSQ_index_Queue [grant_select_index];
			//move everything right 15 -> empty slot
			for (i = grant_select_index; i<= 14; i++) begin
				PC_Queue[grant_select_index] <= PC_Queue[grant_select_index + 1];
				src1[grant_select_index] <= src1[grant_select_index + 1];
				src2[grant_select_index] <= src2[grant_select_index + 1];
				dest[grant_select_index] <= dest[grant_select_index + 1];
				//move metadata
				Instr_Queue [grant_select_index] <= Instr_Queue [grant_select_index + 1];
				Immediate_Queue [grant_select_index] <= Immediate_Queue [grant_select_index + 1];
				RegWrite_Queue [grant_select_index] <= RegWrite_Queue [grant_select_index + 1];
				ALU_Control_Queue [grant_select_index] <= ALU_Control_Queue [grant_select_index + 1];
				MemRead_Queue [grant_select_index] <= MemRead_Queue [grant_select_index + 1];
				MemWrite_Queue [grant_select_index] <= MemWrite_Queue [grant_select_index + 1];
				ShiftAmount_Queue [grant_select_index] <= ShiftAmount_Queue [grant_select_index + 1];
				Jump_Queue [grant_select_index] <= Jump_Queue [grant_select_index + 1];
				JumpRegister_Queue [grant_select_index] <= JumpRegister_Queue [grant_select_index + 1];
				ALUSrc_Queue [grant_select_index] <= ALUSrc_Queue [grant_select_index + 1];
				ROB_index_Queue [grant_select_index] <= ROB_index_Queue [grant_select_index + 1];
				LSQ_index_Queue [grant_select_index] <= LSQ_index_Queue [grant_select_index + 1];
			end
			vacant[15] <= 1;

			PC_Queue[grant_vacancy_index] <= PC_IN;
			src1[grant_vacancy_index] <= src1_IN;
			src2[grant_vacancy_index] <= src2_IN;
			src1_ready[grant_vacancy_index] <= busybit_src1_IN;
			src2_ready[grant_vacancy_index] <= busybit_src2_IN;
			//store some more metadata
			Instr_Queue [grant_vacancy_index] <= Instr_IN;
			Immediate_Queue [grant_vacancy_index] <= Immediate_IN;
			RegWrite_Queue [grant_vacancy_index] <= RegWrite_IN;
			ALU_Control_Queue [grant_vacancy_index] <= ALU_Control_IN;
			MemRead_Queue [grant_vacancy_index] <= MemRead_IN;
			MemWrite_Queue [grant_vacancy_index] <= MemWrite_IN;
			ShiftAmount_Queue [grant_vacancy_index] <= ShiftAmount_IN;
			Jump_Queue [grant_vacancy_index] <= Jump_IN;
			JumpRegister_Queue [grant_vacancy_index] <= JumpRegister_IN;
			ALUSrc_Queue [grant_vacancy_index] <= ALUSrc_IN;
			ROB_index_Queue [grant_vacancy_index] <= ROB_index_IN;
			LSQ_index_Queue [grant_vacancy_index] <= LSQ_index_IN;
			vacant[grant_vacancy_index] <= 0;

		end
		if (!Issue && Dispatch) begin
			if (RegWrite_Queue[grant_select_index] == 1) begin //look through everything in the queue
				for (i =0; i<= 15; i++) begin 
					if (src1[i] == dest[grant_select_index]) begin //first source matches destination reg on bus
						if (src1_ready[i] == 0) begin //was not ready, depended on this
							src1_ready[i] <= 1;
						end else begin //it was already ready, did not depend on instruction on broadcast
							// do nothing
						end
					end
					if (src2[i] == dest[grant_select_index]) begin //second source matches destination reg on bus
						if (src2_ready[i] == 0) begin //was not ready, depended on this
							src2_ready[i] <= 1;
						end else begin //it was already ready, did not depend on instruction on broadcast
							// do nothing
						end
					end
				end
			end
			//looked through everything, now move out regardless of no matches (meaning no dependencies)
			//take some more metadata out
			PC_OUT = PC_Queue[grant_select_index];
			src1_OUT = src1[grant_select_index];
			src2_OUT = src2[grant_select_index];
			dest_OUT = dest[grant_select_index];
			
			Instr_OUT = Instr_Queue [grant_select_index];
			Immediate_OUT = Immediate_Queue [grant_select_index];
			RegWrite_OUT = RegWrite_Queue [grant_select_index];
			ALU_Control_OUT = ALU_Control_Queue [grant_select_index];
			MemRead_OUT = MemRead_Queue [grant_select_index];
			MemWrite_OUT = MemWrite_Queue [grant_select_index];
			ShiftAmount_OUT = ShiftAmount_Queue [grant_select_index];
			Jump_OUT = Jump_Queue [grant_select_index];
			JumpRegister_OUT = JumpRegister_Queue [grant_select_index];
			ALUSrc_OUT <= ALUSrc_Queue [grant_select_index];
			ROB_index_OUT <= ROB_index_Queue [grant_select_index];
			LSQ_index_OUT <= LSQ_index_Queue [grant_select_index];
			//move everything right 15 -> empty slot
			for (i = grant_select_index; i<= 14; i++) begin
				PC_Queue[grant_select_index] <= PC_Queue[grant_select_index + 1];
				src1[grant_select_index] <= src1[grant_select_index + 1];
				src2[grant_select_index] <= src2[grant_select_index + 1];
				dest[grant_select_index] <= dest[grant_select_index + 1];
				//move metadata
				Instr_Queue [grant_select_index] <= Instr_Queue [grant_select_index + 1];
				Immediate_Queue [grant_select_index] <= Immediate_Queue [grant_select_index + 1];
				RegWrite_Queue [grant_select_index] <= RegWrite_Queue [grant_select_index + 1];
				ALU_Control_Queue [grant_select_index] <= ALU_Control_Queue [grant_select_index + 1];
				MemRead_Queue [grant_select_index] <= MemRead_Queue [grant_select_index + 1];
				MemWrite_Queue [grant_select_index] <= MemWrite_Queue [grant_select_index + 1];
				ShiftAmount_Queue [grant_select_index] <= ShiftAmount_Queue [grant_select_index + 1];
				Jump_Queue [grant_select_index] <= Jump_Queue [grant_select_index + 1];
				JumpRegister_Queue [grant_select_index] <= JumpRegister_Queue [grant_select_index + 1];
				ALUSrc_Queue [grant_select_index] <= ALUSrc_Queue [grant_select_index + 1];
				ROB_index_Queue [grant_select_index] <= ROB_index_Queue [grant_select_index + 1];
				LSQ_index_Queue [grant_select_index] <= LSQ_index_Queue [grant_select_index + 1];

			end
			vacant[grant_vacancy_index] <= 0;
		end
		if (Issue && !Dispatch) begin
			PC_Queue[grant_vacancy_index] <= PC_IN;
			src1[grant_vacancy_index] <= src1_IN;
			src2[grant_vacancy_index] <= src2_IN;
			src1_ready[grant_vacancy_index] <= busybit_src1_IN;
			src2_ready[grant_vacancy_index] <= busybit_src2_IN;
			//store some more metadata
			Instr_Queue [grant_vacancy_index] <= Instr_IN;
			Immediate_Queue [grant_vacancy_index] <= Immediate_IN;
			RegWrite_Queue [grant_vacancy_index] <= RegWrite_IN;
			ALU_Control_Queue [grant_vacancy_index] <= ALU_Control_IN;
			MemRead_Queue [grant_vacancy_index] <= MemRead_IN;
			MemWrite_Queue [grant_vacancy_index] <= MemWrite_IN;
			ShiftAmount_Queue [grant_vacancy_index] <= ShiftAmount_IN;
			Jump_Queue [grant_vacancy_index] <= Jump_IN;
			JumpRegister_Queue [grant_vacancy_index] <= JumpRegister_IN;
			ALUSrc_Queue [grant_vacancy_index] <= ALUSrc_IN;
			ROB_index_Queue [grant_vacancy_index] <= ROB_index_IN;
			LSQ_index_Queue [grant_vacancy_index] <= LSQ_index_IN;
			vacant[grant_vacancy_index] <= 0;

		end
		if (!Issue && !Dispatch) begin
			//do nothing
		end

	end

end

endmodule

