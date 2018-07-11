module INVX1(
	input i,
	output o
)

assign o = ~i;

endmodule

module NAND2X1(
	input i1,
	input i2,
	output o
)

assign o = ~(i1 & i2);

endmodule

module NOR2X1(
	input i1,
	input i2,
	output o
)

assign o = ~(i1 | i2);

endmodule

module XOR2X1(
	input i1,
	input i2,
	output o
)

assign o = (i1 ^ i2);

endmodule

module DFFX1(
	input i,
	input CLK,
	output reg o
) 

reg D;
assign D = i;

always @ (posedge CLK) begin
	o <= D;
end

endmodule


module AOI22(
	input a,b,c,d,
	output o
)

assign o = ~((a & b) | (c & d));

endmodule

module OAI22(
	input a,b,c,d,
	output o
)

assign o = ~((a | b) & (c | d));

endmodule

module MUX21(
	input a,b,
	input select,
	output o
)

// ouput b if select is high, output a if select is low
assign o = (select)? b:a;

endmodule

module CLK(
	input enable, // is it on?
	output clock
)

wire switch; // switch from high to low or low to high
reg clock;
reg [9:0] counter; // counts up

parameter duty_cycle = 30; // in percentage form, 100 means always high, 0 means always low.
initial clock = (duty_cycle/100 == 1) ? 0:1;
parameter clock_period = 1023; // counter should be able to granular enough to split up clock_period into enough cycles

//switch when clock_period/duty_cycle == counter or when counter = clock_period
assign switch = ((duty_cycle == 0) | (duty_cycle == 100)) ? 0: ((clock_period/duty_cycle == counter) | (counter == clock_period)); 

always @ (enable) begin
	counter <= counter + 1;
	always @ (switch) begin
		clock = ~clock;
	end
end

endmodule

module COMP(
	input voltage_offset,
	input threshold,
	output o
)

assign o = (voltage_offset >= threshold);

parameter voltage offset //input
parameter threshold
parameter bandwidth


endmodule