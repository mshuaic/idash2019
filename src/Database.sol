pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "./GeneDrugLib.sol";

library Database{
    struct Table {
        mapping (string => GeneDrugLib.GeneDrug[]) relation;
    }
    

    function insert(Table storage self, string memory key, GeneDrugLib.GeneDrug memory observation) public {
        self.relation[key].push(observation);
    }

    function query(Table storage self, string memory key) public view returns(GeneDrugLib.GeneDrug[] memory) {
        return self.relation[key];
    }
     
}
