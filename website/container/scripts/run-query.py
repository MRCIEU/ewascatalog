#!/usr/bin/env python3

import sys
import os
import MySQLdb


def main():
    if len(sys.argv) != 2:
        print("Usage: python prep.py <query>")
        sys.exit(1)

    query = sys.argv[1]

    try:
        conn = MySQLdb.connect(
            user=os.environ['DATABASE_USER'],
            password=os.environ['DATABASE_PASSWORD'],
            db=os.environ['DATABASE_NAME'],
            unix_socket='/var/run/mysql-shared/mysql.sock')

        cur = conn.cursor()
        cur.execute(query)
        results = cur.fetchall()
        print(results)
                
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()



