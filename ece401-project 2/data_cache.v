


module data_cache(
	input RESET,
	input CLK,
	input [31:0] Data_address_fMEM,
	input [31:0] Data_fDM,
/* 	//How many bytes to write:
		1 byte: 1
		2 bytes: 2
		3 bytes: 3
		4 bytes: 0 */
	input [1:0] data_write_size,
	//These two signals come from MEM.  Is it a MemRead instruction?  Is it a MemWrite instruction?
	input MemRead,
	input MemWrite,
	//This stall signal will go to ID which will stall stages EXE, ID, and IF
	output STALL,
	output reg [31:0] Data_2Processor,
	//This is used for writing back dirty bits when its block is evicted from the cache.
	output reg [255:0] Data_2DM, //[255:0]? output or output reg?
	output [31:0] Data_address_2DM
);
/*	32KB size
	2-way associative
	32B block size (holds 8 instructions)
	1 cycle
	10 cycles miss penalty
	write-back/write allocate
*/

wire [17:0] tag;
wire [9:0] index;
wire [9:0] effective_index;
wire [9:0] other_index;
wire [2:0] offset;
//Is one bit in this block dirty? If so, then it is set to 1.
reg [1023:0] dirtyblock;
reg [1023:0]validreg;
reg MRUreg [0:1023];
reg [17:0]		tagreg  [0:1023]; //register file full of tags
reg [255:0]		datareg [0:1023]; //register file full of data
//the data/instructions will be in the form of little endian [w0 w1 w2 w3 w4 w5 w6 w7]
wire [31:0] data1;
wire [31:0] data2;
//This will count down from 10(?) to 1
integer stall_count;
//Do we need to writeback any bytes?
wire writeback;

assign other_index = effective_index ^ 10'b1;

