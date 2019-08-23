from database import Database
import pandas as pd
from utils import attribute
from collections import namedtuple
import math
from logger import log


class LocalDB(Database):
    def __init__(self):
        self.db = pd.DataFrame(columns=attribute()._name())

    def insert(self, geneName: str, variantNumber: int, drugName: str, outcome: str, relation: bool, sideEffect: bool):
        # variantNumber = str(variantNumber)
        data = pd.Series(
            [geneName, variantNumber, drugName, outcome, relation, sideEffect], index=self.db.columns)
        self.db = self.db.append(data, ignore_index=True)

    def query(self, geneName: str, variantNumber: str, drugName: str) -> str:
        args = locals()
        if variantNumber != "*":
            variantNumber = int(variantNumber)
        del args['self']
        # followes pandas query convention col_name == @var
        sql = " and ".join(f"{name} == @{name}" for name,
                           val in args.items() if val != "*")
        if sql == "":
            result = self.db
        else:
            result = self.db.query(sql)
        log.debug(f"sql = {sql}")
        log.debug(result)
        observations = list(result.itertuples(index=False))
        Relation = namedtuple(
            'Relation', ["geneName", "variantNumber", "drugName"])
        Outcome = namedtuple('Outcome', ["outcome", "relation", "sideEffect"])
        relations = {}
        for ob in observations:
            relation = Relation(ob.geneName, ob.variantNumber, ob.drugName)
            outcome = Outcome(ob.outcome, ob.relation, ob.sideEffect)
            relations.setdefault(relation, []).append(outcome)
            # relations[relation].append(outcome)

        return self._get_stat(relations)
        # return list(result.itertuples(index=False, name=False))

    def getNumRelations(self):
        result = self.db
        observations = list(result.itertuples(index=False))
        Relation = namedtuple(
            'Relation', ["geneName", "variantNumber", "drugName"])
        relations = set()
        for ob in observations:
            relation = Relation(ob.geneName, ob.variantNumber, ob.drugName)
            relations.add(relation)
            # relations.setdefault(relation, []).append(outcome)

        return len(relations)

    def _get_stat(self, relations):
        result = []
        for relation, outcomes in relations.items():
            totalCount = len(outcomes)
            improvedCount = 0
            unchangedCount = 0
            deterioratedCount = 0
            suspectedRelationCount = 0
            sideEffectCount = 0
            for outcome in outcomes:
                if getattr(outcome, "outcome") == "IMPROVED":
                    improvedCount += 1
                elif getattr(outcome, "outcome") == "UNCHANGED":
                    unchangedCount += 1
                elif getattr(outcome, "outcome") == "DETERIORATED":
                    deterioratedCount += 1

                if getattr(outcome, "relation") == True:
                    suspectedRelationCount += 1
                if getattr(outcome, "sideEffect") == True:
                    sideEffectCount += 1

            improvedPercent = div(improvedCount, totalCount)
            unchangedPercent = div(unchangedCount, totalCount)
            deterioratedPercent = div(deterioratedCount, totalCount)
            suspectedRelationPercent = div(suspectedRelationCount, totalCount)
            sideEffectPercent = div(sideEffectCount, totalCount)
            result.append((relation) + (totalCount, improvedCount,
                                        improvedPercent, unchangedCount, unchangedPercent,
                                        deterioratedCount, deterioratedPercent, suspectedRelationCount,
                                        suspectedRelationPercent, sideEffectCount, sideEffectPercent))

        return result

    def getKeys(self):
        return list(self.db[['geneName', 'variantNumber', 'drugName']].itertuples(index=False, name=None))


def div(a, b):
    precision = 6
    if a / b == 0:
        return "0.000000"
    # return str(math.trunc(a/b)) + '.' + str(a*(10**precision)//b)[-precision:]

    return "%f" % round(a/b, 6)
