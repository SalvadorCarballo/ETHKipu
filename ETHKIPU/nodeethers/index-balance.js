const { ethers } = require("ethers");

// Reemplaza con tu URL de Alchemy (En este caso usamos Scroll)
const alchemyUrl = 'https://scroll.drpc.org';

// Crear un proveedor usando la URL de Alchemy
const provider = new ethers.JsonRpcProvider(alchemyUrl);

// Indicar la cuenta de la que se quiere conocer el saldo
const address = "0x742d35Cc6634C0532925a3b844Bc454e4438f44e";

// Obtener el saldo de la cuenta
async function getBalance() {
  try {
    const balance = await provider.getBalance(address);
    console.log("Saldo de la cuenta:", ethers.formatEther(balance), "ETH");
  } catch (e) {
    console.error("Error al obtener el saldo de la cuenta", e);
  }
}

getBalance();