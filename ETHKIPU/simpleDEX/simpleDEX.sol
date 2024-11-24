// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SimpleDEX {
    IERC20 public tokenA;  //ERC-20 token contracts that can be traded on the simpleDEX
    IERC20 public tokenB;  //ERC-20 token contracts that can be traded on the simpleDEX
    uint256 public reserveA; //Stores the amount of tokenA in the liquidity pool
    uint256 public reserveB; //Stores the amount of tokenA in the liquidity pool
    address public owner;

    event LiquidityAdded(uint256 amountA, uint256 amountB); // "Liquidity Increase" event
    event TokensSwapped(address indexed user, uint256 amountIn, uint256 amountOut); // "Token Swap" event
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

    //add liquidity to the pool by depositing tokenA and tokenB amounts
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0"); //I request that the amounts of tokenA and tokenB be greater than 0

        tokenA.transferFrom(msg.sender, address(this), amountA); //transfer amountA of tokenA from the owner to the contract
        tokenB.transferFrom(msg.sender, address(this), amountB); //transfer amountB of tokenB from the owner to the contract

        reserveA += amountA; //Update the balance in the tokenA pool
        reserveB += amountB; //Update the balance in the tokenB pool

        emit LiquidityAdded(amountA, amountB); //generates "Liquidity Increase" event
    }

    //To swap tokenA for tokenB
    function swapAforB(uint256 amountAIn) external {
        require(amountAIn > 0, "Amount must be greater than 0");//I request that tokenA amounts be greater than 0 for the swap

        uint256 amountBOut = getSwapAmount(amountAIn, reserveA, reserveB); //use the getSwapAmount function to calculate how many tokenB the user will receive in swap
        tokenA.transferFrom(msg.sender, address(this), amountAIn); //Transfer the amount "amountAIn" of tokenA from the user to the contract
        tokenB.transfer(msg.sender, amountBOut); //Send the amount "amountBOut" of tokenB to the user

        reserveA += amountAIn; //Update the balance in the tokenA pool
        reserveB -= amountBOut; //Update the balance in the tokenB pool

        emit TokensSwapped(msg.sender, amountAIn, amountBOut); //Generates "Token Swap" event
    }

    //To swap tokenB for tokenA
    function swapBforA(uint256 amountBIn) external {
        require(amountBIn > 0, "Amount must be greater than 0");//I request that tokenB amounts be greater than 0 for the swap

        uint256 amountAOut = getSwapAmount(amountBIn, reserveB, reserveA); ////use the getSwapAmount function to calculate how many tokenB the user will receive in swap
        tokenB.transferFrom(msg.sender, address(this), amountBIn); //Transfer the amount "amountBIn" of tokenB from the user to the contract
        tokenA.transfer(msg.sender, amountAOut); //Send the amount "amountAOut" of tokenB to the user

        reserveB += amountBIn; //Update the balance in the tokenB pool
        reserveA -= amountAOut; //Update the balance in the tokenA pool

        emit TokensSwapped(msg.sender, amountBIn, amountAOut); //Generates "Token Swap" event
    }

    //For the owner to withdraw liquidity
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA <= reserveA && amountB <= reserveB, "Not enough liquidity"); //I check that the requested quantities are available

        reserveA -= amountA; //Update the balance in the tokenA pool
        reserveB -= amountB; //Update the balance in the tokenB pool

        tokenA.transfer(msg.sender, amountA); //I send the amount "amountA" to the owner
        tokenB.transfer(msg.sender, amountB); //I send the amount "amountB" to the owner

        emit LiquidityRemoved(amountA, amountB); //Generates "Decreased Liquidity" event
    }

    //Calculates the relative price of one token in relation to the other
    function getPrice(address _token) external view returns (uint256) {
        require(_token == address(tokenA) || _token == address(tokenB), "Invalid token address"); //Requires tokenA or tokenB to be used

        if (_token == address(tokenA)) { //If it is tokenA, it returns the result of balanceB/balanceA
            return reserveB / reserveA;
        } else { //If it is tokenB, it returns the result of balanceA/balanceB
            return reserveA / reserveB;
        }
    }

    //To calculate the amount of tokens that a user will receive when making the swap, according to (x+dx)*(y-dy) = x*y => dy = y-(x*y)/(x+dx)
   function getSwapAmount(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) private pure returns (uint256) {
    // amountIn: Amount of tokens that the user adds to the pool (dx)
    // reserveIn: Amount of tokens in the incoming token pool (x)
    // reserveOut: Amount of tokens in the token pool that is leaving (y)
    // amountOut: Amount of tokens that the user will receive from the pool (dy)
    uint256 denominator = reserveIn + amountIn; // (x+dx)
    uint256 fraction = (reserveIn * reserveOut) / denominator; // (x*y)/(x+dx)
    uint256 amountOut = reserveOut - fraction; // y-((x*y)/(x+dx))
    return amountOut; // dy
}


}