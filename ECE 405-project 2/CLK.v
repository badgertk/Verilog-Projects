// Verilog
module CLK(
	input enable, // is it on?
	output clock
)

wire switch; // switch from high to low or low to high
reg clock;
reg [9:0] counter; // counts up

parameter integer duty_cycle = 30; // in percentage form, 100 means always high, 0 means always low.
initial clock = (duty_cycle/100 == 1) ? 0:1;
parameter integer clock_period = 1023; // counter should be able to granular enough to split up clock_period into enough cycles

//switch when clock_period/duty_cycle == counter or when counter = clock_period
assign switch = ((duty_cycle == 0) | (duty_cycle == 100)) ? 0: ((clock_period/duty_cycle == counter) | (counter == clock_period)); 

always @ (enable) begin
	counter <= counter + 1;
	always @ (switch) begin
		clock = ~clock;
	end
end

endmodule

// Verilog AMS
module CLK(
	input enable,
	output clock
)

integer counter, state;
parameter integer duty_cycle = 30; // in percentage form, 100 means always high, 0 means always low.
initial clock = (duty_cycle/100 == 1) ? 0:1;
parameter integer clock_period = 1023; // counter should be able to granular enough to split up clock_period into enough cycles
parameter real vh = 1; //digital high
parameter real vl = 0; //digital low
parameter real threshold = (vh + vl)/2; // switch at 0.5V
parameter real delay = 0 from [0:inf);	// delay to start of output transition
parameter real tt = 0 from [0:inf);	// transition time of output signals


analog begin
    @(cross(V(enable) - vth)) begin
		count = count + 1; // count input transitions
	if (count >= clock_period)
	    count = 0;
	state = ((duty_cycle == 0) | (duty_cycle == 100)) ? 0: ((clock_period/duty_cycle == counter) | (counter == clock_period));
    end
    V(clock) <+ transition(state ? vh : vl, td, tt);
end


endmodule