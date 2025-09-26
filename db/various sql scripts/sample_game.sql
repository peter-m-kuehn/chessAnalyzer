select
	p1.name white,
	p2.name black,
	g.event,
	g.game_date,
	g.fen ausgangsposition,
	pos.half_move_num,
	pos.fen zielposition,
	pos.move_white,
	pos.move_black
from
	game g
join player p1 on
	g.white_player_id = p1.id
join player p2 on
	g.black_player_id = p2.id
join position pos on
	pos.game_id = g.id
where
	g.id = 2121301
order by
	pos.half_move_num;