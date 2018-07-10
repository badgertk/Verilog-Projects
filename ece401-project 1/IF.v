`include "config.v"
/**************************************
* Module: Fetch
* Date:2013-11-24  
* Author: isaac     
*
* Description: Master Instruction Fetch Module
***************************************/
module  IF
(
    input CLK,
    input RESET,
    
    //This should contain the fetched instruction
    output reg [31:0] Instr1_OUT,
    //This should contain the address of the fetched instruction [DEBUG purposes]
    output reg [31:0] Instr_PC_OUT,
    //This should contain the address of the instruction after the fetched instruction (used by ID)
    output reg [31:0] Instr_PC_Plus4,

    //Will be set to true if we need to just freeze the fetch stage.
    input STALL,
    
    //There was probably a branch -- please load the alternate PC instead of Instr_PC_Plus4.
    input Request_Alt_PC,
    //Alternate PC to load
    input [31:0] Alt_PC,
    
    //Address from which we want to fetch an instruction
     output [31:0] Instr_address_2IM,
//     //Address to use for first instruction to fetch when coming out of reset
//     input [31:0]   PC_init,
     //Instruction received from instruction memory
     input [31:0]   Instr1_fIM
     
);

wire [31:0] IncrementAmount;
assign IncrementAmount = 32'd4; //NB: This might get modified for superscalar.

assign Instr_address_2IM = (Request_Alt_PC)?Alt_PC:Instr_PC_Plus4; //Changed from line below
//assign Instr_address_2IM = Instr_PC_Plus4;  //Are you sure that this is correct?

//wire [31:0] PC_Init;		//added //no longer needed once input[31:0] PC_Init is implemented
//assign PC_Init = 32'hBFC00000;	//added

always @(posedge CLK or negedge RESET) begin
    if(!RESET) begin
        Instr1_OUT <= 0;
        Instr_PC_OUT <= 0;
        Instr_PC_Plus4 <= 32'hBFC00000;
        $display("FETCH [RESET] Fetching @%x", Instr_PC_Plus4);
    end else if(CLK) begin
        if(!STALL) begin
                Instr1_OUT <= Instr1_fIM;
                Instr_PC_OUT <= Instr_address_2IM;
         	/* You should probably assign something to Instr_PC_Plus4. */
		Instr_PC_Plus4 <= Instr_address_2IM + IncrementAmount;	//added                
		$display("FETCH:Instr@%x=%x;Next@%x",Instr_address_2IM,Instr1_fIM,Instr_address_2IM + IncrementAmount);
              	$display("FETCH:ReqAlt[%d]=%x",Request_Alt_PC,Alt_PC);
        end else begin
            $display("FETCH: Stalling; next request will be %x",Instr_address_2IM);
        end
    end
end

endmodule

