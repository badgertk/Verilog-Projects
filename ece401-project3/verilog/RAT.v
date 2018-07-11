//-----------------------------------------
//           		RAT
//-----------------------------------------

`define LOG_ARCH    $clog2(NUM_ARCH_REGS)
`define LOG_PHYS    $clog2(NUM_PHYS_REGS)

module RAT #(
	/* 
	 * NUM_ARCH_REGS is the number of architectural registers present in the 
	 * RAT. 
	 *
	 * sim_main assumes that the value of LO is stored in architectural 
	 * register 33, and that the value of HI is stored in architectural 
	 * register 34.
	 *
	 * It is left as an exercise to the student to explain why.
	 */
    parameter NUM_ARCH_REGS = 35,
    parameter NUM_PHYS_REGS = 64
    /* Maybe Others? */
)
(	
    input CLK,
    input RESET,
    /*Register A to read*/
    input [4:0] RegA1,
    /*Register B to read*/
    input [4:0] RegB1,
    /*Register C to read*/
    //input [4:0] RegC1,
    /*Value of register A*/
    output [5:0] DataPointerA1,
    /*Value of register B*/
    output [5:0] DataPointerB1,
    /*Value of register C*/
    //output [5:0] DataPointerC1,
    /*Register to write*/
    input [4:0] WriteReg1,
    /*Data to write*/
    output [5:0] WriteDataPointer1,
    /*Actually do it?*/
    input Write1,
    /*Free Physical Register from Free List*/
    input [5:0] nextFree,
	
	input [5:0] regRecover_IN, //[34:0],
	output [5:0] regRecover_OUT// [34:0]  //arrays don't work??
	); 

	// actual RAT memory
	reg [`LOG_PHYS-1:0] regPtrs [NUM_ARCH_REGS-1:0] /*verilator public_flat*/;
	reg [`LOG_PHYS-1:0] regRecover [NUM_ARCH_REGS-1:0]; //??
	
	integer i;
	
	 assign DataPointerA1 = regPtrs[RegA1];
	 assign DataPointerB1 = regPtrs[RegB1];
	 assign WriteDataPointer1 = nextFree;
	 
   always @(posedge CLK or negedge RESET) begin
	if (!RESET) begin
		for(i = 0; i <= 34; i++) begin
			regPtrs[i] <= regRecover[i];
		end
	end else begin
        if (Write1) begin
            regPtrs[WriteReg1] <= nextFree;
        end
	end

end

endmodule

