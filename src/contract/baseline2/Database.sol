pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

/* import "./GeneDrugLib.sol"; */

library Database{
    struct Table {
        mapping (string => uint[]) indexes;
    }
    
    // maybe change storage to memory??
    function insert(Table storage self, string memory key, uint index) internal {
        self.indexes[key].push(index);
    }

    function query(Table storage self, string memory key) internal view returns(uint[] memory) {
        return self.indexes[key];        
    }
     
}
