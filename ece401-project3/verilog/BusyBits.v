//-----------------------------------------
//           BUSY BITS
//-----------------------------------------

module BusyBits (	
    input CLK,
    input RESET,
    //clear the busy bit of the corresponding reg
    input [5:0] regBusy,
    //set the busy bit of the corresponding reg
    input [5:0] regReady,
    //need to know if these are ready to go
    input [5:0] readyCheck1,
	input [5:0] readyCheck2,
    //signal whether or not the register is ready
    output isReady1,
	output isReady2
		); 

	reg busyBits [63:0];

	assign busyBits[regBusy] = 0;
	assign busyBits[regReady] = 1;
	
   always @(posedge CLK or negedge RESET) begin
	if (!RESET) begin
		busyBits[0] <= 1;
		busyBits[1] <= 1;
		busyBits[2] <= 1;
		busyBits[3] <= 1;
		busyBits[4] <= 1;
		busyBits[5] <= 1;
		busyBits[6] <= 1;
		busyBits[7] <= 1;
		busyBits[8] <= 1;
		busyBits[9] <= 1;
		busyBits[10] <= 1;
		busyBits[11] <= 1;
		busyBits[12] <= 1;
		busyBits[13] <= 1;
		busyBits[14] <= 1;
		busyBits[15] <= 1;
		busyBits[16] <= 1;
		busyBits[17] <= 1;
		busyBits[18] <= 1;
		busyBits[19] <= 1;
		busyBits[20] <= 1;
		busyBits[21] <= 1;
		busyBits[22] <= 1;
		busyBits[23] <= 1;
		busyBits[24] <= 1;
		busyBits[25] <= 1;
		busyBits[26] <= 1;
		busyBits[27] <= 1;
		busyBits[28] <= 1;
		busyBits[29] <= 1;
		busyBits[30] <= 1;
		busyBits[31] <= 1;
		busyBits[32] <= 1;
		busyBits[33] <= 1;
		busyBits[34] <= 1;
		busyBits[35] <= 1;
		busyBits[36] <= 1;
		busyBits[37] <= 1;
		busyBits[38] <= 1;
		busyBits[39] <= 1;
		busyBits[40] <= 1;
		busyBits[41] <= 1;
		busyBits[42] <= 1;
		busyBits[43] <= 1;
		busyBits[44] <= 1;
		busyBits[45] <= 1;
		busyBits[46] <= 1;
		busyBits[47] <= 1;
		busyBits[48] <= 1;
		busyBits[49] <= 1;
		busyBits[50] <= 1;
		busyBits[51] <= 1;
		busyBits[52] <= 1;
		busyBits[53] <= 1;
		busyBits[54] <= 1;
		busyBits[55] <= 1;
		busyBits[56] <= 1;
		busyBits[57] <= 1;
		busyBits[58] <= 1;
		busyBits[59] <= 1;
		busyBits[60] <= 1;
		busyBits[61] <= 1;
		busyBits[62] <= 1;
		busyBits[63] <= 1;
	end else if(CLK) begin
        isReady1 <= busyBits[readyCheck1];
		isReady2 <= busyBits[readyCheck2];
	end

end

endmodule