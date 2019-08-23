from interface import interface
from pathlib import Path


class Node:
    def __init__(self, libraries, contract, **kwargs):
        self.interface = interface(**kwargs)
        self.interface.deploy_libraries(
            libraries)
        self.interface.publish(contract, Path(contract).stem)

    def insert(self, *args):
        return self.interface.send("insertObservation", *args)

    def query(self, *args):
        return self.interface.retrieve("query", *args)

    def getNumRelations(self):
        return self.interface.retrieve("getNumRelations")

    def getNumObservations(self):
        return self.interface.retrieve("getNumObservations")

    def wait_all(self, tx_hashs):
        return self.interface.wait_all(tx_hashs)

    def estimateGas(self, *args):
        return self.interface.estimateGas("query", *args)

    def setBlocking(self, value):
        self.interface.blocking = value
