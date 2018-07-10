//
module instr_cache(
	input RESET,
	input CLK,
	//The address of the instruction that the processor gives the cache
	input [31:0] Instr_address_fIF,
	//The instruction that MM gives the cache (results from cache miss)
	input [31:0] Instr_fIM,
	//If the cache missed, stall the pipeline for 10 cycles
	output STALL,
	//The instruction that will be given to processor
	output reg [31:0] Instr_2Processor,
	//The address of the instruction that will be given to MM
	output [31:0] Instr_address_2IM
);
/*	32KB size
	1-way associative
	32B block size (holds 8 instructions)
	1 cycle
	10 cycles miss penalty
*/
wire [16:0] tag;
wire [9:0] index;
wire [2:0] offset;
reg [16:0]		tagreg  [0:1023]; //register file full of tags
reg [255:0]		datareg [0:1023]; //register file full of data
//the data/instructions will be in the form of little endian [w0 w1 w2 w3 w4 w5 w6 w7]
integer stall_count;


assign tag = Instr_address_fIF [31:15];
assign index = Instr_address_fIF[14:5];
assign offset = Instr_address_fIF[4:2];

always@ (Instr_address_fIF) begin 
	//$display("ENTER INSTR_ADDRESS_FIF BLOCK %x",Instr_address_fIF);
	if (!RESET) begin
		assign STALL = 1;//?
		assign Instr_2Processor = 32'b0;
	end else begin
		if (tag == tagreg [index] && stall_count <= 1) begin //hit
			assign STALL = 0;
			case (offset) //pick which block to give to processor
				3'b000: begin
					$display("offset = %x", offset);
					assign Instr_2Processor = datareg[index][255:224];
				end
				3'b001: begin
					assign Instr_2Processor = datareg[index][223:192];
				end
				3'b010: begin
					assign Instr_2Processor = datareg[index][191:160];
				end
				3'b011: begin
					assign Instr_2Processor = datareg[index][159:128];
				end
				3'b100: begin
					assign Instr_2Processor = datareg[index][127:96];
				end
				3'b101: begin
					assign Instr_2Processor = datareg[index][95:64];
				end
				3'b110: begin
					assign Instr_2Processor = datareg[index][63:32];
				end
				3'b111: begin
					assign Instr_2Processor = datareg[index][31:0];
				end
			endcase
		end else if (stall_count ==10) begin //miss
			assign STALL = 1;
		end	else if (stall_count >= 2 && stall_count != 10) begin
			assign Instr_address_2IM = {Instr_address_fIF [31:5],5'b0} + 4*(9 - stall_count);
			assign STALL = 1;
 		end else if (stall_count == 1) begin
			assign STALL = 0; //? 
		end else begin
			assign STALL = 1;
		end
	end
	
end

always@(posedge CLK or negedge RESET) begin
	if (!RESET) begin
		stall_count <= 10;//?

	end else if (CLK) begin
			$display ("INSTR_CACHE: stall_count = %x", stall_count);
		if (tag == tagreg [index] && stall_count <= 1) begin //hit
			stall_count <= 0;
			//Instr_2Processor <= data;
			$display("CACHE HIT DETECTED, SENDING TO PROCESSOR %x", Instr_2Processor);
		end else begin //miss
			if (stall_count == 0) begin //reset stall_count to 10 upon new cache miss
				$display("CACHE MISS DETECTED");
				stall_count <= 10;
			end else begin //else, count down
				stall_count <= stall_count - 1;
			end
			//repopulate
			if (stall_count == 10) begin
				$display ("INSTR_CACHE: repopulating cache starting from w0");
				datareg[index] <= 256'b0;
			end

				case(stall_count)
					9: begin
						$display("INSTR_CACHE: repopulating block w0");
						datareg[index] <= {Instr_fIM, 224'b0};
					end
					8: begin
						$display("INSTR_CACHE: repopulating block w1");
						datareg[index] <= {datareg[index][255:224], Instr_fIM, datareg[index][191:0]};
					end
					7: begin
						$display("INSTR_CACHE: repopulating block w2");
						datareg[index] <= {datareg[index][255:192], Instr_fIM, datareg[index][159:0]};
					end
					6: begin
						$display("INSTR_CACHE: repopulating block w3");
						datareg[index] <= {datareg[index][255:160], Instr_fIM, datareg[index][127:0]};
					end
					5: begin
						$display("INSTR_CACHE: repopulating block w4");
						datareg[index] <= {datareg[index][255:128], Instr_fIM, datareg[index][95:0]};
					end
					4: begin
						$display("INSTR_CACHE: repopulating block w5");
						datareg[index] <= {datareg[index][255:96], Instr_fIM, datareg[index][63:0]};
					end
					3: begin
						$display("INSTR_CACHE: repopulating block w6");
						datareg[index] <= {datareg[index][255:64], Instr_fIM, datareg[index][31:0]};
					end
					2: begin
						$display("INSTR_CACHE: repopulating block w7");
						datareg[index] <= {datareg[index][255:32], Instr_fIM};
						tagreg[index] <= Instr_address_fIF[31:15]; //?
					end
				endcase
		end
		//if not hit, stall for 10 cycles (dummy variable) and load in the data blocks and tag
		
		$display ("INSTR_CACHE: datareg at index %x = [%x|%x|%x|%x|%x|%x|%x|%x]",index, datareg[index][255:224], datareg[index][223:192], datareg[index][191:160], datareg[index][159:128], datareg[index][127:96], datareg[index][95:64], datareg[index][63:32], datareg[index][31:0]);
		$display ("INSTR_CACHE: Instr_address_2IM = %x with index = %x and offset = %x", Instr_address_2IM, index, offset);
		$display ("Instr_address_fIF = %x",Instr_address_fIF);
		$display ("INSTR_CACHE: Instr_fIM = %x", Instr_fIM);
		$display ("INSTR_CACHE: stall_count = %x", stall_count);
		
	end
	
end
	 /* verilator lint_off UNUSED */

     /* verilator lint_on UNUSED */
endmodule
