import pandas as pd
from blockchain import Blockchain
from localDB import LocalDB, div
from utils import *
from logger import log
from tqdm import tqdm
import logging
import pytest
# log.setLevel(logging.DEBUG)
# log.setLevel(logging.ERROR)

data_dir = '/home/mark/sample'
sql = ["*", "42", "*"]


def convert_remix_input(line):
    remix = []
    for item in line:
        if type(item) == str:
            remix.append(f"\"{item}\"")
        else:
            remix.append(str(item).lower())

    return ','.join(remix)


def load_data(size=1):
    # data_file = '../sample/data0.txt'
    files = fileReader(data_dir)
    data = []
    for path in files.getFilePathes():
        with open(path, 'r') as f:
            data += f.readlines()

    records = []
    for d in data:
        line = d.strip('\n')
        line = line.split('\t')
        record = [attribute()._type()[i](line[i]) for i in range(len(line))]
        records.append(record)
    return records[:size]


def possibleKeys(key):
    result = []
    size = len(key)
    for i in range(2**size):
        tmp = []
        for j in range(size):
            if i & (1 << j) == (1 << j):
                tmp.append(str(key[j]))
            else:
                tmp.append("*")
        result.append(tmp)
    return result[1:]


# print(possibleKeys(["a", "b", "c"]))


def test_blockchain():
    bc = Blockchain()
    record = load_data()
    bc.insert(*record)
    print(bc.query("CETP", "*", "*"))


def test_bc_insertion():
    bc = Blockchain(blocking=False)
    # bc.setBlocking(False)
    records = load_data(1)
    for record in records:
        convert_remix_input(record)
        # input()
        bc.insert(*record)
    print(bc.query(*sql))


def test_localDB():
    db = LocalDB()
    record = load_data()
    db.insert(*record)
    print(db.query("CETP", "*", "*"))


def test_div():
    assert div(1, 2) == "0.500000"
    assert div(35, 3) == "11.666666"


def test_compare_single():
    bc = Blockchain(blocking=False)
    db = LocalDB()

    records = load_data(size=1)

    for record in tqdm(records):
        convert_remix_input(record)
        bc.insert(*record)
        db.insert(*record)

    log.debug("blockchain: %s" % bc.query(*sql))
    log.debug("localDB: %s" % db.query(*sql))
    assert bc.query(*sql) == db.query(*sql)


def test_compare_all(size):
    bc = Blockchain(blocking=False)
    db = LocalDB()

    records = load_data(size)

    for record in tqdm(records):
        log.debug(convert_remix_input(record))
        bc.insert(*record)
        db.insert(*record)

    assert bc.query("*", "*", "*") == db.query("*", "*", "*")

    for key in tqdm(db.getKeys()):
        pks = possibleKeys(key)
        for pk in pks:
            log.debug(convert_remix_input(pk))
            assert bc.query(*pk) == db.query(*pk)


def test_localDB_getKeys():
    db = LocalDB()
    records = load_data(10)
    for r in records:
        db.insert(*r)
    print(*db.getKeys(), sep='\n')
