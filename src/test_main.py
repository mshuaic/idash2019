import pandas as pd
from blockchain import Blockchain
from localDB import LocalDB, div
from utils import *
from logger import log
from tqdm import tqdm
import logging
import pytest
import time
import json
# log.setLevel(logging.DEBUG)
# log.setLevel(logging.ERROR)

data_dir = '/home/mark/idash2019/sample/test'
sql = ["*", "42", "*"]
TRANSACTION_GAS = 21000


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
    bc = Blockchain(blocking=True)
    db = LocalDB()

    records = load_data(size)

    start = time.time()
    totalGas = 0
    for record in tqdm(records):
        log.debug(convert_remix_input(record))
        r = bc.insert(*record)
        totalGas += (r['gasUsed'] - TRANSACTION_GAS)
        # print(r['gasUsed'])
        db.insert(*record)
    insertion_time = (time.time() - start)

    assert bc.query("*", "*", "*") == db.query("*", "*", "*")

    query_count = 0
    start = time.time()
    for key in tqdm(db.getKeys()):
        pks = possibleKeys(key)
        for pk in pks:
            log.debug(convert_remix_input(pk))
            assert bc.query(*pk) == db.query(*pk)
            query_count += 1
    query_time = time.time() - start

    # result = {
    #     "data size": len(records),
    #     'total insert time': insertion_time,
    #     "insert time per record": insertion_time // len(records),
    #     "total storage used (in gas)": totalGas,
    #     "storage per record": totalGas // len(records),
    #     "total query time": query_time,
    #     "query time per record": query_time // query_count
    # }

    # with open("benchmark.json", 'w') as outfile:
    #     json.dump(result, outfile)


def test_localDB_getKeys():
    db = LocalDB()
    records = load_data(10)
    for r in records:
        db.insert(*r)
    print(*db.getKeys(), sep='\n')
