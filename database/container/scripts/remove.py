#!/usr/bin/env python3

import sys
import os
import subprocess
import pandas as pd
from sqlalchemy import create_engine, text

DB_USER = os.environ['DATABASE_USER']
DB_PASSWORD = os.environ['DATABASE_PASSWORD']
DB_NAME = os.environ['DATABASE_NAME']
SOCKET="/var/run/mysqld/mysql.sock"

def get_existing_study_ids(engine):
    """
    Returns a set of study IDs already present in the database.
    """
    query = text("SELECT study_id FROM studies")
    with engine.connect() as conn:
        result = conn.execute(query)
        return set(row[0] for row in result)

def remove_studies(engine, base_dir):
    print(f" Removing studies in {base_dir} ...")
    studies_file = os.path.join(base_dir, "studies.txt")
    df = pd.read_csv(studies_file, sep="\t")
    df.columns = df.columns.str.lower()
    existing_study_ids = get_existing_study_ids(engine)
    results_query =text("DELETE FROM results WHERE study_id = :study_id")
    study_query =text("DELETE FROM studies WHERE study_id = :study_id")
    with engine.connect() as conn:
        for study_id in set(df['study_id']):
            if study_id not in existing_study_ids:
                print(f"    Study {study_id} not found, skipping")
                continue
            print(f"    Removing study {study_id} ...")
            try:
                conn.execute(results_query, {"study_id": study_id})
                conn.execute(study_query, {"study_id": study_id})
                conn.commit()
            except Exception as e:
                print(f"    Error removing study: {e}")
                continue
            print(f"    Successfully removed")
        
def main():
    if len(sys.argv) != 2:
        print("Usage: python remove.py <directory>")
        sys.exit(1)

    path = sys.argv[1]

    try:
        engine = create_engine(
            f'mysql+pymysql://{DB_USER}:{DB_PASSWORD}@localhost/{DB_NAME}?unix_socket={SOCKET}'
        )
        if not os.path.exists(os.path.join(path,"studies.txt")):
            raise ValueError(f"Input file '{path}/studies.txt' does not exist.")
        remove_studies(engine, path)
                
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
