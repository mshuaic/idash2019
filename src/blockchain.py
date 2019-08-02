from database import Database
from node import Node


class Blockchain(Database):
    def __init__(self, **kwargs):
        self.proxy = Node(**kwargs)

    def insert(self, geneName: str, variantNumber: int, drugName: str, outcome: str, relation: bool, sideEffect: bool):
        return self.proxy.insert(geneName, variantNumber, drugName,
                                 outcome, relation, sideEffect)

    def query(self, geneName: str, variantNumber: str, drugName: str) -> str:
        return self.proxy.query(geneName, variantNumber, drugName)

    def setBlocking(self, value):
        self.proxy.blocking = value
