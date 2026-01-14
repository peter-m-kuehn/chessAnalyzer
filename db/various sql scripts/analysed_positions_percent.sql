select
	g.id game_id,
	count(*) anzahl_halbzuege,
	sum(case when pa.position_id is null then 0 else 1 end) anzahl_analysierter_halbzuege,
	round(100 * sum(case when pa.position_id is null then 0 else 1 end) / count(*), 2) anteil_analysierter_halbzuege_proz
from
	player p
join game g on
	(g.black_player_id = p.id
		or g.white_player_id = p.id)
join position po on
	(po.game_id = g.id)
left outer join position_analysis pa on
	(pa.position_id = po.id)
where
	p.id = 4375261 # Steinitz
group by
	g.id
having
	sum(case when pa.position_id is null then 0 else 1 end) >0
order by	
	4;