assign tag = Data_address_fMEM [31:14];
assign index = {Data_address_fMEM[13:5],1'b0};
assign offset = Data_address_fMEM[4:2];

always@ (Data_address_fMEM) begin 
	//$display("ENTER Data_address_fMEM BLOCK %x",Data_address_fMEM);
//=========================================================================
//=========================================================================
	if (MemRead == 1) begin //LOAD INSTRUCTIONS MEMREAD
		$display("LOAD INSTRUCTION RECEIVED, READING MEMORY");
		if ((tag == tagreg [index] || tag == tagreg[index+1]) && (stall_count <= 1) && ((validreg [index] || validreg[index+1]) == 1)) begin //hit
			$display("CACHE HIT FOR LOAD INSTRUCTION");
			assign STALL = 0;
			case (offset) //pick which block to give to processor
				3'b000: begin
					assign data1 = datareg[index][255:224];
					assign data2 = datareg[index+1][255:224];
				end
				3'b001: begin
					assign data1 = datareg[index][223:192];
					assign data2 = datareg[index+1][223:192];
				end
				3'b010: begin
					assign data1 = datareg[index][191:160];
					assign data2 = datareg[index+1][191:160];
				end
				3'b011: begin
					assign data1 = datareg[index][159:128];
					assign data2 = datareg[index+1][159:128];
				end
				3'b100: begin
					assign data1 = datareg[index][127:96];
					assign data2 = datareg[index+1][127:96];
				end
				3'b101: begin
					assign data1 = datareg[index][95:64];
					assign data2 = datareg[index+1][127:96];
				end
				3'b110: begin
					assign data1 = datareg[index][63:32];
					assign data2 = datareg[index+1][63:32];
				end
				3'b111: begin
					assign data1 = datareg[index][31:0];
					assign data2 = datareg[index+1][31:0];
				end
			endcase
			if (tag == tagreg [index]) begin
				assign Data_2Processor = data1;
			end else if (tag ==  tagreg [index + 1]) begin
				assign Data_2Processor = data2;
			end
		end
//-------------------------------------------------------------------------	
		else begin //miss
			//see if we need to writeback, evict, write new data block
			$display("CACHE MISS FOR LOAD INSTRUCTION");
			if (writeback == 1) begin //writeback needed
				assign STALL = 1;
				assign Data_2DM = datareg[effective_index];
			end else if (writeback == 0) begin //no writeback needed
				if (stall_count ==10) begin //miss
					assign STALL = 1;
				end	else if (stall_count >= 2 && stall_count <= 9) begin
					assign Data_address_2DM = {Data_address_fMEM [31:5],5'b0} + 4*(9 - stall_count);
					assign STALL = 1;
				end else if (stall_count == 1) begin
					assign STALL = 0; //? 
				end else begin
					assign STALL = 1;
				end
			end
		end
//=========================================================================
//=========================================================================
	end else if (MemWrite == 1) begin //STORE INSTRUCTIONS MEMWRITE
		if ((tag == tagreg [index] || tag == tagreg[index+1]) && (stall_count <= 1) && ((validreg [index] || validreg[index+1]) == 1)) begin //hit
			assign STALL = 0;
			$display("CACHE HIT FOR STORE INSTRUCTION");
			$display("we are writing %x bytes",data_write_size);
		end
//------------------------------------------------------------------------
		else begin //miss
			if (writeback == 1) begin //writeback needed
				assign STALL = 1;
				assign Data_2DM = datareg[effective_index];
			end else if (writeback == 0) begin //no writeback needed
				if (stall_count ==10) begin //miss
					assign STALL = 1;
				end	else if (stall_count >= 2 && stall_count <= 9) begin
					assign Data_address_2DM = {Data_address_fMEM [31:5],5'b0} + 4*(9 - stall_count);
					assign STALL = 1;
				end else if (stall_count == 1) begin
					assign STALL = 0; //? 
				end else begin
					assign STALL = 1;
				end
			end
		end
	end else begin // NOT A MEMORY INSTRUCTION
		$display("DATA_CACHE: Not a memory instruction, nothing to do");
	end

//=========================================================================
//=========================================================================
end

always@(posedge CLK or negedge RESET) begin 
	if (!RESET) begin
		//stall_count <= 11;//? flush the cache
		validreg <= 1024'b0;
		$display("DATA_CACHE: !RESET = %x", !RESET);
	end else if (CLK) begin
		if (((MemRead || MemWrite) == 1) && ((tag == tagreg [index] || tag == tagreg[index+1]) && (stall_count <= 1) && ((validreg [index] || validreg[index+1]) == 1))) begin //hit
			$display("validreg [%x] = %x and validreg [%x] = %x", index, validreg [index], index + 1, validreg [index+1]);
			effective_index <= (tag == tagreg [index])?index:(index+1);
			writeback <= 0;
			$display("DATA CACHE HIT DETECTED, SENDING TO MEM STAGE %x", Data_2Processor);
			stall_count <= 0; //?
			
			if (MemWrite == 1) begin
				case(offset)
				0: begin
					case(data_write_size)
						2'b00: begin
							datareg[effective_index] <= {Data_fDM,datareg[effective_index][223:0]};
						end
						2'b01: begin
							datareg[effective_index] <= {Data_fDM[31:24],datareg[effective_index][247:0]};
						end
						2'b10: begin
							datareg[effective_index] <= {Data_fDM[31:16],datareg[effective_index][239:0]};
						end
						2'b11: begin
							datareg[effective_index] <= {Data_fDM[31:8],datareg[effective_index][231:0]};
						end
					endcase
					
				end
				1: begin 
					case(data_write_size)
						2'b00: begin
							datareg[effective_index] <= {datareg[effective_index][255:224],Data_fDM,datareg[effective_index][191:0]};
						end
						2'b01: begin
							datareg[effective_index] <= {datareg[effective_index][255:224],Data_fDM[31:24],datareg[effective_index][215:0]};
						end
						2'b10: begin
							datareg[effective_index] <= {datareg[effective_index][255:224],Data_fDM[31:16],datareg[effective_index][207:0]};
						end
						2'b11: begin
							datareg[effective_index] <= {datareg[effective_index][255:224],Data_fDM[31:8],datareg[effective_index][199:0]};
						end
					endcase
					
				end
				2: begin
					case(data_write_size)
						2'b00: begin
							datareg[effective_index] <= {datareg[effective_index][255:192],Data_fDM,datareg[effective_index][159:0]};
						end
						2'b01: begin
							datareg[effective_index] <= {datareg[effective_index][255:192],Data_fDM[31:24],datareg[effective_index][183:0]};
						end
						2'b10: begin
							datareg[effective_index] <= {datareg[effective_index][255:192],Data_fDM[31:16],datareg[effective_index][175:0]};
						end
						2'b11: begin
							datareg[effective_index] <= {datareg[effective_index][255:192],Data_fDM[31:8],datareg[effective_index][167:0]};
						end
					endcase
					
				end
				3: begin
					case(data_write_size)
						2'b00: begin
							datareg[effective_index] <= {datareg[effective_index][255:160],Data_fDM,datareg[effective_index][127:0]};
						end
						2'b01: begin
							datareg[effective_index] <= {datareg[effective_index][255:160],Data_fDM[31:24],datareg[effective_index][151:0]};
						end
						2'b10: begin
							datareg[effective_index] <= {datareg[effective_index][255:160],Data_fDM[31:16],datareg[effective_index][143:0]};
						end
						2'b11: begin
							datareg[effective_index] <= {datareg[effective_index][255:160],Data_fDM[31:8],datareg[effective_index][135:0]};
						end
					endcase
				
				end
				4: begin
					case(data_write_size)
						2'b00: begin
							datareg[effective_index] <= {datareg[effective_index][255:128],Data_fDM,datareg[effective_index][95:0]};
						end
						2'b01: begin
							datareg[effective_index] <= {datareg[effective_index][255:128],Data_fDM[31:24],datareg[effective_index][119:0]};
						end
						2'b10: begin
							datareg[effective_index] <= {datareg[effective_index][255:128],Data_fDM[31:16],datareg[effective_index][111:0]};
						end
						2'b11: begin
							datareg[effective_index] <= {datareg[effective_index][255:128],Data_fDM[31:8],datareg[effective_index][103:0]};
						end
					endcase
				
				end
				5: begin
					case(data_write_size)
						2'b00: begin
							datareg[effective_index] <= {datareg[effective_index][255:96],Data_fDM,datareg[effective_index][63:0]};
						end
						2'b01: begin
							datareg[effective_index] <= {datareg[effective_index][255:96],Data_fDM[31:24],datareg[effective_index][87:0]};
						end
						2'b10: begin
							datareg[effective_index] <= {datareg[effective_index][255:96],Data_fDM[31:16],datareg[effective_index][79:0]};
						end
						2'b11: begin
							datareg[effective_index] <= {datareg[effective_index][255:96],Data_fDM[31:8],datareg[effective_index][71:0]};
						end
					endcase
				
				end
				6: begin
					case(data_write_size)
						2'b00: begin
							datareg[effective_index] <= {datareg[effective_index][255:64],Data_fDM,datareg[effective_index][31:0]};
						end
						2'b01: begin
							datareg[effective_index] <= {datareg[effective_index][255:64],Data_fDM[31:24],datareg[effective_index][55:0]};
						end
						2'b10: begin
							datareg[effective_index] <= {datareg[effective_index][255:64],Data_fDM[31:16],datareg[effective_index][47:0]};
						end
						2'b11: begin
							datareg[effective_index] <= {datareg[effective_index][255:64],Data_fDM[31:8],datareg[effective_index][39:0]};
						end
					endcase
				
				end
				7: begin
					case(data_write_size)
						2'b00: begin
							datareg[effective_index] <= {datareg[effective_index][255:32],Data_fDM};
						end
						2'b01: begin
							datareg[effective_index] <= {datareg[effective_index][255:32],Data_fDM[31:24],datareg[effective_index][23:0]};
						end
						2'b10: begin
							datareg[effective_index] <= {datareg[effective_index][255:32],Data_fDM[31:16],datareg[effective_index][15:0]};
						end
						2'b11: begin
							datareg[effective_index] <= {datareg[effective_index][255:32],Data_fDM[31:8],datareg[effective_index][7:0]};
						end
					endcase
					end
				endcase
				dirtyblock[effective_index] <= 1;
			end else if (MemRead == 1) begin
				MRUreg[effective_index] <= 1'b1;
				MRUreg[other_index] <= 1'b0;
			end
		end else if ((MemRead || MemWrite) == 1) begin //miss
			effective_index <= validreg[index] == 0? index : validreg[index+1] == 0? index + 1:MRUreg[index] == 0? index:index + 1; //effective index contains the index of the cache block getting evicted
			if (stall_count == 0) begin
				$display("DATA_CACHE: CACHE MISS DETECTED");
				stall_count <= 10;
			end else begin
				stall_count <= stall_count - 1;
			end
			//check dirty bits
/* 			if (stall_count == 11) begin

			end */
			//evict
			if (stall_count == 10) begin
				writeback <= dirtyblock[effective_index];
				$display("DATA_CACHE: writeback = %x", writeback);
				$display("DATA_CACHE: index %x has been evicted", effective_index);
				datareg[effective_index] <= 256'b0;
			end
		//repopulating
			case(stall_count)
				9: begin
					$display("DATA_CACHE: repopulating block w0");
					datareg[effective_index] <= {Data_fDM, 224'b0};
				end
				8: begin
					$display("DATA_CACHE: repopulating block w1");
					datareg[effective_index] <= {datareg[effective_index][255:224], Data_fDM, datareg[effective_index][191:0]};
				end
				7: begin
					$display("DATA_CACHE: repopulating block w2");
					datareg[effective_index] <= {datareg[effective_index][255:192], Data_fDM, datareg[effective_index][159:0]};
				end
				6: begin
					$display("DATA_CACHE: repopulating block w3");
					datareg[effective_index] <= {datareg[effective_index][255:160], Data_fDM, datareg[effective_index][127:0]};
				end
				5: begin
					$display("DATA_CACHE: repopulating block w4");
					datareg[effective_index] <= {datareg[effective_index][255:128], Data_fDM, datareg[effective_index][95:0]};
				end
				4: begin
					$display("DATA_CACHE: repopulating block w5");
					datareg[effective_index] <= {datareg[effective_index][255:96], Data_fDM, datareg[effective_index][63:0]};
				end
				3: begin
					$display("DATA_CACHE: repopulating block w6");
					datareg[effective_index] <= {datareg[effective_index][255:64], Data_fDM, datareg[effective_index][31:0]};
				end
				2: begin
					$display("DATA_CACHE: repopulating block w7");
					datareg[effective_index] <= {datareg[effective_index][255:32], Data_fDM};
					tagreg[effective_index] <= Data_address_fMEM[31:14]; //?
					MRUreg[effective_index] <= 1'b1;
					MRUreg[other_index] <= 1'b0;
					dirtyblock[effective_index] <= 0;
					validreg[effective_index] <= 1;

				end
			endcase 
		end
	end

	
		$display ("DATA_CACHE: datareg at index %x = [%x|%x|%x|%x|%x|%x|%x|%x]",effective_index, datareg[effective_index][255:224], datareg[effective_index][223:192], datareg[effective_index][191:160], datareg[effective_index][159:128], datareg[effective_index][127:96], datareg[effective_index][95:64], datareg[effective_index][63:32], datareg[effective_index][31:0]);
		$display("DATA_CACHE: dirtyblock at index %x = %x", effective_index, dirtyblock[effective_index]);
		$display ("DATA_CACHE: Data_address_2DM = %x with index = %x and offset = %x", Data_address_2DM, effective_index, offset);
		$display ("DATA_CACHE: valid bit at index %x = %b", effective_index, validreg [effective_index]);
		$display ("DATA_CACHE: The MRU index is %x = %x.  The LRU index is %x = %x", effective_index, MRUreg [effective_index], other_index, MRUreg [other_index]);
		$display ("Data_address_fMEM = %x",Data_address_fMEM);
		$display ("DATA_CACHE: Data_fDM = %x", Data_fDM);
		$display ("DATA_CACHE: stall_count = %x writeback = %x", stall_count, writeback);
		$display ("DATA_CACHE: MemRead = %b MemWrite = %b", MemRead, MemWrite);
		$display ("DATA_CACHE: Stall signal to other modules = %x", STALL);

	
end

	 /* verilator lint_off UNUSED */
	 
     /* verilator lint_on UNUSED */
endmodule