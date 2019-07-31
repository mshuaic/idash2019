pragma solidity ^0.5.9;

library GeneDrugLib{
    struct GeneDrug {
        string geneName;
        uint variantNumber;
        string drugName;
        string outcome;
        bool suspectedRelation;
        bool seriousSideEffect;
    }

    enum OUTCOME {IMPROVED, UNCHANGED, DETERIORATED}
    
    struct Relation {
        string geneName;
        string variantNumber;
        string drugName;
    }
    
    struct Outcome {
        string outcome;
        bool suspectedRelation;
        bool seriousSideEffect;
    }

    
    struct Trial{
        mapping (bytes => Outcome[]) trial;
    }
    
    function convert(string memory geneName,
                     string memory variantNumber,
                     string memory drugName) internal pure returns(bytes memory){
        return abi.encode(geneName, variantNumber, drugName);
    }

    function convert(Relation memory r) internal pure returns(bytes memory){
        return abi.encode(r.geneName, r.variantNumber, r.drugName);
    }
    
    struct GeneDrug_bytes{
        bytes geneName;
        uint8 variantNumber;
        bytes drugName;
        uint8 outcome;
        bool suspectedRelation;
        bool seriousSideEffect;
    }

    enum attributes {geneName, variantNumber, drugName}

    // function convert(GeneDrug memory ori) public pure returns(GeneDrug memory){
    //     bytes memory tmp = abi.encode(ori.geneName,ori.variantNumber,ori.drugName,ori.outcome,ori.suspectedRelation,ori.seriousSideEffect);
    //     string memory geneName;
    //     uint variantNumber;
    //     string memory drugName;
    //     string memory outcome;
    //     bool suspectedRelation;
    //     bool seriousSideEffect;
    //     (geneName, variantNumber, drugName,outcome,suspectedRelation,seriousSideEffect) = abi.decode(tmp,(string,uint,string,string,bool,bool));
    //     return GeneDrug(geneName, variantNumber, drugName,outcome,suspectedRelation,seriousSideEffect);
        
    // }

}
