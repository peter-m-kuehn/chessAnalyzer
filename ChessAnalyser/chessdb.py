from datetime import date
from datetime import time
from dataclasses import dataclass
import mariadb

conn = None
cursor = None


@dataclass
class PositionAnalysisRecord:
    position_id: int = None
    centipawn: int = None
    wins: int = None
    draws: int = None
    losses: int = None
    best_move_uci: str = ""
    depth: int = None
    seldepth: int = None
    nodes: int = None
    time_sec: float = None


def connect(p_password):
    global conn
    global cursor

    if conn != None and conn.open:
        return

    # Database connection details
    db_config = {
        "user": "chess_user",
        "password": p_password,
        "host": "localhost",
        "database": "chess",
        "port": 3306,  # Standard port for MariaDB
    }
    # Establishing the connection
    conn = mariadb.connect(**db_config)
    # Disable autocommit
    conn.autocommit = False
    # Create a cursor to execute queries
    cursor = conn.cursor()


def disconnect():
    cursor.close()
    conn.close()


def commit():
    conn.commit()


def rollback():
    conn.rollback()


def insert_position_analysis(p_position_analysis):
    cursor.execute(
        "insert into position_analysis (position_id, centipawn, wins, draws, losses, best_move_uci, depth, seldepth, nodes, time_sec) values (?,?,?,?,?,?,?,?,?,?)",
        (
            p_position_analysis.position_id,
            p_position_analysis.centipawn,
            p_position_analysis.wins,
            p_position_analysis.draws,
            p_position_analysis.losses,
            p_position_analysis.best_move_uci,
            p_position_analysis.depth,
            p_position_analysis.seldepth,
            p_position_analysis.nodes,
            p_position_analysis.time_sec,
        ),
    )


def get_games(p_id_player):
    cursor.execute(
        "select id from game where white_player_id=? or black_player_id=? order by game_date, id",
        (
            p_id_player,
            p_id_player,
        ),
    )
    return cursor.fetchall()


def position_analysis_exists(p_game_id):
    cursor.execute(
        "select count(*) from game g where g.id = ? 	and exists (select 1 from position p join position_analysis pa on (p.id = pa.position_id) where p.game_id = g.id )",
        (p_game_id,),
    )
    row = cursor.fetchone()
    return row[0] > 0


def get_positions(p_game_id):
    sql = """
        select
	    t.pos_id,
	    t.new_position 
    from
        (
        select
            g.game_date,
            pos.id pos_id,
            pos.half_move_num,
            pos.fen "new_position",
            NVL(LAG(pos.fen) over (order by pos.half_move_num), 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1') as 'prior_position'
        from
            game g
        join position pos on
            pos.game_id = g.id
        where
            g.id = ?
        ) t
     where
        not (exists (
        select
            1
        from
            fen_history h
        where
            h.fen_pos = REGEXP_SUBSTR(t.new_position, '[^ ]+ [^ ]+ [^ ]+ [^ ]+')
                and h.game_date < t.game_date)
        and exists (
        select
            1
        from
            fen_history h
        where
            h.fen_pos = REGEXP_SUBSTR(t.prior_position, '[^ ]+ [^ ]+ [^ ]+ [^ ]+')
                and h.game_date < t.game_date))
    order by
        t.half_move_num
    """
    cursor.execute(sql, (p_game_id,))
    return cursor.fetchall()
