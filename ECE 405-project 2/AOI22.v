// Verilog
module AOI22(
	input a,b,c,d,
	output o
)

wire o;
assign o = ~((a & b) | (c & d));

endmodule

// Verilog AMS
module AOI22(
	input a,b,c,d,
	output o
)

parameter real vh = 1; //digital high
parameter real vl = 0; //digital low
parameter real threshold = (vh + vl)/2; // switch at 0.5V
parameter real delay = 0 from [0:inf);	// delay to start of output transition
parameter real tt = 0 from [0:inf);	// transition time of output signals

analog begin
	@ (cross(V(a) - threshold) or cross(V(b) - threshold) or cross(V(c) - threshold) or cross(V(d) - threshold));
	
	V(o) <+ transition(!(((V(a) > threshold) && (V(b) > threshold)) || ((V(c) > threshold) && (V(d) > threshold)))? vh: vl, td, tt);

end

endmodule