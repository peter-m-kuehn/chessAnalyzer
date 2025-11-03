INSERT INTO fen_history (game_date, fen_pos)
select
	MIN(t.game_date) game_date,
	REGEXP_SUBSTR(t.fen, '[^ ]+ [^ ]+ [^ ]+ [^ ]+') as fen_pos
from
	(
	select
		g.game_date,
		p.fen
	from
		position p
	join game g on
		p.game_id = g.id
union all
	select
		STR_TO_DATE('1000-01-01', '%Y-%m-%d') game_date,
		'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1' fen_pos 
) t
group by
	REGEXP_SUBSTR(t.fen, '[^ ]+ [^ ]+ [^ ]+ [^ ]+')
;