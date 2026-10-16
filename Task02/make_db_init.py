import os
import time

DATASET_DIR = "dataset"
OUTPUT_SQL = "db_init.sql"

# Описание структуры таблиц и соответствующих файлов исходных данных
TABLES_CONFIG = {
    "movies": {
        "filename": "movies.csv",  # или movies.txt в зависимости от расширения
        "create_sql": """
CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT,
    year INTEGER,
    genres TEXT
);
"""
    },
    "ratings": {
        "filename": "ratings.csv",
        "create_sql": """
CREATE TABLE ratings (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    movie_id INTEGER,
    rating REAL,
    timestamp INTEGER
);
"""
    },
    "tags": {
        "filename": "tags.csv",
        "create_sql": """
CREATE TABLE tags (
    id INTEGER PRIMARY KEY,
    user_id INTEGER,
    movie_id INTEGER,
    tag TEXT,
    timestamp INTEGER
);
"""
    },
    "users": {
        "filename": "users.csv",
        "create_sql": """
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT,
    email TEXT,
    gender TEXT,
    register_date TEXT,
    occupation TEXT
);
"""
    }
}


def escape_sql(val):
    if val is None:
        return "NULL"
    if isinstance(val, (int, float)):
        return str(val)
    # Экранирование одинарных кавычек для SQL
    return f"'{str(val).replace("'", "''")}'"


def find_file(directory, base_name):
    """Ищет файл с именем base_name, возможно с другим расширением (.csv, .txt, .tsv)."""
    if not os.path.exists(directory):
        return None
    for f in os.listdir(directory):
        if f.lower().startswith(base_name.lower()):
            return os.path.join(directory, f)
    return None


def generate_sql():
    start_time = time.time()

    sql_lines = [
        "PRAGMA foreign_keys = OFF;",
        "BEGIN TRANSACTION;"
    ]

    # Удаление существующих таблиц
    for table_name in TABLES_CONFIG.keys():
        sql_lines.append(f"DROP TABLE IF EXISTS {table_name};")

    # Создание таблиц и наполнение данными
    for table_name, config in TABLES_CONFIG.items():
        sql_lines.append(config["create_sql"].strip())

        # Поиск файла данных (поддерживает .csv, .txt и т.д.)
        base_filename = os.path.splitext(config["filename"])[0]
        file_path = find_file(DATASET_DIR, base_filename)

        if file_path and os.path.exists(file_path):
            # Простейший парсер строк разделенных запятыми или табуляцией
            # Определяем разделитель по расширению или первой строке
            with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                lines = f.readlines()

            if lines:
                # Пробуем определить разделитель (, или \t или ;)
                sample = lines[0]
                delimiter = "\t" if "\t" in sample else (";" if ";" in sample else ",")

                # Пропускаем заголовок, если он есть (проверяем первое поле на числовой id)
                start_idx = 0
                first_parts = lines[0].strip().split(delimiter)
                if not first_parts[0].isdigit():
                    start_idx = 1

                for line in lines[start_idx:]:
                    line = line.strip()
                    if not line:
                        continue
                    parts = line.split(delimiter)
                    # Очищаем кавычки по краям значений, если они есть
                    cleaned_parts = [p.strip().strip('"\'') for p in parts]

                    # Формируем INSERT
                    values_sql = ", ".join([escape_sql(p if p != "" else None) for p in cleaned_parts])
                    sql_lines.append(f"INSERT INTO {table_name} VALUES ({values_sql});")

    sql_lines.append("COMMIT;")
    sql_lines.append("PRAGMA foreign_keys = ON;")

    with open(OUTPUT_SQL, "w", encoding="utf-8") as f:
        f.write("\n".join(sql_lines) + "\n")

    elapsed = time.time() - start_time
    print(f"SQL-скрипт успешно сгенерирован за {elapsed:.3f} сек.")


if __name__ == "__main__":
    generate_sql()