from nose.tools import *
import auditdb

def setUp(self):
    self.conn = psycopg2.connect(tests.dsn)
    self.conn.set_isolation_level(ISOLATION_LEVEL_SERIALIZABLE)
    curs = self.conn.cursor()
    curs.execute('''
        CREATE TEMPORARY TABLE table1 (
        id int PRIMARY KEY
    )''')

    # The constraint is set to deferrable for the commit_failed test
    curs.execute('''
        CREATE TEMPORARY TABLE table2 (
           id int PRIMARY KEY,
              table1_id int,
              CONSTRAINT table2__table1_id__fk
                FOREIGN KEY (table1_id) REFERENCES table1(id) DEFERRABLE)''')
        curs.execute('INSERT INTO table1 VALUES (1)')
        curs.execute('INSERT INTO table2 VALUES (1, 1)')
        self.conn.commit()

    def tearDown(self):
        self.conn.close()


def setup():
    print ("SETUP!")

def teardown():
    print ("TEAR DOWN!")

def test_basic():
    print ("I RAN!")

def test_dummie():
    assert 'b' == 'b'
