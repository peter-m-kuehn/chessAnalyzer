DELIMITER /

CREATE OR REPLACE PACKAGE logging AS
  -- must be delared as public!
  PROCEDURE log(p_msg IN varchar2);
END logging;
/

CREATE OR REPLACE PACKAGE BODY logging as

	procedure log(p_msg IN varchar2)
	as
	begin
		insert into logtable (msg) values (p_msg);
	end log; 
	
end logging;
/

DELIMITER ;