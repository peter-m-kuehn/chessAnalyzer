set @player_id=4352896; # Bobby Fischer
select
	g.*
from
	game g
join player pw on
	g.white_player_id = pw.id
join player pb on
	g.black_player_id = pb.id
where
	exists (
	select
		1
	from
		position p
	join position_analysis pa on
		(p.id = pa.position_id)
	where
		g.id = p.game_id)
	and
	(pw.id = @player_id
		or pb.id = @player_id)
order by
	g.game_date;