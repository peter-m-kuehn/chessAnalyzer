select
	t.game_id, t.fen,	t.half_move_num ,	t.move_white,	t.move_black,	t.best_move_uci,t.best_move_uci_prv,	t.centipawn,	t.centipawn_prv,	(t.centipawn_prv - t.centipawn) cp_diff,	t.accuracy
from
	(
	select
	    p.game_id,
		p.fen,
		p.half_move_num ,
		p.move_white ,
		p.move_black ,
		pa.best_move_uci ,
		lag(pa.best_move_uci) over (order by p.game_id,
		p.half_move_num ) as best_move_uci_prv,
		pa.centipawn ,
		lag(pa.centipawn) over (
		order by p.game_id,
		p.half_move_num ) as centipawn_prv,
		dp.accuracy
	from
		chess.position p
	join chess.position_analysis as pa on
		p.id = pa.position_id
	left outer join chess.da_position as dp on
		dp.position_id = pa.position_id		
		/*
	where
		p.game_id = 2191557		
		*/
	order by
		p.game_id,
		p.half_move_num ) t
where ((half_move_num % 2 = 1 and t.centipawn > centipawn_prv) or (half_move_num % 2 = 0 and t.centipawn < centipawn_prv)) and  nvl(decode_oracle(t.move_white, '', null, t.move_white), decode_oracle(t.move_black, '', null, t.move_black)) <> t.best_move_uci_prv;