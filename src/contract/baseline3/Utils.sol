pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

library Utils {    
    function uintToStr(uint v) internal pure returns (string memory){
        return string(uintToBytes(v));
    }
    
    function uintToBytes(uint _i) internal pure returns (bytes memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return bstr;
    }

    
    function strToUint(string memory s) internal pure returns (uint) {
        bytes memory b = bytes(s);
        uint result = 0;
        for (uint i = 0; i < b.length; i++) { // c = b[i] was not needed
            if (uint8(b[i]) >= 48 && uint8(b[i]) <= 57) {
                result = result * 10 + (uint8(b[i]) - 48); // bytes and int are not compatible with the operator -.
            }
        }
        return result; // this was missing
    }

    function equals(string memory a, uint length) internal pure returns (bool) {
      return bytes(a).length == length;
    }

    
    function isStar(string memory str) internal pure returns(bool) {
        bytes memory tmp = bytes(str);
        if (tmp.length > 1){
            return false;
        }
        bytes1 star = "*";
        return tmp[0] == star;
    }
}
