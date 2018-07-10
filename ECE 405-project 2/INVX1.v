// Verilog
module INVX1(
	input i,
	output o
)

wire o;
assign o = ~i;
	
endmodule

// Verilog AMS
module INVX1(
	input i,
	output o
)

parameter real vh = 1; //digital high
parameter real vl = 0; //digital low
parameter real threshold = (vh + vl)/2; // switch at 0.5V
parameter real delay = 0 from [0:inf);	// delay to start of output transition
parameter real tt = 0 from [0:inf);	// transition time of output signals

analog begin
	@ (cross(V(i) - threshold));
	
	V(o) <+ transition((V(i) > threshold)? vh: vl, td, tt);

end

endmodule