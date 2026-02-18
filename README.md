# chessAnalyzer
import huge pgn-Databases into SQL-Database for analysis and research purposes with Jupyter/Python/Stockfish

## Algorithmus zur Spielanalyse von Schachpartien

1. pgn-Partien einlesen und in Datenbank schreiben

    1. aus PGN Metainfo Spielerdaten extrahieren und ggf. in **player** Tabelle schreiben. Ggf. auch **elo** und **title** Tabellen ergänzen
    2. aus PGN Metainfo Spieldaten extrahieren und in **game** Tabelle schreiben.  
       Dabei "chess 960" und andere Varianten ignorieren.

2. Partien bestimmter Spieler analysieren

3. Statistische Analysen erstellen und grafisch aufbereiten

## Dokumentation
https://peter-kuehn.de/wiki/wer-ist-der-beste-schachspieler-aller-zeiten/
