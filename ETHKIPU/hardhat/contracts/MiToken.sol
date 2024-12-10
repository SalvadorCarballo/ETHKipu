// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MiToken is ERC20("MiToken","MT"){

    constructor() {
        _mint(msg.sender, 100000000);
    }
}