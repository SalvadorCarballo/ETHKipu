// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleDEX {
    IERC20 public tokenA;  //ERC-20 token contracts that can be traded on the simpleDEX
    IERC20 public tokenB;  //ERC-20 token contracts that can be traded on the simpleDEX
    uint256 public balanceofA; //Stores the amount of tokenA in the liquidity pool
    uint256 public balanceofB; //Stores the amount of tokenA in the liquidity pool
    address public owner;

    event LiquidityAdded(uint256 amountA, uint256 amountB); // "Liquidity Increase" event
    event TokensSwappedAB(address indexed user, uint256 amountAIn, uint256 amountBOut); // Generates the event "Swap of tokens A for B"
    event TokensSwappedBA(address indexed user, uint256 amountBIn, uint256 amountAOut); // Generates the event "Swap of tokens B for A"
    event LiquidityRemoved(uint256 amountA, uint256 amountB); // "Decreased Liquidity" event

    //The contract receives the contract addresses of tokenA and tokenB as parameters
    constructor(address _tokenA, address _tokenB) { 
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        owner = msg.sender;
    }
    //Limits access only to the owner
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    //I verify that the contract has liquidity
    modifier EnoughLiquidity() {
        require(balanceofA > 0 && balanceofB > 0, "Not enough liquidity"); 
        _;
    }

    //add liquidity to the pool by depositing tokenA and tokenB amounts
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0"); //I request that the amounts of tokenA and tokenB be greater than 0

        tokenA.transferFrom(msg.sender, address(this), amountA); //transfer amountA of tokenA from the owner to the contract
        tokenB.transferFrom(msg.sender, address(this), amountB); //transfer amountB of tokenB from the owner to the contract

        balanceofA += amountA; //Update the balance in the tokenA pool
        balanceofB += amountB; //Update the balance in the tokenB pool

        emit LiquidityAdded(amountA, amountB); //generates "Liquidity Increase" event
    }

    //To swap tokenA for tokenB
    function swapAforB(uint256 amountAIn) external EnoughLiquidity {
        require(amountAIn > 0, "Amount must be greater than 0");//I request that tokenA amounts be greater than 0 for the swap

        //To calculate the amount of tokens that a user will receive when making the swap, according to (x+dx)*(y-dy) = x*y => dy = y-(x*y)/(x+dx)
        uint256 denominator = balanceofA + amountAIn; // (x+dx)
        uint256 fraction = (balanceofA * balanceofB) / denominator; // (x*y)/(x+dx)
        uint256 amountBOut = balanceofB - fraction; // dy=y-((x*y)/(x+dx))
        
        require(amountBOut > 0 && amountBOut <= balanceofB, "Invalid output amount"); //Check that "amountBout" is not negative and is less than the total balance of tokenB

        tokenA.transferFrom(msg.sender, address(this), amountAIn); //Transfer the amount "amountAIn" of tokenA from the user to the contract
        tokenB.transfer(msg.sender, amountBOut); //Send the amount "amountBOut" of tokenB to the user

        balanceofA += amountAIn; //Update the balance in the tokenA pool
        balanceofB -= amountBOut; //Update the balance in the tokenB pool

        emit TokensSwappedAB(msg.sender, amountAIn, amountBOut); //Generates the event "Swap of tokens A for B"
    }

    //To swap tokenB for tokenA
    function swapBforA(uint256 amountBIn) external EnoughLiquidity {
        require(amountBIn > 0, "Amount must be greater than 0");//I request that tokenB amounts be greater than 0 for the swap

        //To calculate the amount of tokens that a user will receive when making the swap, according to (x+dx)*(y-dy) = x*y => dX = (x*y)/(y-dy)-x
        uint256 denominator = balanceofB - amountBIn; // (y-dy)
        uint256 fraction = (balanceofA * balanceofB) / denominator; // (x*y)/(y-dy)
        uint256 amountAOut = fraction - balanceofA; // dx=((x*y)/(y-dy))-x

        require(amountAOut > 0 && amountAOut <= balanceofA, "Invalid output amount"); //Check that "amountAout" is not negative and is less than the total balance of tokenA

        tokenB.transferFrom(msg.sender, address(this), amountBIn); //Transfer the amount "amountBIn" of tokenB from the user to the contract
        tokenA.transfer(msg.sender, amountAOut); //Send the amount "amountAOut" of tokenB to the user

        balanceofB += amountBIn; //Update the balance in the tokenB pool
        balanceofA -= amountAOut; //Update the balance in the tokenA pool

        emit TokensSwappedBA(msg.sender, amountBIn, amountAOut); //Generates the event "Swap of tokens B for A"
    }

    //For the owner to withdraw liquidity
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner EnoughLiquidity {
        require(amountA <= balanceofA && amountB <= balanceofB, "Not enough liquidity"); //I check that the requested quantities are available
    
        balanceofA -= amountA; //Update the balance in the tokenA pool
        balanceofB -= amountB; //Update the balance in the tokenB pool

        tokenA.transfer(msg.sender, amountA); //I send the amount "amountA" to the owner
        tokenB.transfer(msg.sender, amountB); //I send the amount "amountB" to the owner

        emit LiquidityRemoved(amountA, amountB); //Generates "Decreased Liquidity" event
    }

    //Calculates the relative price of one token in relation to the other
    function getPrice(address _token) external view EnoughLiquidity returns (uint256) {
        require(_token == address(tokenA) || _token == address(tokenB), "Invalid token address"); //Requires tokenA or tokenB to be used
        
        if (_token == address(tokenA)) { //If it is tokenA, it returns the result of balanceB/balanceA
            return (balanceofB * 1e18) / balanceofA;
        } else { //If it is tokenB, it returns the result of balanceA/balanceB
            return (balanceofA * 1e18) / balanceofB;
        }
    }

}