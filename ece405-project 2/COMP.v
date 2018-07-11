// Verilog 
module COMP(
	input voltage_offset,
	input threshold,
	output o
)

assign o = (voltage_offset >= threshold);


endmodule

// Verilog AMS
// Verilog 
module COMP(
	input voltage_offset,
	input threshold,
	output o
)
parameter real voltage_offset;
parameter real threshold;
parameter real vh = 1; //digital high
parameter real vl = 0; //digital low

analog begin
	always @ (cross(V(voltage_offset) - V(threshold)));
	V(o) <+ vh;
	always @ (cross(V(threshold) - V(voltage_offset)));
	V(o) <+ vl;
	
end

endmodule