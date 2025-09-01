select
	p.*,
	t.title,
	e.max_elo_num,
	wg.num_white_games,
	bg.num_black_games
from
	player p 
left outer join (
	select
		max(e.elo_num) max_elo_num,
		e.player_id
	from
		elo e
	group by
		e.player_id) e on
	e.player_id = p.id
left outer join (
	select
		count(*) num_white_games,
		white_player_id
	from
		game
	group by
		white_player_id) wg on
	wg.white_player_id = p.id
left outer join (
	select
		count(*) num_black_games,
		black_player_id
	from
		game
	group by
		black_player_id) bg on
	bg.black_player_id = p.id
left outer join (
	select
		t.title,
		t.player_id
	from
		title t
	where
		t.title_date = (
		select
			max(tt.title_date)
		from
			title tt
		where
			tt.player_id = t.player_id)
	) t on
	t.player_id = p.id
	/* where p.name like BINARY '%Tal%' */
order by
	e.max_elo_num desc;


