SET SESSION SQL_MODE='ORACLE';
DELIMITER //

CREATE OR REPLACE PACKAGE da AS
  -- must be delared as public!
  PROCEDURE gen_da_position(p_player_id NUMBER(20));
END da;
//

CREATE OR REPLACE PACKAGE BODY da as

	function calc_win_percent(p_centipawns in double) return double
	as
		v_win_percent double;
	begin
		logging.log('calc_win_percent()');
		logging.log('p_centipawns: '||p_centipawns);
		v_win_percent := 50.0 + 50.0 * (2.0 / (1.0 + exp(-0.00368208 * p_centipawns)) - 1.0);
		logging.log('v_win_percent: '||v_win_percent);
		return v_win_percent;
	end calc_win_percent;
	
	function calc_accuracy (p_winpercent_before in double, p_winpercent_after in double) return double
	as
		v_win_diff double;
		v_accuracy double;
	begin
logging.log('calc_accuracy()');
logging.log('p_winpercent_before: '||p_winpercent_before);
logging.log('p_winpercent_after: '||p_winpercent_after);

		if p_winpercent_after >= p_winpercent_before then
		logging.log('accuracy: 100.0');
			return (100.0);
		end if;
	
		v_win_diff := p_winpercent_before - p_winpercent_after;
logging.log('v_win_diff: '||v_win_diff);
		v_accuracy := 103.1668 * exp(-0.04354 * (v_win_diff)) - 3.1669;
		v_accuracy := greatest(v_accuracy, 0.0);
		v_accuracy := least(v_accuracy, 100.0);
