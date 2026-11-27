import csv
import os
import re

BATCH = 1000
OUT = "db_init.sql"
DATASET_DIR = "dataset"


def esc(s):
    if s is None:
        return "NULL"
    return "'" + str(s).replace("'", "''") + "'"


def val(v):
    if v is None:
        return "NULL"
    return str(v)


def write_table(f, name, columns, rows):
    col_names = ", ".join(c[0] for c in columns)
    cols_sql = ", ".join(f"{c[0]} {c[1]}" for c in columns)

    f.write(f"DROP TABLE IF EXISTS {name};\n")
    f.write(f"CREATE TABLE {name} ({cols_sql});\n")

    for i in range(0, len(rows), BATCH):
        chunk = rows[i:i + BATCH]
        values = ",\n".join("(" + ", ".join(r) + ")" for r in chunk)
        f.write(f"INSERT INTO {name} ({col_names}) VALUES\n{values};\n")

    f.write("\n")


def parse_movies():
    rows = []
    file_path = os.path.join(DATASET_DIR, "movies.csv")
    with open(file_path, encoding="utf-8", newline="") as f:
        for r in csv.DictReader(f):
            title = r["title"].strip()
            year = "NULL"
            m = re.search(r"\((\d{4})(?:[–-]\d{4})?\)$", title)
            if m:
                year = m.group(1)
                title = title[:m.start()].strip()
            rows.append((
                val(int(r["movieId"])),
                esc(title),
                year,
                esc(r["genres"]),
            ))
    return rows


def parse_ratings():
    rows = []
    file_path = os.path.join(DATASET_DIR, "ratings.csv")
    with open(file_path, encoding="utf-8", newline="") as f:
        for i, r in enumerate(csv.DictReader(f), start=1):
            rows.append((
                val(i),
                val(int(r["userId"])),
                val(int(r["movieId"])),
                val(float(r["rating"])),
                val(int(r["timestamp"])),
            ))
    return rows


def parse_tags():
    rows = []
    file_path = os.path.join(DATASET_DIR, "tags.csv")
    with open(file_path, encoding="utf-8", newline="") as f:
        for i, r in enumerate(csv.DictReader(f), start=1):
            rows.append((
                val(i),
                val(int(r["userId"])),
                val(int(r["movieId"])),
                esc(r["tag"]),
                val(int(r["timestamp"])),
            ))
    return rows


def parse_users():
    rows = []
    file_path = os.path.join(DATASET_DIR, "users.txt")
    with open(file_path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\r\n")
            if not line:
                continue
            uid, name, email, gender, register_date, occupation = line.split("|")
            rows.append((
                val(int(uid)),
                esc(name),
                esc(email),
                esc(gender),
                esc(register_date),
                esc(occupation),
            ))
    return rows


def main():
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write("BEGIN TRANSACTION;\n\n")

        write_table(f, "movies", [
            ("id", "INTEGER PRIMARY KEY"),
            ("title", "TEXT"),
            ("year", "INTEGER"),
            ("genres", "TEXT"),
        ], parse_movies())

        write_table(f, "ratings", [
            ("id", "INTEGER PRIMARY KEY"),
            ("user_id", "INTEGER"),
            ("movie_id", "INTEGER"),
            ("rating", "REAL"),
            ("timestamp", "INTEGER"),
        ], parse_ratings())

        write_table(f, "tags", [
            ("id", "INTEGER PRIMARY KEY"),
            ("user_id", "INTEGER"),
            ("movie_id", "INTEGER"),
            ("tag", "TEXT"),
            ("timestamp", "INTEGER"),
        ], parse_tags())

        write_table(f, "users", [
            ("id", "INTEGER PRIMARY KEY"),
            ("name", "TEXT"),
            ("email", "TEXT"),
            ("gender", "TEXT"),
            ("register_date", "TEXT"),
            ("occupation", "TEXT"),
        ], parse_users())

        f.write("COMMIT;\n")


if __name__ == "__main__":
    main()
