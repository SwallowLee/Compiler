//&S+
//&T-
//&D+
test;
/*
foo(): integer;
begin
		var a: array 1 to 3 of array 1 to 3 of integer;
		var b: array 1 to 5 of array 1 to 3 of integer;
		var i, j: integer;
		
		a[1][1] := i; // legal
		i := a[1][1] + j; // legal
		a[1][1] := b[1][2]; // legal
		
		a := b; // illegal: array arithmetic
		a[1] := b[2]; // illegal: array arithmetic
		return an[1][1]; // legal: 'a[1][1]' is a scalar type, but 'a' is an array type.
end
end foo
*/

begin
	var bool: boolean;
	var float: real;
	var str: string;
	var int: integer;
	var i3: array 1 to 3 of integer;
	var ii3: array 1 to 3 of array 1 to 3 of integer;
	var iii3: array 1 to 3 of array 1 to 3 of array 1 to 3 of integer;
	var i4: array 1 to 4 of integer;
	var s3: array 1 to 3 of string;
	var ss3: array 1 to 3 of array 1 to 3 of string;
	var sss3: array 1 to 3 of array 1 to 3 of array 1 to 3 of string;
	
	i3 := s3; 			//both array but dif type
	i3 := i3[1][1];		//both array but over dimetion
	i3 := i4;			//both array but dif size
	i3 := ii3; 			//both array but dif dimetion
	i3 := i3; 			//both array
	
	float := -ff[2];			//oprand is array
	float := -i3;				//oprand is array
	float := str + i3;			//oprand is array
	float := str mod i3;		//oprand is array
	float := str * i3;			//oprand is array
	bool  := str > i3;			//oprand is array
	
	float := str + int;			//f = s + i
	float := int + str;			//f = i + s
	float := str + str;			//f = s + s
	
	i3 := i3 + cccc[2] + cccc[2];		//no declare with array
	i3 := cccc[2] + cccc[2] + i3;		//no declare with array
	int   := int + cccc[2] + cccc[2];	//no declare with int
	int   := cccc[2] + cccc[2] + int;	//no declare with int
	
	cccc[2] := cc[1];					//no declare LHS with array
	cccc[2] := int;						//no declare LHS with int
	
end
end ttest
