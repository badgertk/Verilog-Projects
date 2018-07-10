// Verilog 
module MUX21(
	input a,b,
	input select,
	output o
)

// ouput b if select is high, output a if select is low
assign o = (select)? b:a;

endmodule

// Verilog AMS
module MUX21(
	input a,b,
	input select,
	output o
)

parameter real vh = 1; //digital high
parameter real vl = 0; //digital low
parameter real threshold = (vh + vl)/2; // switch at 0.5V
parameter real delay = 0 from [0:inf);	// delay to start of output transition
parameter real tt = 0 from [0:inf);	// transition time of output signals

analog begin
	@ (cross(V(a) - threshold) or cross(V(b) - threshold) or cross(V(select) - threshold));
	
	V(o) <+ transition((((V(select) < threshold) && (V(a) < threshold)) || ((V(select) > threshold) && (V(b) > threshold)))? vh: vl, td, tt);

end

endmodule