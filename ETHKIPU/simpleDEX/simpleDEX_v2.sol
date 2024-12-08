// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Simple Decentralized Exchange (DEX)
/// @notice This contract facilitates token swaps and liquidity management
/// @notice The comment format was updated according to the model that was indicated
/// @notice As suggested in the feedback, the Ownable library was added. When doing so, the compiler gave an error requesting that a parameter with the address of the initial owner of the contract be added to the constructor. It seems that the version of OpenZeppelin that I have in Remix does not automatically assign the person who deploys the contract as the initial owner
/// @dev Uses the constant product formula for swaps
/// @author Salvador Carballo

contract SimpleDEX is Ownable {
    /// @notice ERC-20 token A in the liquidity pool
    IERC20 public tokenA; 

    /// @notice ERC-20 token B in the liquidity pool
    IERC20 public tokenB;
    
    /// @notice Stores the amount of token A in the liquidity pool
    uint256 public balanceofA; 
    
    /// @notice Stores the amount of token B in the liquidity pool
    uint256 public balanceofB;

    /// @notice Emitted when liquidity is added
    /// @param amountA The amount of token A added to the pool
    /// @param amountB The amount of token B added to the pool
    event LiquidityAdded(uint256 amountA, uint256 amountB); 

    /// @notice Emitted when token A is swapped for token B
    /// @param user The address of the user performing the swap
    /// @param amountAIn The amount of token A swapped
    /// @param amountBOut The amount of token B received
    event TokensSwappedAB(address indexed user, uint256 amountAIn, uint256 amountBOut); 
    
    /// @notice Emitted when token B is swapped for token A
    /// @param user The address of the user performing the swap
    /// @param amountBIn The amount of token B swapped
    /// @param amountAOut The amount of token A received
    event TokensSwappedBA(address indexed user, uint256 amountBIn, uint256 amountAOut); 
    
    /// @notice Emitted when liquidity is removed
    /// @param amountA The amount of token A removed from the pool
    /// @param amountB The amount of token B removed from the pool
    event LiquidityRemoved(uint256 amountA, uint256 amountB);


    /// @notice Initializes the DEX with the two tokens and sets the initial owner
    /// @param _tokenA The address of token A
    /// @param _tokenB The address of token B
    /// @param initialOwner The address of the initial owner
    constructor(address _tokenA, address _tokenB, address initialOwner) Ownable(initialOwner) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    /// @notice Modifier to ensure sufficient liquidity in the pool
    modifier EnoughLiquidity() {
        require(balanceofA > 0 && balanceofB > 0, "Not enough liquidity"); 
        _;
    }

    /// @notice Adds liquidity to the pool
    /// @dev Only callable by the owner
    /// @param amountA The amount of token A to add
    /// @param amountB The amount of token B to add
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0"); 

        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        balanceofA += amountA;
        balanceofB += amountB;

        emit LiquidityAdded(amountA, amountB);
    }

    /// @notice Swaps token A for token B
    /// @param amountAIn The amount of token A to swap
    function swapAforB(uint256 amountAIn) external EnoughLiquidity {
        require(amountAIn > 0, "Amount must be greater than 0");

        /// @notice To calculate the amount of tokens that a user will receive when making the swap, according to (x+dx)*(y-dy) = x*y => dy = y-(x*y)/(x+dx)
        uint256 denominator = balanceofA + amountAIn; 
        uint256 fraction = (balanceofA * balanceofB) / denominator; 
        uint256 amountBOut = balanceofB - fraction; 

        require(amountBOut > 0 && amountBOut <= balanceofB, "Invalid output amount");

        tokenA.transferFrom(msg.sender, address(this), amountAIn);
        tokenB.transfer(msg.sender, amountBOut);

        balanceofA += amountAIn;
        balanceofB -= amountBOut;

        emit TokensSwappedAB(msg.sender, amountAIn, amountBOut);
    }

    /// @notice Swaps token B for token A
    /// @param amountBIn The amount of token B to swap
    function swapBforA(uint256 amountBIn) external EnoughLiquidity {
        require(amountBIn > 0, "Amount must be greater than 0");

        /// @notice To calculate the amount of tokens that a user will receive when making the swap, according to (x+dx)*(y-dy) = x*y => dX = (x*y)/(y-dy)-x
        uint256 denominator = balanceofB + amountBIn;
        uint256 fraction = (balanceofA * balanceofB) / denominator;
        uint256 amountAOut = balanceofA - fraction;

        require(amountAOut > 0 && amountAOut <= balanceofA, "Invalid output amount"); 

        tokenB.transferFrom(msg.sender, address(this), amountBIn); 
        tokenA.transfer(msg.sender, amountAOut);

        balanceofB += amountBIn;
        balanceofA -= amountAOut;

        emit TokensSwappedBA(msg.sender, amountBIn, amountAOut);
    }

    /// @notice Removes liquidity from the pool
    /// @dev Only callable by the owner
    /// @param amountA The amount of token A to remove
    /// @param amountB The amount of token B to remove
    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner EnoughLiquidity {
        require(amountA <= balanceofA && amountB <= balanceofB, "Not enough liquidity"); 

        balanceofA -= amountA;
        balanceofB -= amountB;

        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit LiquidityRemoved(amountA, amountB);
    }

    /// @notice Calculates the relative price of one token in terms of the other
    /// @param _token The address of the token to price
    /// @return The price of the token in terms of the other token
    function getPrice(address _token) external view EnoughLiquidity returns (uint256) {
        require(_token == address(tokenA) || _token == address(tokenB), "Invalid token address"); 

        if (_token == address(tokenA)) {
            return (balanceofB * 1e18) / balanceofA;
        } else { 
            return (balanceofA * 1e18) / balanceofB;
        }
    }
}
