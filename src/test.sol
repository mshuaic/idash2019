pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "./Database.sol";
import "./GeneDrugLib.sol";
import "./Utils.sol";
import "./Math.sol";

contract test {
    event log(bytes);
    using Database for Database.Table;
    uint8 internal constant ATTRIBUTES_NUM = 3; 
    Database.Table[ATTRIBUTES_NUM] tables;
    // uint[] filter; 
    uint numObservations;
    mapping (address => uint) numObservationsFromSenders;
    // mapping (bytes => GeneDrugLib.Outcome[])  trial;
    
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
        GeneDrugLib.GeneDrug memory ob = GeneDrugLib.GeneDrug(geneName,Utils.uintToStr(variantNumber),drugName,outcome,suspectedRelation,seriousSideEffect);
        
        tables[uint(GeneDrugLib.attributes.geneName)].insert(geneName,ob);
        tables[uint(GeneDrugLib.attributes.variantNumber)].insert(Utils.uintToStr(variantNumber),ob);
        tables[uint(GeneDrugLib.attributes.drugName)].insert(drugName,ob);
        
        
        numObservations++;
        numObservationsFromSenders[msg.sender]++;

        
    }

    function query(GeneDrugLib.attributes attribute, string memory key) private view returns(GeneDrugLib.GeneDrug[] memory) {
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
        uint[] memory indexList;
        uint indexList_size;

        GeneDrugLib.GeneDrug[] memory observations;

        GeneDrugRelation[] memory result;         
        (indexList, indexList_size, observations) = intersect(geneName, variantNumber, drug);
        GeneDrugLib.Relation[] memory relations;
        GeneDrugLib.GeneDrug memory ob;
        uint size = indexList_size == 0 ? observations.length : indexList_size;
        result = new GeneDrugRelation[](size);
        relations = new GeneDrugLib.Relation[](size);
        uint num_unique_relations;
        bytes[] memory relations_bytes_arr = new bytes[](size);
        GeneDrugLib.Outcome[][] memory outcomes = new GeneDrugLib.Outcome[][](size);
        uint[] memory num_outcomes = new uint[](size);
        for (uint i=0;i<size;i++) {
            ob = indexList_size == 0 ? observations[i] : observations[indexList[i]];
            GeneDrugLib.Relation memory r = GeneDrugLib.Relation(ob.geneName, ob.variantNumber, ob.drugName);
            bytes memory relation_bytes = GeneDrugLib.convert(r);
            int index = Utils.contains(relations_bytes_arr, relation_bytes);
            if (index == -1) {
                relations_bytes_arr[num_unique_relations] = relation_bytes;
                relations[num_unique_relations] = GeneDrugLib.Relation(ob.geneName, ob.variantNumber, ob.drugName);
                // fix the size later
                outcomes[num_unique_relations] = new GeneDrugLib.Outcome[](size);
                outcomes[num_unique_relations][0] = GeneDrugLib.Outcome(ob.outcome, ob.suspectedRelation, ob.seriousSideEffect);
                num_outcomes[num_unique_relations]++;
                num_unique_relations++;
             } 
            //  else {
            //     outcomes[num_unique_relations][num_outcomes[num_unique_relations]] = GeneDrugLib.Outcome(ob.outcome, ob.suspectedRelation, ob.seriousSideEffect);
            // }
        }
        

        for(uint i=0; i< num_unique_relations; i++) {
            result[i] = getStat(relations[i],outcomes[i]);
        }
        return result;
    }

    function getStat(GeneDrugLib.Relation memory relation,
                     GeneDrugLib.Outcome[] memory outcomes) private pure
        returns(GeneDrugRelation memory){
        uint improvedCount;
        string memory improvedPercent;
        uint unchangedCount;
        string memory unchangedPercent;
        uint deterioratedCount;
        string memory deterioratedPercent;
        uint suspectedRelationCount;
        string memory suspectedRelationPercent;
        uint sideEffectCount;
        string memory sideEffectPercent;
        for (uint i=0;i<outcomes.length;i++) {
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
            improvedPercent = Math.div(improvedCount, outcomes.length);
            unchangedPercent = Math.div(unchangedCount, outcomes.length);
            deterioratedPercent = Math.div(deterioratedCount, outcomes.length);
            suspectedRelationPercent = Math.div(suspectedRelationCount, outcomes.length);
            sideEffectPercent = Math.div(sideEffectCount, outcomes.length);
        }

        return GeneDrugRelation(relation.geneName, Utils.strToUint(relation.variantNumber), relation.drugName, outcomes.length, improvedCount, improvedPercent, unchangedCount, unchangedPercent, deterioratedCount, deterioratedPercent, suspectedRelationCount, suspectedRelationPercent, sideEffectCount, sideEffectPercent);
    }
    
    
    function filer1(GeneDrugLib.attributes attribute, GeneDrugLib.GeneDrug[] memory data, string memory key) private view returns(uint[] memory, uint){
        uint index = 0;
        uint[] memory filter = new uint[](numObservations);
        for (uint i=0;i<data.length;i++){
            if ( (attribute == GeneDrugLib.attributes.geneName && Utils.equals(data[i].geneName,key) == true)
                || (attribute == GeneDrugLib.attributes.variantNumber && Utils.equals(data[i].variantNumber,key) == true)
                || (attribute == GeneDrugLib.attributes.drugName && Utils.equals(data[i].drugName,key) == true) ){
                filter[index++] = i;
            }
        }
        return (filter, index);
    }
    
    function fiter2(GeneDrugLib.attributes attribute, GeneDrugLib.GeneDrug[] memory data, string memory key, uint[] memory filter, uint filter_size) private pure  returns (bool){
        for (uint i=0;i<filter_size;i++){
            if ( (attribute == GeneDrugLib.attributes.geneName && Utils.equals(data[filter[i]].geneName,key) == true)
                || (attribute == GeneDrugLib.attributes.variantNumber && Utils.equals(data[filter[i]].variantNumber,key) == true)
                || (attribute == GeneDrugLib.attributes.drugName && Utils.equals(data[filter[i]].drugName,key) == true) ){
                    return true;
            }
        }
        return false;
    }

    function fiter3(GeneDrugLib.attributes attribute, GeneDrugLib.GeneDrug[] memory data, string memory key, uint[] memory filter, uint filter_size) private view returns (uint[] memory, uint){
        uint[] memory indexList = new uint[](numObservations);
        uint index;
        for (uint i=0;i<filter_size;i++){
            if ( (attribute == GeneDrugLib.attributes.geneName && Utils.equals(data[filter[i]].geneName,key) == true)
                || (attribute == GeneDrugLib.attributes.variantNumber && Utils.equals(data[filter[i]].variantNumber,key) == true)
                || (attribute == GeneDrugLib.attributes.drugName && Utils.equals(data[filter[i]].drugName,key) == true) ){
                indexList[index++] = i;
            }
        }
        return (indexList, index);
    }
    
    function intersect(string memory geneName,
                       string memory variantNumber,
                       string memory drugName
                       ) public view returns(uint[] memory, uint, GeneDrugLib.GeneDrug[] memory) {
        GeneDrugLib.GeneDrug[] memory result;
        uint filter_size = 0;
        uint[] memory filter;
        // emit debug("hellow");
        if (Utils.isStar(geneName) == false) {
            result = query(GeneDrugLib.attributes.geneName,geneName);
            if (Utils.isStar(variantNumber) == false) {
                // emit debug("variantNumber != star");
                (filter, filter_size) = filer1(GeneDrugLib.attributes.variantNumber, result, variantNumber);
                if  (Utils.isStar(drugName) == false) {
                    (filter, filter_size) = fiter3(GeneDrugLib.attributes.drugName, result, drugName,filter,filter_size);
                    return (filter, filter_size, result);
                } else {
                    // emit debug("no bug");
                    return (new uint[](0), 0, result);
                }
            } else {
                // emit debug("variantNumber == star");
                if (Utils.isStar(drugName) == false) {
                    (filter, filter_size) = filer1(GeneDrugLib.attributes.drugName, result, drugName);
                    return (filter, filter_size, result);
                } else {
                    return (new uint[](0), 0, result);
                }
            }
            
        } else {
            // emit debug("genename == star");
            if (Utils.isStar(variantNumber) == false) {
                result = query(GeneDrugLib.attributes.variantNumber,variantNumber);
                if  (Utils.isStar(drugName) == false) {
                    (filter, filter_size) = filer1(GeneDrugLib.attributes.drugName, result, drugName);
                    return (filter, filter_size, new GeneDrugLib.GeneDrug[](0));
                } else {
                    return (new uint[](0), 0, result);
                }
            } else {
                if (Utils.isStar(drugName) == false) {
                    result = query(GeneDrugLib.attributes.drugName,drugName);
                    return (new uint[](0), 0, result);
                } else {
                    return (new uint[](0), 0, new GeneDrugLib.GeneDrug[](0));
                }
            }
        }
    }


    function entryExists(
                         string memory geneName,
                         string memory variantNumber,
                         string memory drugName
                         ) public view returns (bool){
        GeneDrugLib.GeneDrug[] memory result;
        uint filter_size = 0;
        uint[] memory filter;
        // emit debug("hellow");
        if (Utils.isStar(geneName) == false) {
            result = query(GeneDrugLib.attributes.geneName,geneName);
            if (Utils.isStar(variantNumber) == false) {
                // emit debug("variantNumber != star");
                (filter, filter_size) = filer1(GeneDrugLib.attributes.variantNumber, result, variantNumber);
                if  (Utils.isStar(drugName) == false) {
                    // emit debug("bug");
                    return fiter2(GeneDrugLib.attributes.drugName, result, drugName,filter,filter_size);
                } else {
                    // emit debug("no bug");
                    return result.length > 0;
                }
            } else {
                // emit debug("variantNumber == star");
                if (Utils.isStar(drugName) == false) {
                    (, filter_size) = filer1(GeneDrugLib.attributes.drugName, result, drugName);
                    return filter_size > 0;
                } else {
                    return result.length > 0;
                }
            }
            
        } else {
            // emit debug("genename == star");
            if (Utils.isStar(variantNumber) == false) {
                result = query(GeneDrugLib.attributes.variantNumber,variantNumber);
                if  (Utils.isStar(drugName) == false) {
                    (, filter_size) = filer1(GeneDrugLib.attributes.drugName, result, drugName);
                    return filter_size > 0;
                } else {
                    return result.length > 0;
                }
            } else {
                if (Utils.isStar(drugName) == false) {
                    result = query(GeneDrugLib.attributes.drugName,drugName);
                    return result.length > 0;
                } else {
                    return numObservations>0;
                }
            }
        }
    }

    /** Return the total number of known relations, a.k.a. the number of unique geneName,-name, variant-number, drug-name pairs
     */
    function getNumRelations () public view returns(uint){
        // Code here
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
