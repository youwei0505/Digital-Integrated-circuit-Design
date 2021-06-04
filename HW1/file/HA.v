module HA(s, c, x, y);
input x, y;
output s, c;

/*
	Write Your Design Here ~
*/

xor xor1(s,x,y);
and and1(c,x,y);

endmodule
