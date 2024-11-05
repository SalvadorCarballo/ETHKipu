// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;
/*
Existen Diferencias?
Cual es más optimo?
*/
contract Storage1 {
    uint256 var1;
   
    function setVar1(uint256 _var1) external  {
        var1 = _var1;
    }


    function getVar1() external view returns(uint256) {
        return var1;
    }

    function setThisVar1(uint256 _var1) external {
        //var1 = _var1;
        this.setVar1(_var1);
    }

}


contract padre {
    string hola="soy el padre";
    function quienSoy() public view virtual  returns(string memory) { return(hola); }
}

contract madre {
    string hola2="soy la madre";
    function quienSoy() public view virtual returns(string memory) { return(hola2); }
}

contract hijo is madre, padre {
    string hola3="soy la Hijo";
    function quienSoy() public view override(madre, padre) returns (string memory) {
        return hola3;
        //return super.quienSoy(); }
    }
}



interface IERC20 {
    function balanceOf(address) external view returns (uint256);
}

abstract contract ERC20Base is IERC20 {
    uint internal balance=100;
}

contract ERC20 is ERC20Base {
    function balanceOf(address) external override  view returns (uint256) {
        return balance;
    }
}

contract ICO {
    IERC20 usdt;

    constructor(IERC20 _usdt) {
        usdt = _usdt;
    }

    function getBalance() public view returns (uint256) {
        return usdt.balanceOf(address(this));
    }
}