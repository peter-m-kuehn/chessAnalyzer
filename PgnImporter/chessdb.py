from datetime import date
from datetime import time
from dataclasses import dataclass
import mariadb

conn = None
cursor = None

#fake_date = datetime(1,1,1)
@dataclass
class GameRecord:
    white: str = ""
    black: str = ""
    variant: str = ""
    event: str = ""
    site: str  = ""
    white_fide_id: int = None
    black_fide_id: int = None
    white_elo: int = None
    black_elo: int = None
    white_title: str = ""
    black_title: str = ""
    game_date: date = None
    round: int = None
    result: int = None
    event_date: date = None
    event_sponsor: str = ""
    section: str = ""
    stage: str = ""
    board: int = None
    opening: str = None
    variation: str = None
    subvariation: str = None
    eco: str = ""
    nic: str = ""
    game_time: str = ""
    game_utc_date: str = ""
    game_utc_time: str = ""
    time_control: str = ""
    setup: int = None
    fen: str = ""
    termination: str = ""
    annotator: str = ""
    mode: str = ""
    plycount: int = None
    white_player_id: int = None
    black_player_id: int = None
    
def connect():
    global conn
    global cursor

    if conn != None and conn.open:
        return
        
    # Database connection details
    db_config = {
        'user': 'chess_user',
        'password': 'billich',
        'host': 'localhost',
        'database': 'chess',
        'port': 3306  # Standard port for MariaDB
    }
    # Establishing the connection
    conn = mariadb.connect(**db_config)
    # Create a cursor to execute queries
    cursor = conn.cursor()

def disconnect():
    cursor.close()
    conn.close()

def commit():
    conn.commit()
    
def rollback():
    conn.rollback()
    
def lookup_player_by_name(p_name):
    if p_name == '' or pname == None:
        return None
    
    cursor.execute("select id from player where name=?", (p_name,))
    result = cursor.fetchall()

    if not result:
        return None

    return result[0][0]

def insert_player(p_name, p_fide_id):
    if p_name == '' or p_name == None:
        return None    

    if (p_fide_id == 0 or p_fide_id == None):
        cursor.execute("insert into player (name) values (?) on duplicate key update id=id returning id", (p_name,))
    else:
        cursor.execute("insert into player (name, fide_id) values (?, ?) on duplicate key update fide_id=? returning id", (p_name, p_fide_id, p_fide_id,))

    result = cursor.fetchall()
    #conn.commit()
    
    return result[0][0]   
                       
def insert_elo (p_player_id, p_elo_num, p_elo_date):
    if (p_player_id == 0 or p_player_id == None or p_elo_num == 0 or p_elo_num == None or p_elo_date == None):
        return None

    cursor.execute("insert into elo (player_id, elo_num, elo_date) values (?, ?, ?) on duplicate key update elo_num=? returning player_id", (p_player_id, p_elo_num, p_elo_date, p_elo_num,))
    
    result = cursor.fetchall()
    #conn.commit()
    
    return result[0][0] 

def insert_title (p_player_id, p_title, p_title_date):
    if (p_player_id == 0 or p_player_id == None or p_title == "" or p_title == None or p_title_date == None):
        return None

    cursor.execute("insert into title (player_id, title, title_date) values (?, ?, ?) on duplicate key update title=? returning player_id", (p_player_id, p_title, p_title_date, p_title,))
    
    result = cursor.fetchall()
    #conn.commit()
    
    return result[0][0]     

def insert_game (p_game_record):
    # both players have to be set
    if (p_game_record.white_player_id == None or p_game_record.black_player_id == None):
        return None

    cursor.execute("insert into game (event, site, game_date, round, result, event_date, event_sponsor, section, stage, board, opening, variation, "
                   "subvariation, eco, nic, game_time, game_utc_date, game_utc_time, time_control, setup, fen, termination, annotator, mode, "
                   "plycount, white_player_id, black_player_id) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) returning id",
                   (p_game_record.event, p_game_record.site, p_game_record.game_date, p_game_record.round, p_game_record.result, p_game_record.event_date, 
                    p_game_record.event_sponsor, p_game_record.section, p_game_record.stage, p_game_record.board, p_game_record.opening, p_game_record.variation, 
                   p_game_record.subvariation, p_game_record.eco, p_game_record.nic, p_game_record.game_time, p_game_record.game_utc_date, 
                   p_game_record.game_utc_time, p_game_record.time_control, p_game_record.setup, p_game_record.fen, p_game_record.termination, 
                    p_game_record.annotator, p_game_record.mode, p_game_record.plycount, p_game_record.white_player_id, p_game_record.black_player_id,))

    result = cursor.fetchall()
    #conn.commit()
    
    return result[0][0]     
    