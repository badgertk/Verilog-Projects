

`define LOG_PHYS    $clog2(NUM_PHYS_REGS)

module PhysRegFile/**#**/(
    //parameter NUM_PHYS_REGS = 64 
//)
//(
		input CLK,
		input RESET,
		input [5:0] RegA,
		input [5:0] RegB,
		input [5:0] RegC,
		output [31:0] DataA,
		output [31:0] DataB,
		input [5:0] WriteReg,
		input [31:0] WriteData,
		input RegWrite
    );

/* 	RegRead  #(
	.NUM_PHYS_REGS(NUM_PHYS_REGS)
	)
	PhysRegFile(
		.CLK(CLK),
		.RESET(RESET),
		.RegA(RegA),
		.RegB(RegB),
		.RegC(RegC),
		.DataA(DataA),
		.DataB(DataB),
		.WriteReg(WriteReg),
		.WriteData(WriteData),
		.RegWrite(RegWrite)
    ); */
	
	reg [31:0] Reg [0:64 - 1] /*verilator public*/;
	
	assign DataA = Reg[RegA];
	assign DataB = Reg[RegB];
	//assign DataC = Reg[RegC];
	integer i;
	
	always@(posedge CLK or negedge RESET) begin
		if (!RESET) begin
			for (i = 0; i<=64 - 1; i++) begin
				Reg[i] <= 0;
			end
		end else begin
			if (RegWrite) begin
				Reg[WriteReg] <= WriteData;
			end
		end
	end
    
    
endmodule
