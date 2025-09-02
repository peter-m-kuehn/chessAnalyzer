import math
import re
from datetime import date
import chess
import chess.engine
import chess.pgn
#from IPython.display import Image, display
from dataclasses import dataclass
import logging
import sys
#sys.path.append("../PgnImporter")
import chessdb as db

# use basic logging
logging.basicConfig(filename='logs.log', level=logging.INFO, filemode="w")

# convert date in string format to date type by replacing unknown ("?") parts with default values
def clean_date(p_str):
    if p_str == None or p_str == "?":
        return None
    res = re.search(r"([0-9?]{4})[-.]([0-9?]{2})[.-]([0-9?]{2})", p_str)
    if res:
        year = res.group(1)
        if year == "????":
            year = '9999'
        month = res.group(2)
        if month == "??":
            month = "12"            
        day = res.group(3)
        if day == "??" or day == "31":
            if month == "02":
                day = "28"
            elif month in ("01", "03", "05", "07", "08", "10", "12"):
                day = "31"
            else:
                day= "30"
        return date(int(year), int(month), int(day))
    else:
        return None

# some data cleansing from raw pgn file
def clean_game(p_game):
    # game metadata cleaned up from pgn structure
    cleanGame = db.GameRecord()

    cleanGame.white = p_game.headers.get("White", "")
    cleanGame.black = p_game.headers.get("Black", "")
    s = p_game.headers.get("WhiteFideId")
    if s == None or s == "" or s == "?":
        cleanGame.white_fide_id = None     
    else:
        cleanGame.white_fide_id = int(s)
    s = p_game.headers.get("BlackFideId")
    if s == None or s == "" or s == "?":
        cleanGame.black_fide_id = None
    else:
        cleanGame.black_fide_id = int(s)
    cleanGame.variant = p_game.headers.get("Variant", "")
    cleanGame.event=p_game.headers.get("Event", "")
    cleanGame.event_date = clean_date(p_game.headers.get("EventDate"))
    cleanGame.game_date = clean_date(p_game.headers.get("Date"))
    s = p_game.headers.get("WhiteElo")
    if s == None or s == "" or s == "?":
        cleanGame.white_elo = None
    else:
        cleanGame.white_elo = int(s)
    s = p_game.headers.get("BlackElo")
    if s == None or s == "" or s == "?":
        cleanGame.black_elo = None
    else:
        cleanGame.black_elo = int(s)
    cleanGame.white_title = p_game.headers.get("WhiteTitle", "")
    cleanGame.black_title = p_game.headers.get("BlackTitle", "")
    cleanGame.site = p_game.headers.get("Site", "")
    cleanGame.round = p_game.headers.get("Round")
    s = p_game.headers.get("Result")
    if (s == "1-0"):
        cleanGame.result = 1
    elif (s == "0-1"):
        cleanGame.result = 2
    elif (s == "1/2-1/2"):
        cleanGame.result = 3
    else:
        cleanGame.result = 4
    cleanGame.event_sponsor = p_game.headers.get("EventSponsor", "")
    cleanGame.section = p_game.headers.get("Section", "")
    s = p_game.headers.get("Board")
    if (s != None and s != "" and s != "?"):
        cleanGame.board = int(s)
    cleanGame.opening = p_game.headers.get("Opening", "")
    cleanGame.variation = p_game.headers.get("Variation", "")
    cleanGame.subvariation = p_game.headers.get("Subvariation", "")
    cleanGame.eco = p_game.headers.get("ECO", "")
    cleanGame.nic = p_game.headers.get("Nic", "")
    cleanGame.game_time = p_game.headers.get("Time", "")
    cleanGame.game_utc_date = p_game.headers.get("UTCDate", "")
    cleanGame.game_utc_time = p_game.headers.get("UTCTime", "")
    cleanGame.time_control = p_game.headers.get("TimeControl", "")
    s = p_game.headers.get("SetUp")
    if (s == None or s == "0" or s != "1"):
        cleanGame.setup = 0
    else:
        cleanGame.setup = 1
    cleanGame.fen = p_game.headers.get("FEN", "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    cleanGame.termination = p_game.headers.get("Termination", "")
    cleanGame.annotator = p_game.headers.get("Annotator", "")
    cleanGame.mode = p_game.headers.get("Mode", "")
    s = p_game.headers.get("Plycount")
    if (s == None or s == "" or s == "?"):
        cleanGame.plycount = 0
    else:
        cleanGame.plycount = int(s)
    cleanGame.source=p_game.headers.get("Source", "")
    cleanGame.import_date = clean_date(p_game.headers.get("ImportDate"))
    
    return(cleanGame)
    
def upsert_players_info(p_cleanGame):
    d = p_cleanGame.event_date if p_cleanGame.game_date is None else p_cleanGame.game_date
    
    # white player stuff
    player_id = db.insert_player(p_cleanGame.white, p_cleanGame.white_fide_id)
    db.insert_elo (player_id, p_cleanGame.white_elo, d)
    db.insert_title (player_id, p_cleanGame.white_title, d)
    p_cleanGame.white_player_id = player_id
    
    # black player stuff
    player_id = db.insert_player(p_cleanGame.black, p_cleanGame.black_fide_id)
    db.insert_elo (player_id, p_cleanGame.black_elo, d)
    db.insert_title (player_id, p_cleanGame.black_title, d)
    p_cleanGame.black_player_id = player_id

def insert_positions(p_game, p_game_id):
    game = p_game.next()
    while game != None:
        position = db.PositionRecord() 
        position.half_move_num = int(game.ply())
        #print("fullmove_number: ", math.ceil(position.half_move_num / 2))
        position.fen = game.board().fen()
        if position.half_move_num % 2 == 1:
            position.move_white = game.move
        else:
            position.move_black = game.move
        position.game_id = p_game_id
        db.insert_position(position)
        game = game.next()   

db.connect()
db.rollback() 
num = 0
with open("../data/export_total.pgn", encoding="utf8") as pgn:
    while True:
        num += 1
        game = chess.pgn.read_game(pgn)
        # If there are no more games, exit the loop
        #if game is None or num>1000:
        if game is None:
            break
        
        try:
            cleanGame = clean_game(game)
        except Exception as err:
            logging.error(f"Unexpected {err=}, {type(err)=}")
            logging.info("num: %d", num)
            for k, v in game.headers.items():
                logging.info("%s : %s", k, v)
                logging.info("")
            db.rollback()
            continue
       
        # no variants wanted
        if cleanGame.variant != "":
            continue

        upsert_players_info(cleanGame)
        game_id = db.insert_game (cleanGame)
        if (game_id != None):
            insert_positions(game, game_id)
        else:
            db.rollback()
            continue
        db.commit()        