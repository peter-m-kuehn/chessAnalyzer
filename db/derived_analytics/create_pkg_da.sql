SET SESSION SQL_MODE='ORACLE';
DELIMITER //

CREATE OR REPLACE PACKAGE da AS
  -- must be declared as public!
  PROCEDURE gen_da_position(p_player_id NUMBER(20));
  procedure gen_da_game;
END da;
//

CREATE OR REPLACE PACKAGE BODY da as

	function calc_win_percent(p_centipawns in double) return double
	as
		v_win_percent double;
	begin
		v_win_percent := 50.0 + 50.0 * (2.0 / (1.0 + exp(-0.00368208 * p_centipawns)) - 1.0);
		return v_win_percent;
	end calc_win_percent;
	
	function calc_accuracy (p_winpercent_before in double, p_winpercent_after in double) return double
	as
		v_win_diff double;
		v_accuracy double;
	begin
		if p_winpercent_after >= p_winpercent_before then
			return (100.0);
		end if;
	
		v_win_diff := p_winpercent_before - p_winpercent_after;
		v_accuracy := 103.1668 * exp(-0.04354 * (v_win_diff)) - 3.1669;
		v_accuracy := greatest(v_accuracy, 0.0);
		v_accuracy := least(v_accuracy, 100.0);
		
		return(v_accuracy);
	end calc_accuracy;
		
	function calc_judgement (p_winpercent_before in double, p_winpercent_after in double) return varchar2
	as
		v_win_diff double;
		v_judgement varchar2(100);
	begin
		if p_winpercent_after >= p_winpercent_before then
			return ('ENGINE');
		end if;
	
		v_win_diff := p_winpercent_before - p_winpercent_after;
		
		if v_win_diff >= 30.0 then
			v_judgement := 'BLUNDER';
		elsif v_win_diff >= 20.0 then
			v_judgement := 'MISTAKE';
		elsif v_win_diff >= 10.0 then
			v_judgement := 'INACCURACY';
		end if;
		
		return(v_judgement);
	end calc_judgement;
		
	function calc_sharpness (p_win in integer, p_loose in integer) return double
	as
		v_win_rescaled double;
		v_loose_rescaled double;
		v_sharpness double;
	begin	
		if p_win = 0 or p_loose = 0 then
			return null;
		end if;
	
		v_win_rescaled := p_win / 1000.0;
		v_loose_rescaled := p_loose / 1000.0;
		v_sharpness := pow(2.0 / (log(1.0 / v_win_rescaled - 1.0) + log(1.0 / v_loose_rescaled - 1.0)), 2);
	
	    return v_sharpness;
	end calc_sharpness;
	
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
		v_judgement varchar2(100);
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
			if v_rec.best_move_uci_prv is null or v_rec.game_id <> v_rec.game_id_prv
			then
				continue; -- no move evaluation available
			end if;
			v_da_position_rec := null;
			v_total_prv := v_rec.wins_prv + v_rec.draws_prv + v_rec.losses_prv;
			v_win_rate_prv := v_rec.wins_prv / v_total_prv;
			v_loss_rate_prv := v_rec.losses_prv / v_total_prv;
			v_white_winning_chances_prv := calc_win_percent(v_rec.centipawn_prv);
			v_black_winning_chances_prv := 100 - v_white_winning_chances_prv;
	
			v_total := v_rec.wins + v_rec.draws + v_rec.losses;
			v_score := v_rec.wins + v_rec.draws / 2;
			v_score_rate := v_score / v_total;
			v_win_rate := v_rec.wins / v_total;
			v_draw_rate := v_rec.draws / v_total;
			v_loss_rate := v_rec.losses / v_total;
			
			v_white_winning_chances := calc_win_percent(v_rec.centipawn);
			v_black_winning_chances := 100 - v_white_winning_chances;
			-- logging.log('v_white_winning_chances: '||v_white_winning_chances);
			-- logging.log('v_black_winning_chances: '||v_black_winning_chances);
				
			if (v_rec.half_move_num MOD 2 = 0) 
			then -- black moved
				v_black_score_rate := 100 * v_score_rate;
				v_white_score_rate := 100 * (1 - v_score_rate);
				if (v_rec.move_black = v_rec.best_move_uci_prv) then
					v_accuracy := 100.0;
					v_judgement := 'ENGINE';
				else
				    v_accuracy := calc_accuracy(v_black_winning_chances_prv, v_black_winning_chances);
					v_judgement := calc_judgement(v_black_winning_chances_prv, v_black_winning_chances);
				end if;
			else -- white moved
				v_white_score_rate := 100 * v_score_rate;
				v_black_score_rate := 100 * (1 - v_score_rate);
				if (v_rec.move_white = v_rec.best_move_uci_prv) then
					v_accuracy := 100.0;
					v_judgement := 'ENGINE';
				else
				    v_accuracy := calc_accuracy(v_white_winning_chances_prv, v_white_winning_chances);
					v_judgement := calc_judgement(v_white_winning_chances_prv, v_white_winning_chances);
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
			v_da_position_rec.judgement := v_judgement;
			v_da_position_rec.sharpness := calc_sharpness(v_rec.wins, v_rec.losses);
			--
			-- upsert record
			--
			upsert_da_position(v_da_position_rec);
		end loop;
		
	end gen_da_position;
	
	procedure gen_da1game (p_game_id NUMBER(20))
	as
		v_acpl_white double;
	    v_acpl_black double;
		v_stdcpl_white double;
		v_stdcpl_black double;
		v_accuracy_avg_white double;
		v_accuracy_avg_black double;
		v_sum_engine_moves_white integer;
		v_sum_engine_moves_black integer;
		v_sum_normal_moves_white integer;
		v_sum_normal_moves_black integer;
		v_sum_inaccurate_moves_white integer;
		v_sum_inaccurate_moves_black integer;
		v_sum_mistake_moves_white integer;
		v_sum_mistake_moves_black integer;
		v_sum_blunder_moves_white integer;
		v_sum_blunder_moves_black integer;
		v_game_length integer;
	begin
		select
			avg(cpl_white) acpl_white,
			avg(cpl_black) acpl_black,
			stddev_samp(cpl_white) stdcpl_white,
			stddev_samp(cpl_black) stdcpl_black,
			avg(case when cpl_white is not null then accuracy else null end) accuracy_avg_white,
			avg(case when cpl_black is not null then accuracy else null end) accuracy_avg_black,
			sum(case when cpl_white is not null and judgement = 'ENGINE' then 1 else 0 end) sum_engine_moves_white,
			sum(case when cpl_black is not null and judgement = 'ENGINE' then 1 else 0 end) sum_engine_moves_black,
			sum(case when cpl_white is not null and judgement is null then 1 else 0 end) sum_normal_moves_white,
			sum(case when cpl_black is not null and judgement is null then 1 else 0 end) sum_normal_moves_black,
			sum(case when cpl_white is not null and judgement = 'INACCURACY' then 1 else 0 end) sum_inaccurate_moves_white,
			sum(case when cpl_black is not null and judgement = 'INACCURACY' then 1 else 0 end) sum_inaccurate_moves_black,
			sum(case when cpl_white is not null and judgement = 'MISTAKE' then 1 else 0 end) sum_mistake_moves_white,
			sum(case when cpl_black is not null and judgement = 'MISTAKE' then 1 else 0 end) sum_mistake_moves_black,
			sum(case when cpl_white is not null and judgement = 'BLUNDER' then 1 else 0 end) sum_blunder_moves_white,
			sum(case when cpl_black is not null and judgement = 'BLUNDER' then 1 else 0 end) sum_blunder_moves_black,
			max(half_move_num) game_length
			into
			v_acpl_white,
			    v_acpl_black,
				v_stdcpl_white,
				v_stdcpl_black,
				v_accuracy_avg_white,
				v_accuracy_avg_black,
				v_sum_engine_moves_white,
				v_sum_engine_moves_black ,
				v_sum_normal_moves_white,
				v_sum_normal_moves_black,
				v_sum_inaccurate_moves_white,
				v_sum_inaccurate_moves_black,
				v_sum_mistake_moves_white,
				v_sum_mistake_moves_black,
				v_sum_blunder_moves_white,
				v_sum_blunder_moves_black,
				v_game_length
		from
				(
			select
						t.half_move_num ,
						t.move_white,
						t.move_black,
						t.best_move_uci,
						t.centipawn,
						case
							when t.half_move_num mod 2 = 0 then null
					else case
								when t.accuracy >= 99 then 0
						else (t.centipawn_prv - t.centipawn) * t.inverse_sign
					end
				end cpl_white,
						case
							when t.half_move_num mod 2 = 1 then null
					else case
								when t.accuracy >= 99 then 0
						else (t.centipawn_prv - t.centipawn) * t.inverse_sign
					end
				end cpl_black,
						t.accuracy,
							t.judgement ,
							t.sharpness
			from
						(
				select
							p.half_move_num ,
							case
								when p.half_move_num mod 2 = 1 then 1
						else -1
					end inverse_sign,
							p.move_white ,
							p.move_black ,
							pa.best_move_uci ,
							pa.centipawn ,
							lag(pa.centipawn) over (
				order by
							p.game_id,
							p.half_move_num ) as centipawn_prv,
							dp.accuracy,
							dp.judgement ,
							dp.sharpness
				from
							chess.position p
				join chess.position_analysis as pa on
							p.id = pa.position_id
				left outer join chess.da_position as dp on
							dp.position_id = pa.position_id
				where
							p.game_id = p_game_id
				order by
							p.game_id,
							p.half_move_num ) t ) t2;
		insert into
			da_game (game_id,
			acpl_white,
			acpl_black,
			stdcpl_white,
			stdcpl_black,
			accuracy_avg_white,
			accuracy_avg_black,
			sum_engine_moves_white,
			sum_engine_moves_black,
			sum_normal_moves_white,
			sum_normal_moves_black,
			sum_inaccurate_moves_white,
			sum_inaccurate_moves_black,
			sum_mistake_moves_white,
			sum_mistake_moves_black,
			sum_blunder_moves_white,
			sum_blunder_moves_black,
			game_length)
		values (p_game_id,
			v_acpl_white,
			v_acpl_black,
			v_stdcpl_white,
			v_stdcpl_black,
			v_accuracy_avg_white,
			v_accuracy_avg_black,
			v_sum_engine_moves_white,
			v_sum_engine_moves_black,
			v_sum_normal_moves_white,
			v_sum_normal_moves_black,
			v_sum_inaccurate_moves_white,
			v_sum_inaccurate_moves_black,
			v_sum_mistake_moves_white,
			v_sum_mistake_moves_black,
			v_sum_blunder_moves_white,
			v_sum_blunder_moves_black,
			v_game_length);
	end gen_da1game;
	
	procedure gen_da_game
	as
	begin
		truncate table da_game;
		for v_rec in (select distinct p.game_id from da_position dap join position p on p.id =dap.position_id order by game_id)
		loop
			gen_da1game(v_rec.game_id);
			commit;
		end loop;
		
	end gen_da_game;
end da;
//

DELIMITER ;