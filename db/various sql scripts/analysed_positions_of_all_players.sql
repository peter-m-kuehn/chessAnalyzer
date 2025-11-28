select
	p.id id,
	p.name name ,
	count(*) anzahl
from
	game g
join player p on
	(g.white_player_id = p.id
		or g.black_player_id = p.id)
where
	exists
(
	select
		1
	from
		position pp
	join position_analysis pa on
		(pp.id = pa.position_id)
	where
		g.id = pp.game_id)
group by
	p.id,
	p.name
order by
	3 desc;