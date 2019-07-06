pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

contract test {
    struct GeneDrug {
        string geneName;
        uint variantNumber;
        string drugName;
        string outcome;
        bool suspectedRelation;
        bool seriousSideEffect;
    }
    GeneDrug[] db;
    function insertObservation (
        string memory geneName,
        uint variantNumber,
        string memory drugName,
        string memory outcome,  // IMPROVED, UNCHANGED, DETERIORATED. This will always be capitalized, you don't have to worry about case.
        bool suspectedRelation,
        bool seriousSideEffect
    ) public {
        GeneDrug memory tmp = GeneDrug(geneName,variantNumber,drugName,outcome,suspectedRelation,seriousSideEffect);
        db.push(tmp);
    }

    function show() public view returns(GeneDrug[] memory){
        return db;
    }
}
