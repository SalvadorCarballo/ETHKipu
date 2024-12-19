// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

// Interfaz del contrato Hacking2024
interface IContract {
    function retrieve() external payable;
    function mint(address to) external;
}

contract Proxy {
    address public target; // Dirección del contrato Hacking2024

    constructor(address _target) {
        target = _target; // Se inicializa con la dirección del contrato a intervenir
    }

    // Función para interactuar con retrieve
      function executeRetrieve() public payable {
    // Llama a la función retrieve del contrato a intervenir
    (bool success, ) = target.call{value: msg.value, gas: gasleft()}(
        abi.encodeWithSignature("retrieve()")
    );
    require(success, "Failed to send Ether");
}


    // Función para mintear un NFT
    function mintNFT() external {
        // Llama a la función mint del contrato a intervenir
        IContract(target).mint(msg.sender);
    }
}
