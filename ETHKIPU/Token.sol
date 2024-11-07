// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
//npm i @openzeppelin/contracts
contract ETHKIPUCOIN is ERC20, Ownable {
    constructor()
        ERC20("ETHKIPUCOIN", "EKC")
        Ownable(msg.sender)
    {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}
