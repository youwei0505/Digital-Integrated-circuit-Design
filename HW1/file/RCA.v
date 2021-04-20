module RCA(s, c_out, x, y, c_in);
input  [3:0] x, y;
output [3:0] s;
input  c_in;
output c_out;

/*
	Write Your Design Here ~
*/
wire c1,c2,c3;

//The Full Adder : FA(s, c_out, x, y, c_in);
FA FA1(s[0],c1,x[0],y[0],c_in);
FA FA2(s[1],c2,x[1],y[1],c1);
FA FA3(s[2],c3,x[2],y[2],c2);
FA FA4(s[3],c_out,x[3],y[3],c3);


endmodule
