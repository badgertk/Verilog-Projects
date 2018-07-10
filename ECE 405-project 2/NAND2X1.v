// Verilog
module NAND2X1(
	input i1,
	input i2,
	output o
)

wire o;
assign o = ~(i1 & i2);

endmodule

// Verilog AMS
module NAND2X1(
	input i1,
	input i2,
	output o
)

parameter real vh = 1; //digital high
parameter real vl = 0; //digital low
parameter real threshold = (vh + vl)/2; // switch at 0.5V
parameter real delay = 0 from [0:inf);	// delay to start of output transition
parameter real tt = 0 from [0:inf);	// transition time of output signals

analog begin
	@ (cross(V(i1) - threshold) or cross(V(i2) - threshold));
	
	V(o) <+ transition(!((V(i1) > threshold) && (V(i2) > threshold))? vh: vl, td, tt);

end

endmodule