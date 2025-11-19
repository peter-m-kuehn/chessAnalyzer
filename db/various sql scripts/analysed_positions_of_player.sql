set @player_id=4375261;
select
	g.id,count(*)
from
	game g
join player pw on
	g.white_player_id = pw.id
join player pb on
	g.black_player_id = pb.id
join position p on
	(g.id = p.game_id)
join position_analysis pa on
	(p.id = pa.position_id)
where
	pw.id = @player_id
	or pb.id = @player_id
	group by g.id;