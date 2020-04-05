import datetime
import glob
import os
from pathlib import Path
import re
import sqlite3
import sys
import time


def main(db_file):
    """create a connection to SQLite database"""

    conn = None
    try:
        conn = sqlite3.connect(db_file)
    except Exception as e:
        print(e)

    c = conn.cursor()

    c.execute(
        '''
        CREATE VIRTUAL TABLE IF NOT EXISTS zevttelkasten
        USING fts5(title, body, tags, mtime UNINDEXED, prefix = 3, tokenize = "porter unicode61");
        '''
    )

    c.execute("""INSERT INTO zettelkasten (zettelkasten, rank) VALUES('rank', 'bm25(2.0, 1.0, 5.0, 0.0)');""")

    db_existing_files = c.execute("SELECT title, mtime FROM zettelkasten;")

    # parse the datetime from the database and convert to a integer-timestamp
    existing_files = {
        r[0]: int(datetime.datetime.strptime(r[1], "%Y-%m-%d %H:%M:%S").timestamp()) for r in db_existing_files
    }

    for file in glob.glob('*.md'):
        modified_time = time.strftime(
            "%Y-%m-%d %H:%M:%S",
            time.localtime(os.path.getmtime(file))
        )
        modified_timestamp = int(os.path.getmtime(file))

        # get the contents and tags of the file
        with open(file, 'r') as reader:
            file_content = reader.read()
            file_tags = " ".join(re.findall(r'#\S+', file_content))

        # if file isn't in db, add it to the database
        if file not in existing_files:
            c.execute(
                "INSERT INTO zettelkasten (title, body, tags, mtime) VALUES (?, ?, ?, ?);",
                (file, file_content, file_tags, modified_time)
            )
        # if the file is in the db, but it's modifed time is more recent than what's in the db,
        # updated it's record in the db
        elif modified_timestamp > existing_files[file]:
            c.execute(
                "UPDATE zettelkasten SET body = ?, tags = ?, mtime = ? WHERE title = ?;",
                (file_content, file_tags, modified_time, file)
            )

        existing_files[file] = 'VISITED'

    # remove the files from the db that are not in the updated map of files
    for file_title, file_timestamp_or_visited in existing_files.items():
        if file_timestamp_or_visited != "VISITED":
            c.execute("DELETE FROM zettelkasten WHERE title = ?;", (file_title,))

    ##############
    # File preview
    ##############

    # delete the "-f" flag from the arguments of this script beeing called
    # and assign it to a variable such that file_cat = '-f' if -f exists.  Otherwise file_cat == None
    file_cat = None
    # get only the arguments, b/c sys.argv has the script name as the first item in the list
    arguments = sys.argv[1:]
    for i, arg in enumerate(arguments):
        if arg == "-f":
            file_cat = arguments.pop(i)

    if file_cat:
        # if the second command argument exists
        if len(arguments) > 1:
            results = c.execute(
                "SELECT rank, highlight(zettelkasten, 1, '\x1b[0;41m', '\x1b[0m') FROM zettelkasten WHERE title = ? AND zettelkasten MATCH ? ORDER BY rank;",
                (file_cat[0], file_cat[1])
            )
        # This is when the script starts and there's no query input
        else:
            results = c.execute(
                "SELECT rank, body FROM zettelkasten WHERE title = ?;",
                (file_cat[0],)
            )
    elif len(arguments) > 0:
        results = c.execute(
            "SELECT rank, highlight(zettelkasten, 0, '\x1b[0;41m', '\x1b[0m') FROM zettelkasten WHERE zettelkasten MATCH {} ORDER BY rank;",
            (arguments[0],)
        )
    else:
        results = c.execute("SELECT title FROM zettelkasten;")

    for result in results:
        print(result[-1])

    conn.close()


if __name__ == '__main__':
    path = Path('./index.db')
    main(path)
