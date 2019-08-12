pragma solidity ^0.5.9;

import "./Utils.sol";

library Math{
    uint constant precision = 6;
    uint constant multiplier = 10**precision;
    
    
    // unsafe division
    // truncates the remining digits
    function div(uint a, uint b) public pure returns(string memory){
        assert(a <= b);
        if (a == b) {
            return "1.000000";
        } else if (a == 0) {
            return "0";     
        }
        return round_up(a,b);
    }
    
    function uintToBytes(uint number) private pure returns(bytes memory) {
        return Utils.uintToBytes(number);
    }
    
    
    function truncate(uint a, uint b) private pure returns (string memory) {
        uint long_num = a * multiplier / b;
        bytes memory long_num_bytes = uintToBytes(long_num);
        return string(abi.encodePacked("0.",long_num_bytes));
    }
    
    function round_up(uint a, uint b) private pure returns(string memory) {
        uint long_num = a * multiplier * 10 / b;    
        long_num = (long_num+5) / 10 * 10 /10;
        bytes memory long_num_bytes = uintToBytes(long_num);
        return string(abi.encodePacked("0.",long_num_bytes));
    }
    
}