logging.log('v_accuracy: '||v_accuracy);
		
		return(v_accuracy);
	end calc_accuracy;
	
	procedure upsert_da_position(p_da_position_rec in da_position%rowtype)
	as
	begin
		insert into da_position values (p_da_position_rec.position_id, 
										p_da_position_rec.white_winning_chances,
										p_da_position_rec.white_score_rate,
										p_da_position_rec.white_draw_rate,
										p_da_position_rec.black_winning_chances,
										p_da_position_rec.black_score_rate,
										p_da_position_rec.black_draw_rate,
										p_da_position_rec.accuracy,
										p_da_position_rec.judgement,
										p_da_position_rec.sharpness
										)
			on duplicate key 
				update white_winning_chances = p_da_position_rec.white_winning_chances,
	                   white_score_rate = p_da_position_rec.white_score_rate,
					   white_draw_rate = p_da_position_rec.white_draw_rate,
					   black_winning_chances = p_da_position_rec.black_winning_chances,
	                   black_score_rate = p_da_position_rec.black_score_rate,
	                   black_draw_rate = p_da_position_rec.black_draw_rate,
	                   accuracy = p_da_position_rec.accuracy,
	                   judgement = p_da_position_rec.judgement,
	                   sharpness = p_da_position_rec.sharpness;
	end upsert_da_position;
	
	PROCEDURE gen_da_position(p_player_id NUMBER(20))
	as
		v_total_prv, v_total, v_win_rate_prv, v_win_rate, v_white_winning_chances_prv, v_white_winning_chances, v_score double;
	    v_score_rate, v_draw_rate, v_loss_rate, v_white_score_rate, v_black_score_rate double;
		v_loss_rate_prv, v_accuracy, v_black_winning_chances_prv, v_black_winning_chances double;
		v_white_draw_rate, v_black_draw_rate double;
	
		v_da_position_rec da_position%rowtype;
	begin
		for v_rec in 
		(
		select
		lag(g.id) over (order by g.id, p.half_move_num) as game_id_prv,
		g.id as game_id, 
		pa.position_id,
		p.half_move_num,
		decode(p.move_white, '', null, p.move_white) move_white,
		decode(p.move_black, '', null, p.move_black) move_black,
		lag(pa.best_move_uci) over (order by g.id, p.half_move_num) as best_move_uci_prv,
		pa.best_move_uci,
		lag(pa.centipawn) over (order by g.id, p.half_move_num) as centipawn_prv,
		pa.centipawn,
		lag(pa.wins) over (order by g.id, p.half_move_num) as wins_prv,
		pa.wins,
		lag(pa.draws) over (order by g.id, p.half_move_num) as draws_prv,
		pa.draws,
		lag(pa.losses) over (order by g.id, p.half_move_num) as losses_prv,
		pa.losses
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
			pw.id = p_player_id
			or pb.id = p_player_id
	    order by g.id, p.half_move_num
		)
		loop
		logging.log('position_id: '||v_rec.position_id);
			if v_rec.best_move_uci_prv is null or v_rec.game_id <> v_rec.game_id_prv
			then
				continue; -- no move evaluation available
			end if;
			v_da_position_rec := null;
			v_total_prv := v_rec.wins_prv + v_rec.draws_prv + v_rec.losses_prv;
		logging.log('v_total_prv: '||v_total_prv);
			v_win_rate_prv := v_rec.wins_prv / v_total_prv;
		logging.log('v_win_rate_prv: '||v_win_rate_prv);
			v_loss_rate_prv := v_rec.losses_prv / v_total_prv;
		logging.log('v_loss_rate_prv: '||v_loss_rate_prv);
			
			if ((v_rec.half_move_num - 1) MOD 2 = 0) 
			then -- prior black move
			    logging.log('black moved');
				v_black_winning_chances_prv := calc_win_percent(v_rec.centipawn_prv);
				v_white_winning_chances_prv := 100 - v_black_winning_chances_prv;
			else -- white moved
				logging.log('white moved');
				v_white_winning_chances_prv := calc_win_percent(v_rec.centipawn_prv);
				v_black_winning_chances_prv := 100 - v_white_winning_chances_prv;
			end if;		
		logging.log('v_white_winning_chances_prv: '||v_white_winning_chances_prv);
		logging.log('v_black_winning_chances_prv: '||v_black_winning_chances_prv);
	
			v_total := v_rec.wins + v_rec.draws + v_rec.losses;
		logging.log('v_total: '||v_total);
			v_score := v_rec.wins + v_rec.draws / 2;
		logging.log('v_score: '||v_score);
			v_score_rate := v_score / v_total;
		logging.log('v_score_rate: '||v_score_rate);
			v_win_rate := v_rec.wins / v_total;
		logging.log('v_win_rate: '||v_win_rate);
			v_draw_rate := v_rec.draws / v_total;
		logging.log('v_draw_rate: '||v_draw_rate);
			v_loss_rate := v_rec.losses / v_total;
		logging.log('v_loss_rate: '||v_loss_rate);
			
			v_white_winning_chances := calc_win_percent(v_rec.centipawn);
			v_black_winning_chances := 100 - v_white_winning_chances;
			logging.log('v_white_winning_chances: '||v_white_winning_chances);
			logging.log('v_black_winning_chances: '||v_black_winning_chances);
				
			if (v_rec.half_move_num MOD 2 = 0) 
			then -- black moved
				logging.log('black moved');
				v_black_score_rate := 100 * v_score_rate;
				v_white_score_rate := 100 * (1 - v_score_rate);
				if (v_rec.move_black = v_rec.best_move_uci_prv) then
					v_accuracy := 100.0;
				else
				    v_accuracy := calc_accuracy(v_black_winning_chances_prv, v_black_winning_chances);
				end if;
			else -- white moved
				logging.log('white moved');
				v_white_score_rate := 100 * v_score_rate;
				v_black_score_rate := 100 * (1 - v_score_rate);
				if (v_rec.move_white = v_rec.best_move_uci_prv) then
					v_accuracy := 100.0;
				else
				    v_accuracy := calc_accuracy(v_white_winning_chances_prv, v_white_winning_chances);
				end if;
			end if;
			v_white_draw_rate := 100 * v_draw_rate;
			v_black_draw_rate := 100 * v_draw_rate;

			--
			-- set record data
			--
			v_da_position_rec.position_id := v_rec.position_id;
			v_da_position_rec.white_winning_chances := v_white_winning_chances;
			v_da_position_rec.white_score_rate := v_white_score_rate;
			v_da_position_rec.white_draw_rate := v_white_draw_rate;
			v_da_position_rec.black_winning_chances := v_black_winning_chances;
			v_da_position_rec.black_score_rate := v_black_score_rate; 
			v_da_position_rec.black_draw_rate := v_black_draw_rate;
			v_da_position_rec.accuracy := v_accuracy;
			v_da_position_rec.judgement := 'ENGINE';
			v_da_position_rec.sharpness := 0.0;
			--
			-- upsert record
			--
			upsert_da_position(v_da_position_rec);
		end loop;
		
	end gen_da_position;
end da;
//

DELIMITER ;