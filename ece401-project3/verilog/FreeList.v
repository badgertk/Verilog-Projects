//-----------------------------------------
//           FREE LIST
//-----------------------------------------


module FreeList (	
    input CLK,
    input RESET,
    /*FRAT needs a free register*/
    input Request,
     /*Free Physical Register to FRAT*/
     output [5:0] freeToFRAT,
	 input recycleReady,
     input [5:0] registerRecycle,
	 output STALL
		); 


	reg [5:0] head;
	reg [5:0] tail;
	reg [5:0] freeRegPtrs [63:0]; 


	wire empty;
	wire full;
	reg swap; //wire or reg?
	integer i;
	//assigns
	assign empty = (head == tail && !swap)?1:0;
	assign full = (head == tail && swap)?1:0;		
	
	always @(registerRecycle) begin
		assign freeRegPtrs[tail] = registerRecycle;
		assign tail =  (swap?tail+1:tail-1);
	end
	
   always @(posedge CLK or negedge RESET) begin
	if (!RESET) begin
		for(i = 0; i < 64; i++) begin
		
		end
		freeRegPtrs[0] <= 6'd0;
		freeRegPtrs[1] <= 6'd1;
		freeRegPtrs[2] <= 6'd2;
		freeRegPtrs[3] <= 6'd3;
		freeRegPtrs[4] <= 6'd4;
		freeRegPtrs[5] <= 6'd5;
		freeRegPtrs[6] <= 6'd6;
		freeRegPtrs[7] <= 6'd7;
		freeRegPtrs[8] <= 6'd8;
		freeRegPtrs[9] <= 6'd9;
		freeRegPtrs[10] <= 6'd10;
		freeRegPtrs[11] <= 6'd11;
		freeRegPtrs[12] <= 6'd12;
		freeRegPtrs[13] <= 6'd13;
		freeRegPtrs[14] <= 6'd14;
		freeRegPtrs[15] <= 6'd15;
		freeRegPtrs[16] <= 6'd16;
		freeRegPtrs[17] <= 6'd17;
		freeRegPtrs[18] <= 6'd18;
		freeRegPtrs[19] <= 6'd19;
		freeRegPtrs[20] <= 6'd20;
		freeRegPtrs[21] <= 6'd21;
		freeRegPtrs[22] <= 6'd22;
		freeRegPtrs[23] <= 6'd23;
		freeRegPtrs[24] <= 6'd24;
		freeRegPtrs[25] <= 6'd25;
		freeRegPtrs[26] <= 6'd26;
		freeRegPtrs[27] <= 6'd27;
		freeRegPtrs[28] <= 6'd28;
		freeRegPtrs[29] <= 6'd29;
		freeRegPtrs[30] <= 6'd30;
		freeRegPtrs[31] <= 6'd31;
		freeRegPtrs[32] <= 6'd32;
		freeRegPtrs[33] <= 6'd33;
		freeRegPtrs[34] <= 6'd34;
		freeRegPtrs[35] <= 6'd35;
		freeRegPtrs[36] <= 6'd36;
		freeRegPtrs[37] <= 6'd37;
		freeRegPtrs[38] <= 6'd38;
		freeRegPtrs[39] <= 6'd39;
		freeRegPtrs[40] <= 6'd40;
		freeRegPtrs[41] <= 6'd41;
		freeRegPtrs[42] <= 6'd42;
		freeRegPtrs[43] <= 6'd43;
		freeRegPtrs[44] <= 6'd44;
		freeRegPtrs[45] <= 6'd45;
		freeRegPtrs[46] <= 6'd46;
		freeRegPtrs[47] <= 6'd47;
		freeRegPtrs[48] <= 6'd48;
		freeRegPtrs[49] <= 6'd49;
		freeRegPtrs[50] <= 6'd50;
		freeRegPtrs[51] <= 6'd51;
		freeRegPtrs[52] <= 6'd52;
		freeRegPtrs[53] <= 6'd53;
		freeRegPtrs[54] <= 6'd54;
		freeRegPtrs[55] <= 6'd55;
		freeRegPtrs[56] <= 6'd56;
		freeRegPtrs[57] <= 6'd57;
		freeRegPtrs[58] <= 6'd58;
		freeRegPtrs[59] <= 6'd59;
		freeRegPtrs[60] <= 6'd60;
		freeRegPtrs[61] <= 6'd61;
		freeRegPtrs[62] <= 6'd62;
		freeRegPtrs[63] <= 6'd63;
	end else begin
        if(Request) begin
			if(empty) begin
				STALL <= 1;
			end else begin
				STALL <= 0;
				freeToFRAT <= freeRegPtrs[head];
				if(swap) begin
					if(head == 6'b000000) begin
						head <= 6'b111111;
						swap <= !swap;
					end else begin
						head <= head - 1;
					end
				end else begin
					if(head == 6'b111111) begin
						head <= 6'b000000;
						swap <= !swap;
					end else begin
						head <= head + 1;
					end
				end
			end
		end
	end

end

endmodule

