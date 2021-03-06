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
from pathlib import Path
# log.setLevel(logging.DEBUG)
# log.setLevel(logging.ERROR)

data_dir = '/home/mark/idash2019/data'
# sql = [["*", "*", "*"], ["CYP3A5", "*", ""]]
TRANSACTION_GAS = 21000

BASELINE = 'GeneDrugRepo'
CONTRACT = f"{BASELINE}.sol"
CONTRACT_DIR = f"./contract/{BASELINE}"
LIBRARIES = load_contracts(CONTRACT_DIR, suffix='.sol')
LIBRARIES.remove(Path(CONTRACT_DIR).joinpath(CONTRACT).resolve())
# LIBRARIES = ['Utils.sol', 'Math.sol']

# LIBRARIES = list(
# map(lambda x: str(Path(CONTRACT_DIR).joinpath(x).resolve()), LIBRARIES))

# LIBRARIES = None
CONTRACT = str(Path(CONTRACT_DIR).joinpath(CONTRACT).resolve())

BLOCKING = False

bc = Blockchain(blocking=BLOCKING, libraries=None,
                contract=CONTRACT, ipcfile='/home/mark/blockchain/eth/node0/geth.ipc', timeout=120)

# bc = Blockchain(blocking=BLOCKING, libraries=LIBRARIES,
# contract = CONTRACT)


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


def test_compare_single(size):
    # bc = Blockchain(blocking=False)
    db = LocalDB()

    records = load_data(size)

    tx_hashs = []
    for record in tqdm(records):
        convert_remix_input(record)
        r = bc.insert(*record)
        db.insert(*record)
        tx_hashs.append(r)

    bc.wait_all(tx_hashs)
    # time.sleep(5)
    # print()

    sql = ['*', '*', '*']
    log.debug("blockchain: %s" % bc.query(*sql))
    log.debug("localDB: %s" % db.query(*sql))

    assert bc.getNumRelations() == db.getNumRelations()
    # print(bc.query(*sql))
    print("num relations: ", bc.getNumRelations())
    print("num observations: ", bc.getNumObservations())
    # assert bc.query(*sql) == db.query(*sql)


def test_compare_all(size):
    # bc = Blockchain(blocking=True)
    db = LocalDB()

    records = load_data(size)

    start = time.time()
    tx_hashs = []
    totalGas = 0
    for record in tqdm(records):
        log.debug(convert_remix_input(record))
        with open("insertion.log", 'a') as f:
            f.write("%s\n" % convert_remix_input(record))
        r = bc.insert(*record)
        tx_hashs.append(r)
        # totalGas += (r['gasUsed'] - TRANSACTION_GAS)
        # print(r['gasUsed'])
        db.insert(*record)
    insertion_time = (time.time() - start)

    # time.sleep(60)
    bc.wait_all(tx_hashs)

    # print(bc.query("*", "*", "*"))
    # print(db.query("*", "*", "*"))

    assert bc.query("*", "*", "*") == db.query("*", "*", "*")
    assert bc.getNumRelations() == db.getNumRelations()
    assert bc.getNumRelations() != 0

    query_count = 0
    start = time.time()
    for key in tqdm(db.getKeys()):
        pks = possibleKeys(key)
        for pk in pks:
            with open("query.log", 'a') as f:
                f.write("%s\n" % convert_remix_input(pk))
            log.debug(convert_remix_input(pk))
            # print(bc.query(*pk))
            # print(db.query(*pk))
            assert bc.query(*pk) == db.query(*pk)
            query_count += 1
    query_time = time.time() - start


def test_localDB_getKeys():
    db = LocalDB()
    records = load_data(10)
    for r in records:
        db.insert(*r)
    print(*db.getKeys(), sep='\n')
