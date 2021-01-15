"""Classes for querying and storying SQL databases.

The response to an SQL query is a table. 
The 'response' class provides access to the table
similarly to a data.frame in R.

For example:

obj = response(db, "SELECT * FROM sky")
obj.nrow()
"""

class response:
    """Executes a query and provides access to the response table.

    Access to the reponse table is similar to a data.frame in R.

    Args:
    db (MySQLdb.connections.Connection): Database connection object.
    sql (str): SQL query.

    Attributes:
    db (MySQLdb.connections.Connection): Database connection object.
    sql (str): SQL query.
    cols (list): List of table column names.
    data (list): List of rows in the table.  Each row is a list of values.
    """
    def __init__(self, db, sql, cols=None, data=None):
        if cols is None:
            cur = db.cursor()      
            cur.execute(sql)
            self.cols = [x[0] for x in cur.description]
            self.data = list(cur.fetchall())
        else:
            self.cols = cols
            self.data = data
        if self.cols is None or self.data is None:
            self.cols = []
            self.data = []
        self.db = db
        self.sql = sql
    def copy(self):
        return response(self.db, self.sql, cols=self.cols, data=self.data)
    def nrow(self):
        """ Number of rows in the table. """
        return len(self.data)
    def ncol(self):
        """ Number of columns in the table. """
        return len(self.cols)
    def colnames(self):
        """ Column names in the table. """
        return self.cols;
    def row(self, idx):
        """ Contents of a specified row. """
        return self.data[idx]
    def col(self, colname):
        """ Contents of the specified column. """
        idx = self.cols.index(colname)
        return [row[idx] for row in self.data]
    def subset(self, rows=None, cols=None):
        """ Revise table to be a subset of rows and/or columns. 

        Args:
        rows (list): List of integers between 0 and nrow()-1.
        cols (list): List of column names from colnames().
        """
        if not rows is None:
            self.data = [self.row(i) for i in rows]

        if not cols is None:
            indices = [self.cols.index(colname) for colname in cols]
            self.data = [[row[idx] for idx in indices] for row in self.data]
            self.cols = cols
    def del_col(self, colname):
        """ Delete specified column from the table. """
        cidx = self.colnames().index(colname)
        for ridx in range(len(self.data)):
            del self.data[ridx][cidx]
        del self.cols[cidx]
    def set_col(self, colname, values):
        """ Specify values for new or existing column. """
        if not colname in self.colnames():
            self.cols.append(colname)
            for ridx in range(len(self.data)):
                self.data[ridx].append(values[ridx])
        else:
            cidx = self.colnames().index(colname)
            for ridx in range(len(self.data)):            
                self.data[ridx][cidx] = values[ridx]
    
        
class singleton_response(response):
    """ Executes query that supplies a single value

    Special case of 'response' for a query that returns a single value.
    """
    def __init__(self, db, sql):
        super().__init__(db, sql)
        if len(self.data) > 0:
            self.data = self.data[0][0]
            self.cols = self.cols[0]
    def value(self):
        """ Returns the single value query response. """
        return self.data
