//&S+
//&T-
//&D+
/**
 * semtest5.p: test for program name
 */
test;

begin
	var i : integer;
	var r2 : array 1 to 2 of real;
	
	//IF condition THEN opt_stmt_list END IF
	if(d) then		// not decalere
	end if
	
	if(r2) then		// array type
	end if
	
	if(r2[1]) then	// other type
	end if
	
	if(r2[1]>r2[1]) then	// ok
	end if


	while(d) do			// not decalere
	end do
	
	while(r2) do		// array type
	end do
	
	while(r2[1]) do		// other type
	end do
	
	while(r2[1]>r2[1]) do	// ok
	end do
	
end
end testt
