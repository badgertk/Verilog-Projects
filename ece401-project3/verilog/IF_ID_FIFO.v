/**
NOTES:

Metadata include the following:
	Instr, Instr_PC_Plus4
**/


module IF_ID_FIFO(
	input CLK,
	input RESET,
	input [31:0] PC_IN,
	//input [1000:0] metadata_IN,
	input [31:0] Instr_IN,
	input [31:0] Instr_PC_Plus4_IN,
	
	output reg [31:0] PC_OUT,
	//output reg [1000:0] metadata_OUT,
	output [31:0] Instr_OUT,
	output [31:0] Instr_PC_Plus4_OUT,

	input STALL_IF_IN,
	output STALL_forIF, //this stalls when the queue is full and cannot accept something in
	output STALL_forID, //this stalls when the queue is empty and cannot take something out
	input STALL_ID_IN

);

reg [2:0] head;
reg [2:0] tail;
reg [31:0]		PC_Queue  		[7:0]; 
//reg [1000:0]		Metadata_Queue	[7:0];
reg [31:0] Instr	[7:0];
reg [31:0] Instr_PC_Plus4	[7:0];

wire empty;
wire full;
reg swap; //wire or reg?
integer i;
//assigns
assign empty = (head == tail && !swap)?1:0;
assign full = (head == tail && swap)?1:0;

//always @ blocks
always@(PC_IN) begin
	if(!STALL_IF_IN && !STALL_ID_IN) begin
		assign STALL_forIF = 0;
		assign STALL_forID = 0;
		if (empty) begin //do i need to move head and tail pointers???
			assign PC_OUT = PC_IN;
			//assign Metadata_OUT = Metadata_IN;
			assign Instr_OUT = Instr_IN;
			assign Instr_PC_Plus4_OUT = Instr_PC_Plus4_IN;

		end else begin //normal execution
			//take something out of queue
			assign PC_OUT = PC_Queue[head];
			//assign Metadata_OUT = Metadata_Queue[head];
			
			assign Instr_OUT = Instr[head];
			assign Instr_PC_Plus4_OUT = Instr_PC_Plus4[head];

/* 			//update head of queue
			if (head == 3b'111) begin
				head = 3'b000;
				swap = !swap;
			end else begin
				head = head + 1;
			end
			//update the tail of the queue
			if (tail == 3b'111) begin
				tail = 3'b000;
				swap = !swap;
			end else begin
				tail = tail + 1;
			end */
			
			//put something into the queue (this probably goes into @posedge block)
			assign PC_Queue[tail] = PC_IN;
			//assign Metadata_Queue[tail] = Metadata_IN;
			
			assign Instr[tail] = Instr_IN;
			assign Instr_PC_Plus4[tail] = Instr_PC_Plus4_IN;

		end
	end

	if(!STALL_IF_IN && STALL_ID_IN) begin
		if (full) begin
			assign STALL_forIF = 1;
			assign STALL_forID = 0;
		end else begin
			assign STALL_forIF = 0;
			assign STALL_forID = 0;
/* 			//update the tail of the queue
			if (tail == 3b'111) begin
				tail = 3'b000;
				swap = !swap;
			end else begin
				tail = tail + 1;
			end */
			//put something into the queue (this probably goes into @posedge block)
			assign PC_Queue[tail] = PC_IN;
			//assign Metadata_Queue[tail] = Metadata_IN;
			
			assign Instr[tail] = Instr_IN;
			assign Instr_PC_Plus4[tail] = Instr_PC_Plus4_IN;

		end
	end

	if(STALL_IF_IN && !STALL_ID_IN) begin
		if (empty) begin
			assign STALL_forIF = 0;
			assign STALL_forID = 1;
		end else begin
			assign STALL_forIF = 0;
			assign STALL_forID = 0;
			//take something out of queue
			assign PC_OUT = PC_Queue[head];
			//assign Metadata_OUT = Metadata_Queue[head];
			
			assign Instr_OUT = Instr[head];
			assign Instr_PC_Plus4_OUT = Instr_PC_Plus4[head];

/* 			//update head of queue
			if (head == 3b'111) begin
				head = 3'b000;
				swap = !swap;
			end else begin
				head = head + 1;
			end */
		end
	end

	if(STALL_IF_IN && STALL_ID_IN) begin
		assign STALL_forIF = 1;
		assign STALL_forID = 1;
		//both prev and next stage stalled, do nothing
	end

end

always@(posedge CLK or negedge RESET) begin
	if(!RESET) begin
		head <= 3'b0;
		tail <= 3'b0;
		for (i = 0; i<= 7; i++) begin
			PC_Queue[i] <= 32'b0;
			//Metadata_Queue[i] <= 1000b'0;			
			Instr[i] <= 32'b0;
			Instr_PC_Plus4[i] <= 32'b0;
			
		end
	end else if (CLK) begin 
		if(!STALL_IF_IN && !STALL_ID_IN) begin //normal execution
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
		
		if(!STALL_IF_IN && STALL_ID_IN) begin //evaluate full, if not, put in, else do nothing
			//$display("QUEUE: XXXX.");
			//update the tail of the queue
				if (tail == 3'b111) begin
					tail <= 3'b000;
					swap <= !swap;
				end else begin
					tail <= tail + 1;
				end
		end
		
		if(STALL_IF_IN && !STALL_ID_IN) begin //evaluate empty, if not, take out, else do nothing
			//$display("QUEUE: XXXX.");
						//update head of queue
				if (head == 3'b111) begin
					head <= 3'b000;
					swap <= !swap;
				end else begin
					head <= head + 1;
				end
		end
		
		if(STALL_IF_IN && STALL_ID_IN) begin //stall
			$display("QUEUE: both stages on either side have stalled.");
		end
	end
end

endmodule