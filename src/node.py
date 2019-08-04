from interface import interface
from utils import attribute, outcome
from pathlib import Path


BASELINE = 'baseline2'
LIBRARIES = ['Database.sol', 'Utils.sol',
             'GeneDrugLib.sol', 'Math.sol', 'StatLib.sol']
CONTRACT = f"{BASELINE}.sol"
CONTRACT_DIR = f"./contract/{BASELINE}"
LIBRARIES = list(
    map(lambda x: str(Path(CONTRACT_DIR).joinpath(x).resolve()), LIBRARIES))

CONTRACT = str(Path(CONTRACT_DIR).joinpath(CONTRACT).resolve())


class Node:
    def __init__(self, libraries=LIBRARIES, contract=CONTRACT, **kwargs):
        self.interface = interface(**kwargs)
        self.interface.deploy_libraries(
            libraries)
        self.interface.publish(CONTRACT, Path(CONTRACT).stem)
        # self.contract = self.interface(tx_receipt, contract_interface)

    def insert(self, *args):
        return self.interface.send("insertObservation", *args)

    def query(self, *args):
        return self.interface.retrieve("query", *args)

    def setBlocking(self, value):
        self.interface.blocking = value
