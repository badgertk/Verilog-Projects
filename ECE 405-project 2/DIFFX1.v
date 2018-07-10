// Verilog
module DFFX1(
	input i,
	input CLK,
	output reg q
) 

reg D;
assign D = i;

always @ (posedge CLK) begin
	q <= D;
end

endmodule

// Verilog AMS
module DFFX1(
	input i,
	input CLK,
	output reg q
) 
parameter real vh = 1; //digital high
parameter real vl = 0; //digital low
parameter real threshold = (vh + vl)/2; // switch at 0.5V
parameter real delay = 0 from [0:inf);	// delay to start of output transition
parameter real tt = 0 from [0:inf);	// transition time of output signals

reg D;

analog begin
	@(cross(V(CLK) - threshold, 1) or cross(V(i) - threshold))
		@(cross(V(CLK) - threshold, 1) // posedge of CLK
		V(q) <+ transition((V(D) > threshold)? vh: vl, td, tt);
		
		@(cross(V(i) - threshold))
		V(D) <+ transition((V(i) > threshold)? vh: vl, td, tt);
end

endmodule