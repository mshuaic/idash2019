pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "./Database.sol";
import "./GeneDrugLib.sol";
import "./Utils.sol";
import "./Math.sol";

contract test {
    using Database for Database.Table;
    uint8 internal constant ATTRIBUTES_NUM = 3; 
    Database.Table[ATTRIBUTES_NUM] tables;
    GeneDrugLib.GeneDrug[] data;
    uint numObservations;
    uint numRelations;
    mapping (address => uint) numObservationsFromSenders;
    
    event debug(string);    
    
    // This structure is how the data should be returned from the query function.
    // You do not have to store relations this way in your contract, only return them.
    // geneName and drugName must be in the same capitalization as it was entered. E.g. if the original entry was GyNx3 then GYNX3 would be considered incorrect.
    // Percentage values must be acurrate to 6 decimal places and will not include a % sign. E.g. "35.123456"
    struct GeneDrugRelation {
        string geneName;
        uint variantNumber;
        string drugName;
        uint totalCount;
        uint improvedCount;
        string improvedPercent;
        uint unchangedCount;
        string unchangedPercent;
        uint deterioratedCount;
        string deterioratedPercent;
        uint suspectedRelationCount;
        string suspectedRelationPercent;
        uint sideEffectCount;
        string sideEffectPercent;
    }
    
    function insertObservation (
                                string memory geneName,
                                uint variantNumber,
                                string memory drugName,
                                string memory outcome,  // IMPROVED, UNCHANGED, DETERIORATED. This will always be capitalized, you don't have to worry about case.
                                bool suspectedRelation,
                                bool seriousSideEffect
                                ) public {
        GeneDrugLib.GeneDrug memory ob = GeneDrugLib.GeneDrug(geneName,variantNumber,drugName,outcome,suspectedRelation,seriousSideEffect);

        data.push(ob);
        
        tables[uint(GeneDrugLib.attributes.geneName)].insert(geneName,numObservations);
        tables[uint(GeneDrugLib.attributes.variantNumber)].insert(Utils.uintToStr(variantNumber),numObservations);
        tables[uint(GeneDrugLib.attributes.drugName)].insert(drugName,numObservations);
        
        if (entryExists(geneName, Utils.uintToStr(variantNumber),drugName) == false) {
            numRelations++;
        }
        
        numObservations++;
        numObservationsFromSenders[msg.sender]++;

        
    }

    function query(GeneDrugLib.attributes attribute, string memory key) private view returns(uint[] memory) {
        return tables[uint(attribute)].query(key);
    }
    
    

        /** Takes geneName, variant-number, and drug-name as strings. A value of "*" for any name should be considered as a wildcard or alternatively as a null parameter.
        Returns: An array of GeneDrugRelation Structs which match the query parameters

        To clarify here are some example queries:
        query("CYP3A5", "52", "pegloticase") => An array of the one relation that matches all three parameters
        query("CYP3A5","52","*") => An array of all relations between geneName, CYP3A5, variant 52, and any drug
        query("CYP3A5","*","pegloticase") => An array of all relations between geneName, CYP3A5 and drug pegloticase, regardless of variant
        query("*","*","*") => An array of all known relations. 

        Note that capitalization matters. 
    */
    function query(
        string memory geneName,
        string memory variantNumber,
        string memory drug
    ) public view returns (GeneDrugRelation[] memory) {

        GeneDrugRelation[] memory result;
        
        uint[] memory indexList;
        uint size;
        (indexList, size) = query_private(geneName,variantNumber,drug);

        GeneDrugLib.Relation[] memory unique_relations = new GeneDrugLib.Relation[](size);
        bytes[] memory unique_relations_bytes = new bytes[](size);
        uint num_unique_relations;

        GeneDrugLib.Outcome[][] memory outcomes = new GeneDrugLib.Outcome[][](size);
        uint[] memory num_outcomes = new uint[](size);
        for (uint i=0;i<size;i++) {
            GeneDrugLib.GeneDrug memory ob = data[indexList[i]];
            GeneDrugLib.Relation memory r = GeneDrugLib.Relation(ob.geneName, Utils.uintToStr(ob.variantNumber), ob.drugName);
            bytes memory relation_bytes = GeneDrugLib.convert(r);
            int index = Utils.contains(unique_relations_bytes, relation_bytes);
            // not find 
            if (index == -1) {
                unique_relations_bytes[num_unique_relations] = relation_bytes;
                unique_relations[num_unique_relations] = r;

                outcomes[num_unique_relations] = new GeneDrugLib.Outcome[](size);
                outcomes[num_unique_relations][0] = GeneDrugLib.Outcome(ob.outcome, ob.suspectedRelation, ob.seriousSideEffect);
                num_outcomes[num_unique_relations]++;
                num_unique_relations++;
            } else {
                outcomes[uint(index)][num_outcomes[uint(index)]] = GeneDrugLib.Outcome(ob.outcome, ob.suspectedRelation, ob.seriousSideEffect);
                num_outcomes[uint(index)]++;
            }          
        }

        result = new GeneDrugRelation[](num_unique_relations);
        
        for(uint i=0; i< num_unique_relations; i++) {
            result[i] = getStat(unique_relations[i],outcomes[i],num_outcomes[i]);
        }
        return result;
    }

    function getStat(GeneDrugLib.Relation memory relation,
                     GeneDrugLib.Outcome[] memory outcomes, uint num_outcomes) private pure
        returns(GeneDrugRelation memory){
        uint improvedCount;
        uint unchangedCount;
        uint deterioratedCount;
        uint suspectedRelationCount;
        uint sideEffectCount;
        for (uint i=0;i<num_outcomes;i++) {
            if (Utils.equals(outcomes[i].outcome, "IMPROVED")) {
                improvedCount++;
            } else if (Utils.equals(outcomes[i].outcome, "UNCHANGED")) {
                unchangedCount++;
            } else {
                deterioratedCount++;
            }
            if (outcomes[i].suspectedRelation == true){
                suspectedRelationCount++;
            }
            if (outcomes[i].seriousSideEffect == true){
                sideEffectCount++;
            }
        }
        return GeneDrugRelation(relation.geneName, Utils.strToUint(relation.variantNumber),
                                relation.drugName, num_outcomes,
                                improvedCount, Math.div(improvedCount, num_outcomes),
                                unchangedCount, Math.div(unchangedCount, num_outcomes),
                                deterioratedCount, Math.div(deterioratedCount, num_outcomes),
                                suspectedRelationCount, Math.div(suspectedRelationCount, num_outcomes),
                                sideEffectCount, Math.div(sideEffectCount, num_outcomes));
    }    
    

    function query_private(
        string memory geneName,
        string memory variantNumber,
        string memory drugName) private view returns (uint[] memory, uint) {
        if (Utils.isStar(geneName) && Utils.isStar(variantNumber) && Utils.isStar(drugName)){
            uint[] memory list = new uint[](data.length);
            for (uint i=0;i<data.length;i++) {
                list[i] = i;
            }
            return (list,list.length);
        }

        uint[] memory geneList = Utils.isStar(geneName) ? new uint[](0) : query(GeneDrugLib.attributes.geneName, geneName);
        uint[] memory variantList = Utils.isStar(variantNumber) ? new uint[](0) : query(GeneDrugLib.attributes.variantNumber, variantNumber);
        uint[] memory drugList = Utils.isStar(drugName) ? new uint[](0) : query(GeneDrugLib.attributes.drugName, drugName);
        /* uint[][] memory lists = [geneList, variantList, drugList]; */
        uint  shortestListIndex = Utils.shortestList([geneList, variantList, drugList]);
        
        return Utils.intersect([geneList, variantList, drugList], shortestListIndex);
    }
    
    function entryExists(
                         string memory geneName,
                         string memory variantNumber,
                         string memory drugName
                         ) public view returns (bool){
        if (numObservations == 0) {
            return false;
        }
        uint size;
        (,size) = query_private(geneName,variantNumber,drugName);
        return size > 0;
            
    }

    /** Return the total number of known relations, a.k.a. the number of unique geneName,-name, variant-number, drug-name pairs
     */
    function getNumRelations () public view returns(uint){
        return numRelations;
    }
    
    /** Return the total number of recorded observations, regardless of sender.
     */
    function getNumObservations() public view returns (uint) {
        return numObservations;
    }

    /** Takes: A wallet address.
        Returns: The number of observations recorded from the provided wallet address
     */
    function getNumObservationsFromSender(address sender) public view returns (uint) {
        return numObservationsFromSenders[sender];
    }

}
