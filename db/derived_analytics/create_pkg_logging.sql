SET SESSION SQL_MODE='ORACLE';
DELIMITER //

CREATE DEFINER="chess_user"@"%" PACKAGE "logging" AS
  -- must be delared as public!
  PROCEDURE log(p_msg IN varchar2);
END
//
CREATE DEFINER="chess_user"@"%" PACKAGE BODY "logging" as

	procedure log(p_msg IN varchar2)
	as
	begin
		insert into logtable (msg) values (p_msg);
	end log; 
	
end
//