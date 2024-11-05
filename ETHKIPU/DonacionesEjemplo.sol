    // SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;

contract Donaciones {
    mapping(address => uint256) public balance;
    uint256 public vecesFallback;
    uint256 public vecesReceive;
    bytes public data;

    function setBalance(uint256 _balance) public {
        balance[msg.sender] = _balance;
    }

    fallback() external payable {
        vecesFallback++;
        data = msg.data;
    }

    receive() external payable {
        vecesReceive++;
    }

}
