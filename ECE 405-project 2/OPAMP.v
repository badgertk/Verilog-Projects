// Verilog how to digitize opamp?

// Verilog AMS
module OPAMP(
	input voltage_offset,
	output o
)

parameter real voltage_offset;
parameter real threshold;
parameter real gain;
parameter real SR;
parameter real f_3dB;
parameter real f_unity;
parameter real vh = 1; //digital high
parameter real vl = 0; //digital low
parameter real freq = SR/(2*3.1415*vh); // fiding frequency based on slew rate

analog begin
	@(cross (V(voltage_offset) - threshold));
	
	V(o) <+ (freq <= f_3dB)? (vh*gain*voltage_offset)/** before 3dB max gain**/:(freq <= f_unity ? (vh * (freq - f_3dB) * SR * gain)/** within low-pass band **/: ((freq - f_unity)*SR*gain*voltage_offset)/** past unity gain**/); 
	
	@(cross (threshold - V(voltage_offset)));
	V(o) = vl;
end

endmodule



always begin
MEMLB[0]<=8'b0000;
MEMLB[1]<=8'b0000;
MEMLB[2]<=8'b0000;
MEMLB[3]<=8'b0000;
MEMLB[4]<=8'b0010;
MEMLB[5]<=8'b0010;
MEMLB[6]<=8'b0010;
MEMLB[7]<=8'b0010;
MEMLB[8]<=8'b0010;
MEMLB[9]<=8'b0010;
MEMLB[10]<=8'b0011;
MEMLB[11]<=8'b0011;
MEMLB[12]<=8'b0011;
MEMLB[13]<=8'b0011;
MEMLB[14]<=8'b0011;
MEMLB[15]<=8'b0011;
MEMLB[16]<=8'b0101;
MEMLB[17]<=8'b0101;
MEMLB[18]<=8'b0101;
MEMLB[19]<=8'b0101;
MEMLB[20]<=8'b0101;
MEMLB[21]<=8'b0101;
MEMLB[22]<=8'b1000;
MEMLB[23]<=8'b1000;
MEMLB[24]<=8'b1000;
MEMLB[25]<=8'b1000;
MEMLB[26]<=8'b1000;
MEMLB[27]<=8'b1000;
MEMLB[28]<=8'b00011101;
MEMLB[29]<=8'b00011101;
MEMLB[30]<=8'b00011101;
MEMLB[31]<=8'b00011101;
MEMLB[32]<=8'b00011101;
MEMLB[33]<=8'b00011101;
MEMLB[34]<=8'b00010011;
MEMLB[35]<=8'b00010011;
MEMLB[36]<=8'b00010011;
MEMLB[37]<=8'b00010011;
MEMLB[38]<=8'b00010011;
MEMLB[39]<=8'b00010011;
MEMLB[40]<=8'b00100010;
MEMLB[41]<=8'b00100010;
MEMLB[42]<=8'b00100010;
MEMLB[43]<=8'b00100010;
MEMLB[44]<=8'b00100010;
MEMLB[45]<=8'b00100010;
MEMLB[46]<=8'b00100010;
MEMLB[47]<=8'b0010;
MEMLB[48]<=8'b0010;
MEMLB[49]<=8'b0010;
MEMLB[50]<=8'b0010;
MEMLB[51]<=8'b0010;
MEMLB[52]<=8'b0101;
MEMLB[53]<=8'b0101;
MEMLB[54]<=8'b0101;
MEMLB[55]<=8'b0101;
MEMLB[56]<=8'b0101;
MEMLB[57]<=8'b0101;
MEMLB[58]<=8'b1001;
MEMLB[59]<=8'b1001;
MEMLB[60]<=8'b1001;
MEMLB[61]<=8'b1001;
MEMLB[62]<=8'b1001;
MEMLB[63]<=8'b1001;
MEMLB[64]<=8'b1001;
MEMLB[65]<=8'b0100;
MEMLB[66]<=8'b0100;
MEMLB[67]<=8'b0100;
MEMLB[68]<=8'b0100;
MEMLB[69]<=8'b0100;
MEMLB[70]<=8'b0011;--
MEMLB[71]<=8'b0011;
MEMLB[72]<=8'b0011;
MEMLB[73]<=8'b0011;
MEMLB[74]<=8'b0011;
MEMLB[75]<=8'b0011;
MEMLB[76]<=8'b0011;
MEMLB[77]<=8'b0011;
MEMLB[78]<=8'b0111;--
MEMLB[79]<=8'b0111;
MEMLB[80]<=8'b0111;
MEMLB[81]<=8'b0111;
MEMLB[82]<=8'b0111;
MEMLB[83]<=8'b0111;
MEMLB[84]<=8'b0000;--
MEMLB[85]<=8'b0000;
MEMLB[86]<=8'b0000;
MEMLB[87]<=8'b0000;
MEMLB[88]<=8'b0000;
MEMLB[89]<=8'b0000;
MEMLB[90]<=8'b0000;
MEMLB[91]<=8'b0000;
MEMLB[92]<=8'b0000;
MEMLB[93]<=8'b0000;
MEMLB[94]<=8'b0000;
MEMLB[95]<=8'b0000;
MEMLB[96]<=8'b0111;--
MEMLB[97]<=8'b0111;
MEMLB[98]<=8'b0111;
MEMLB[99]<=8'b0111;
MEMLB[100]<=8'b0111;
MEMLB[101]<=8'b0111;
MEMLB[102]<=8'b0111;--
MEMLB[103]<=8'b0111;
MEMLB[104]<=8'b0111;
MEMLB[105]<=8'b0111;
MEMLB[106]<=8'b0111;
MEMLB[107]<=8'b0111;
MEMLB[108]<=8'b0111;--
MEMLB[109]<=8'b0100;
MEMLB[110]<=8'b0100;
MEMLB[111]<=8'b0100;
MEMLB[112]<=8'b0100;
MEMLB[113]<=8'b0100;
MEMLB[114]<=8'b0100;--
MEMLB[115]<=8'b0001;
MEMLB[116]<=8'b0001;
MEMLB[117]<=8'b0001;
MEMLB[118]<=8'b0001;
MEMLB[119]<=8'b0001;
MEMLB[120]<=8'b0101;--

end