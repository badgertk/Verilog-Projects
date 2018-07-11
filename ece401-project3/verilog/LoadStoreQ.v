
module LoadStoreQ (
	input CLK,
	input RESET,
	input FLUSH_IN,
	input FLUSH_SAVE,
	input newEntry,
	input newReady,
	input addressEntry,
	input[32:0] address_IN,
	input[31:0] data_IN,
	input memWrite, //write to memory? ie store instruction?
	input[3:0] writePosition, //where in the queue do we want to write 
	output[3:0] Q_position, // the address in the q the instruction is waiting at so it can be found later
	output[31:0] address_OUT,
	output[31:0] data_OUT,
	output memRequest,
	input[31:0] PC_IN,
	output[31:0] PC_OUT,
	input[31:0] instr_IN,
	output[31:0] instr_OUT,
	input[5:0] ALUcntrl_IN,
	output[5:0] ALUcntrl_OUT,
	output LS_FULL
	);

reg [3:0] head;
reg [3:0] tail;

wire FLUSH;
reg swap;
wire full;

reg ready [15:0];
reg hasAddress[15:0];
reg writetoMem [15:0];
reg [31:0] MemAddress [15:0];
reg [31:0] data [15:0];
reg [31:0] PC [15:0];
reg [31:0] instr [15:0];
reg [5:0] ALUcntrl [15:0];

assign FLUSH = FLUSH_IN | !RESET;
assign full = ((head == tail) && swap)?1:0;

always @ (posedge CLK or negedge RESET) begin
	if(FLUSH) begin
		if(FLUSH_SAVE) begin
			if(head == 4'd15) begin
				tail <= 0;
				swap <= 1;
			end else begin
				tail <= head + 1;
				swap <= 0;
			end
		end else begin
			tail <= head;
			swap <= 0;
			ready[head] <= 0;
		end
	end else if(CLK) begin
		if((ready[head] == 1 && hasAddress[head] == 1)) begin
			address_OUT <= MemAddress[head];
			data_OUT <= data[head];
			PC_OUT <= PC[head];
			instr_OUT <= instr[head];
			ALUcntrl_OUT <= ALUcntrl[head];
			memRequest <= 1;
			if(head == 4'd15) begin
				head <= 0;
				swap <= !swap;
			end else begin
				head <= head + 1;
			end
		end else begin
			memRequest <= 0;
		end
		if(newEntry) begin
			if(!full | (ready[head] == 1 && hasAddress[head] == 1)) begin
				ready[tail] <= !memWrite;
				hasAddress[tail] <= 0;
				writetoMem[tail] <= memWrite;
				data[tail] <= data_IN;
				PC[tail] <= PC_IN;
				instr[tail] <= instr_IN;
				ALUcntrl[tail] <= ALUcntrl_IN;
				LS_FULL <= 0;
				Q_position <= tail;
				if(tail == 4'd15) begin
					tail <= 0;
					swap <= !swap;
				end else begin
					tail <= tail + 1;
				end
			end else if(full) begin
				LS_FULL <= 1;
			end
		end
		if(addressEntry) begin
			hasAddress[writePosition] <= 1;
			MemAddress[writePosition] <= address_IN;
		end
		if(newReady) begin
			ready[head] <= 1;
		end
	end
end

endmodule