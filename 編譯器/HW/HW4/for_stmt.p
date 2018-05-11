//&S+
//&T-
//&D+
test;


begin
	var float: real;
	var int: integer;

	for i := 1 to 3 do				// ok
		for ii := 1 to 1 do
			for iii := 0 to 0 do
				int := int + 1;
			end do
		end do
	end do

	for i := 1 to 0 do				// error
		i := i + 1;					// error i
		for ii := 1 to 1 do
			i := i + 1;				// error i
			ii := i + 1;			// error ii
			ii := i[1] + 1;			// error ii && i[1]
			float := i + ii;
		end do
	end do

end
end ttest
