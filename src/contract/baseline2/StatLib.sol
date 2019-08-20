pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "./Utils.sol";

library StatLib {
    struct Stat {
        string geneName;
        uint variantNumber;
        string drugName;
        uint totalCount;
        uint improvedCount;
        uint unchangedCount;
        uint deterioratedCount;
        uint suspectedRelationCount;
        uint sideEffectCount;
    }

    uint constant IMPROVED = 8;
    uint constant UNCHANGED = 9;
    uint constant DETERIORATED = 12;

    function update(Stat memory s, string memory outcome,
                    bool suspectedRelation, bool seriousSideEffect)
        internal pure returns(Stat memory) {
        s.improvedCount += Utils.equals(outcome, IMPROVED) ? 1 : 0;
        s.unchangedCount += Utils.equals(outcome, UNCHANGED) ? 1 : 0;
        s.deterioratedCount += Utils.equals(outcome, DETERIORATED) ? 1 : 0;
        s.suspectedRelationCount += suspectedRelation ? 1 : 0;
        s.sideEffectCount += seriousSideEffect ? 1 : 0;
        Stat memory stat = Stat(s.geneName, s.variantNumber,s.drugName, s.totalCount+1,s.improvedCount,s.unchangedCount,s.deterioratedCount,s.suspectedRelationCount,s.sideEffectCount);
        return stat;
    }

    function buildRelation(string memory geneName,
                           uint variantNumber,
                           string memory drugName,
                           string memory outcome, 
                           bool suspectedRelation,
                           bool seriousSideEffect) internal pure returns(bytes memory, Stat memory){
        uint improvedCount = Utils.equals(outcome, IMPROVED) ? 1 : 0;
        uint unchangedCount = Utils.equals(outcome, UNCHANGED) ? 1 : 0;
        uint deterioratedCount = Utils.equals(outcome, DETERIORATED) ? 1 : 0;
        uint suspectedRelationCount = suspectedRelation ? 1 : 0;
        uint sideEffectCount = seriousSideEffect ? 1 : 0;
        Stat memory stat = Stat(geneName,variantNumber,drugName,1,improvedCount,unchangedCount,deterioratedCount,suspectedRelationCount,sideEffectCount);
        return (abi.encodePacked(geneName, variantNumber, drugName), stat);
    }

}

