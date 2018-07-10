`include "config.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:17:07 10/18/2013 
// Design Name: 
// Module Name:    MEM2 
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
module MEM(
    input CLK,
    input RESET,
    //Currently executing instruction [debug only]
    input [31:0] Instr1_IN,
    //PC of executing instruction [debug only]
    input [31:0] Instr1_PC_IN,
    //Output of ALU (contains address to access, or data enroute to writeback)
    input [31:0] ALU_result1_IN,
    //What register will get our ultimate outputs
    input [4:0] WriteRegister1_IN,
    //What data gets written to memory
    input [31:0] MemWriteData1_IN,
    //This instruction is a register write?
    input RegWrite1_IN,
    //ALU control value (used to also specify the type of memory operation)
    input [5:0] ALU_Control1_IN,
    //The instruction requests a load
    input MemRead1_IN,
    //The instruction requests a store
    input MemWrite1_IN,
    //What register we are writing to
    output reg [4:0] WriteRegister1_OUT,
    //Actually do the write
    output reg RegWrite1_OUT,
    //And what data
    output reg [31:0] WriteData1_OUT, //also used for nonlive bypassing to EXE
    output reg [31:0] data_write_2DM,
	//Contains the virtual address that the DM will start reading/writing at
    output [31:0] data_address_2DM,
	//How many bytes to read/write 
	output reg [1:0] data_write_size_2DM,
	//What is read from DM
    input [31:0] data_read_fDM,
	//Signals to DM for read from DM and write to DM
	output MemRead_2DM,
	output MemWrite_2DM,
	output [31:0] WriteData1_async

    );
	
	wire [31:0] MemoryData1;	//Used for LWL, LWR (existing content in register) and for writing (data to write)
	wire [31:0] MemoryData;
	//wire [31:0] MemoryReadData;	//Data read in from memory (and merged appropriate if LWL, LWR)
	reg [31:0]	 data_read_aligned;
	
	//Word-aligned address for reads
    wire [31:0] MemReadAddress;
    //Not always word-aligned address for writes (SWR has issues with this)
    reg [31:0] MemWriteAddress;
	//reg [1:0] SWL_write_size;

	wire MemWrite;
	wire MemRead;
	wire [31:0] ALU_result;
	wire [5:0] ALU_Control;
	 
    assign MemWrite = MemWrite1_IN;
    assign MemRead = MemRead1_IN;
    assign ALU_result = ALU_result1_IN;
    assign ALU_Control = ALU_Control1_IN;
    assign MemoryData = MemoryData1;
	//Used for aligned reads so cut off the 2 LSBs to start at the beginning of a word
	assign MemReadAddress = {ALU_result[31:2],2'b00};
	assign data_address_2DM = MemWrite?MemWriteAddress:MemReadAddress;	//Reads are always aligned; writes may be unaligned
	assign MemRead_2DM = MemRead;
    assign MemWrite_2DM = MemWrite;
	//This signal reverses the values of ALU_result[1:0] from 1/2/3/0 to 3/2/1/0 for more complex instructions such as LWL,LWR,SWL,SWR
	//assign SWL_write_size = {(ALU_result[0] ^ ALU_result[1]),ALU_result[0]};
	 
    reg [31:0]WriteData1;

always @(data_read_fDM) begin
	//$display("MEM Received:data_read_fDM=%x",data_read_fDM);
	data_read_aligned = MemoryData;
	MemWriteAddress = ALU_result;
	//$display("MEM: Load or Store Instruction:MemWriteAddress = %x",MemWriteAddress);
	case(ALU_Control)
		//Register File contains bytes [A B C D]
		//Memory contains bytes        [W X Y Z]
		6'b101101: begin //LWL BELIEVED TO BE FIXED
			data_write_size_2DM = 0;
			case (ALU_result[1:0])
				2'b11: begin //Register File will contain [W B C D]
					data_read_aligned[31:24] = data_read_fDM[7:0];
					end
				2'b10: begin //Register File will contain [W X C D]
					data_read_aligned[31:16] = data_read_fDM[15:0];
					end
				2'b01: begin //Register File will contain [W X Y D]
					data_read_aligned[31:8] = data_read_fDM[23:0];
					end
				2'b00: begin //Register File will contain [W X Y Z]
					data_read_aligned = data_read_fDM[31:0];
					end
			endcase

		end
		6'b101110: begin //LWR BELIEVED TO BE FIXED
			data_write_size_2DM = 0;
			case (ALU_result[1:0])
				2'b11: begin //[W X Y Z]
					data_read_aligned = data_read_fDM[31:0];
					end
				2'b10: begin //[A X Y Z]
					data_read_aligned[23:0] = data_read_fDM[31:8];
					end
				2'b01: begin //[A B Y Z]
					data_read_aligned[15:0] = data_read_fDM[31:16]};
					end
				2'b00: begin //[A B C Z]
					data_read_aligned[7:0] = data_read_fDM[31:24]};
					end
			endcase
		end
		6'b100001: begin //LB case statements for which byte to take based on modulo of alu result
			case (ALU_result[1:0]) //CORRECT?
				2'b11: begin //[0 0 0 Z]
					data_read_aligned = {{24{data_read_fDM[7]}},{data_read_fDM[7:0]}};
					end
				2'b10: begin //[0 0 Y 0]
					data_read_aligned = {{24{data_read_fDM[15]}},{data_read_fDM[15:8]}};
					end
				2'b01: begin //[0 X 0 0]
					data_read_aligned = {{24{data_read_fDM[23]}},{data_read_fDM[23:16]}};
					end
				2'b00: begin //[W 0 0 0]
					data_read_aligned = {{24{data_read_fDM[31]}},{data_read_fDM[31:24]}};
					end
			endcase
			//data_read_aligned = {{24{data_read_fDM[7]}},data_read_fDM[7:0]};
			data_write_size_2DM=0;
		end
		6'b101011: begin //LH case statements for which byte to take based on modulo of alu result
			case (ALU_result[1:0])
				2'b11: begin //[0 0 0 Z]???? NOT SUPPOSED TO HAPPEN?
					end
				2'b10: begin //[0 0 Y Z]
					data_read_aligned = {{16{data_read_fDM[15]}},{data_read_fDM[15:0]}};
					end
				2'b01: begin //[0 X 0 0]???? NOT SUPPOSED TO HAPPEN?
					end
				2'b00: begin //[W X 0 0]
					data_read_aligned = {{16{data_read_fDM[31]}},{data_read_fDM{31:16}}};
					end
			endcase
			data_write_size_2DM=0;
		end
		6'b101010: begin //LBU case statements for which byte to take based on modulo of alu result
			case (ALU_result[1:0]) //correct?
				2'b11: begin //[0 0 0 Z]
					data_read_aligned = {{24{1'b0}},{data_read_fDM[7:0]}};
					end
				2'b10: begin //[0 0 Y 0]
					data_read_aligned = {{24{1'b0}},{data_read_fDM[15:8]}};
					end
				2'b01: begin //[0 X 0 0]
					data_read_aligned = {{24{1'b0}},{data_read_fDM[23:16]}};
					end
				2'b00: begin //[W 0 0 0]
					data_read_aligned = {{24{1'b0}},{data_read_fDM[31:24]}};
					end
			endcase
			data_write_size_2DM=0;
		end
		6'b101100: begin //LHU
			case (ALU_result[1:0])
				2'b11: begin //[0 0 0 Z]???? NOT SUPPOSED TO HAPPEN?
					end
				2'b10: begin //[0 0 Y Z]
					data_read_aligned = {{16{1'b0}},{data_read_fDM[15:0]}};
					end
				2'b01: begin //[0 X 0 0]???? NOT SUPPOSED TO HAPPEN?
					end
				2'b00: begin //[W X 0 0]
					data_read_aligned = {{16{1'b0}},{data_read_fDM[31:16]}};
					end
			endcase
			data_write_size_2DM=0;
		end
		6'b111101, 6'b101000, 6'd0, 6'b110101: begin	//LW, LL, NOP, LWC1
			data_read_aligned = data_read_fDM;
			data_write_size_2DM=0;
		end
		//Register File contains bytes [A B C D]
		//Memory contains bytes        [W X Y Z]
		6'b101111: begin	//SB
			data_write_size_2DM=1;
			data_write_2DM[7:0] = MemoryData [7:0];
		end
		6'b110000: begin	//SH
			data_write_size_2DM=2;
			data_write_2DM[15:0] = MemoryData[15:0];
		end
		6'b110001, 6'b110110: begin	//SW/SC
			data_write_size_2DM=0;
			data_write_2DM = MemoryData;
		end
		6'b110010: begin	//SWL BELIEVED TO BE FIXED
			MemWriteAddress = ALU_result;
			case (ALU_result[1:0])
				2'b11: begin
					data_write_2DM[7:0] = MemoryData[31:24];
					data_write_size_2DM = 1;
				end
				2'b10: begin
					data_write_2DM[15:0] = MemoryData[31:16];
					data_write_size_2DM = 2;
				end
				2'b01: begin
					data_write_2DM[23:0] = MemoryData[31:8]};
					data_write_size_2DM = 3;
				end
				2'b00: begin
					data_write_2DM = MemoryData[31:0];
					data_write_size_2DM = 0;
				end
			endcase
		end
		6'b110011: begin	//SWR BELIEVED TO BE FIXED
			MemWriteAddress = MemReadAddress;
			case (ALU_result[1:0])
				2'b11: begin
					data_write_2DM = MemoryData;
					data_write_size_2DM = 0;
					end
				2'b10: begin
					data_write_2DM[23:0] = MemoryData[23:0];
					data_write_size_2DM = 3;
					end
				2'b01: begin
					data_write_2DM[15:0] = MemoryData[15:0];
					data_write_size_2DM = 2;
					end
				2'b00: begin
					data_write_2DM[7:0] = MemoryData[7:0];
					data_write_size_2DM = 1;
					end
			endcase			
		end
		default: begin
			//If it's not a real memory instruction,
			//write what was retrieved from $rt into $rt so nothing should change
			//correctly implemented??
			data_read_aligned = data_read_fDM;
			data_write_size_2DM=0;
		end
	endcase
	//If you asked DM to read, then it is a store or load, else, just take the ALU_result and writeback
    WriteData1 = MemRead1_IN?data_read_aligned:ALU_result1_IN;
end

//Note that this takes the same combinational logic as WriteData1 above.  This signal will not require a clock cycle to get driven.
//This signal will rush to ID for branch and compare instructions to resolve in time.
assign MemoryData1 = ((WriteRegister1_IN == WriteRegister1_OUT) && RegWrite1_OUT)?MemWriteData1_IN : WriteData1_OUT;
	 
	 /* verilator lint_off UNUSED */
	 reg [31:0] Instr1_OUT;
	 reg [31:0] Instr1_PC_OUT;
     /* verilator lint_on UNUSED */

always @(posedge CLK or negedge RESET) begin
	if(!RESET) begin
		Instr1_OUT <= 0;
		Instr1_PC_OUT <= 0;
		WriteRegister1_OUT <= 0;
		RegWrite1_OUT <= 0;
		WriteData1_OUT <= 0;
		$display("MEM:RESET");
	end else if(CLK) begin //Once clock pulses, everything that is latched gets outputed and WB cycle receives these as inputs.
			Instr1_OUT <= Instr1_IN;
			Instr1_PC_OUT <= Instr1_PC_IN;
			WriteRegister1_OUT <= WriteRegister1_IN;
			RegWrite1_OUT <= RegWrite1_IN;
			WriteData1_OUT <= WriteData1;
			$display("MEM:Instr1=%x,Instr1_PC=%x,WriteData1=%x; Write?%d to %d",Instr1_IN,Instr1_PC_IN,WriteData1, RegWrite1_IN, WriteRegister1_IN);
			$display("MEM:data_address_2DM=%x; data_write_2DM(%d)=%x(%d); data_read_fDM(%d)=%x",data_address_2DM,MemWrite_2DM,data_write_2DM,data_write_size_2DM,MemRead_2DM,data_read_fDM);
	end
end

endmodule
