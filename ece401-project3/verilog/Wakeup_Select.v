module Wakeup_Select(
	input [15:0] request_IN,
	output reg Issue_OUT,
	output reg [3:0] grant_index_OUT //the index of the instr granted permission to issue
	
);

//generates wakeup signal

wire Issue;
wire [15:0] request;
wire [15:0] grant;
wire [3:0] grant_index;

assign request = request_IN;
assign Issue_OUT = Issue;
assign grant_index_OUT = grant_index;

	assign grant [0] = request [0]; ///0000
	assign grant [1] = !request [0] & request [1];
	assign grant [2] = !grant [1] & request [2];
	assign grant [3] = !grant [2] & request [3];
	assign grant [4] = !grant [3] & request [4];
	assign grant [5] = !grant [4] & request [5];
	assign grant [6] = !grant [5] & request [6];
	assign grant [7] = !grant [6] & request [7]; ///0111
	assign grant [8] = !grant [7] & request [8]; ///1000
	assign grant [9] = !grant [8] & request [9];
	assign grant [10] = !grant [9] & request [10];
	assign grant [11] = !grant [10] & request [11];
	assign grant [12] = !grant [11] & request [12];
	assign grant [13] = !grant [12] & request [13];
	assign grant [14] = !grant [13] & request [14]; ///1110
	assign grant [15] = !grant [14] & request [15]; ///1111


//incredibly brute force...
assign grant_index[3] = grant[15] | grant[14] | grant[13] | grant[12] | grant[11] | grant[10] | grant[9] |  grant[8];
assign grant_index[2] = grant[15] | grant[14] | grant[13] | grant[12] | grant[7] | grant[6] | grant[5] |  grant[4];
assign grant_index[1] = grant[15] | grant[14] | grant[11] | grant[10] | grant[7] | grant[6] | grant[3] |  grant[2];
assign grant_index[0] = grant[15] | grant[13] | grant[11] | grant[9] | grant[7] | grant[5] | grant[3] |  grant[1];
assign Issue =  grant[15] | grant[14] | grant[13] | grant[12] | grant[11] | grant[10] | grant[9] |  grant[8] | grant[7] | grant[6] | grant[5] | grant[4] | grant[3] | grant[2] | grant[1] |  grant[0];

endmodule