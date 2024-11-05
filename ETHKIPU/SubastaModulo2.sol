    // SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;

contract SubastaSC {

     // Variables de estado
    address public subastador;
    address public mejorOfertante;
    address public vendedor;
    uint public mejorOferta;
    uint public inicioTiempo = 1730894400; // Timestamp para 6 de noviembre de 2024, 12:00 UTC
    uint public finTiempo = inicioTiempo + 168 hours; // La subasta finaliza 168 horas después del inicio
    uint public ofertaMinima = 0.005 ether;
    uint public extensionTiempo = 10 minutes;
    uint public porcentajeIncrementoMinimo = 5;
    uint public porcentajeComision = 2;
    bool public finalizada = false;

    struct Oferta {
        address ofertante;
        uint monto;
    }

    Oferta[] public ofertas;
    mapping(address => uint) public depositos;

    // Eventos
    event NuevaOferta(address ofertante, uint monto);
    event SubastaFinalizada(address ganador, uint montoGanador);

    // Modificadores
    modifier soloSubastador() {
        require(msg.sender == subastador, "Solo el subastador puede ejecutar esta funcion");
        _;
    }

    modifier subastaHaIniciado() {
        require(block.timestamp >= inicioTiempo, "La subasta aun no ha iniciado");
        _;
    }

    modifier subastaActiva() {
        require(block.timestamp >= inicioTiempo && block.timestamp < finTiempo, "La subasta no esta activa");
        _;
    }

    modifier subastaFinalizada() {
        require(finalizada, "La subasta aun no ha finalizado");
        _;
    }

    // Constructor
    constructor(address _vendedor) {
        subastador = msg.sender;
        vendedor = _vendedor;
    }

    // Función para ofertar
    function ofertar() external payable subastaHaIniciado subastaActiva {
        require(msg.value >= ofertaMinima, "La oferta debe ser al menos el minimo de 0.005 ETH");
        require(msg.value >= mejorOferta + (mejorOferta * porcentajeIncrementoMinimo / 100), "La oferta debe ser al menos un 5% mayor que la mejor oferta actual");

        // Reembolsar el depósito del anterior mejor ofertante si no es la primera oferta
        if (mejorOfertante != address(0)) {
            depositos[mejorOfertante] += mejorOferta;
        }

        // Actualizar mejor oferta y ofertante
        mejorOfertante = msg.sender;
        mejorOferta = msg.value;
        ofertas.push(Oferta(msg.sender, msg.value));

        emit NuevaOferta(msg.sender, msg.value);

        // Extender la subasta si quedan menos de 10 minutos
        if (block.timestamp > finTiempo - 10 minutes) {
            finTiempo += extensionTiempo;
        }
    }

    // Mostrar ganador
    function mostrarGanador() external view subastaFinalizada returns (address, uint) {
        return (mejorOfertante, mejorOferta);
    }

    // Mostrar todas las ofertas
    function mostrarOfertas() external view returns (Oferta[] memory) {
        return ofertas;
    }

    // Finalizar subasta
    function finalizarSubasta() external soloSubastador subastaActiva {
        require(block.timestamp >= finTiempo, "La subasta aun esta en curso");
        finalizada = true;
        emit SubastaFinalizada(mejorOfertante, mejorOferta);

        // Transferir la mejor oferta al vendedor
        payable(vendedor).transfer(mejorOferta);
    }

    // Devolver depósitos a los que no ganaron, descontando una comisión del 2%
    function devolverDepositos() external subastaFinalizada {
        uint deposito = depositos[msg.sender];
        require(deposito > 0, "No tienes deposito para reclamar");
        
        depositos[msg.sender] = 0;
        uint reembolso = deposito - (deposito * porcentajeComision / 100);
        payable(msg.sender).transfer(reembolso);
    }

    // Reembolso parcial: permite retirar el excedente de la última oferta
    function reembolsoParcial(uint monto) external subastaActiva {
        uint depositoDisponible = depositos[msg.sender];
        require(depositoDisponible >= monto, "Monto mayor al deposito disponible");
        
        depositos[msg.sender] -= monto;
        payable(msg.sender).transfer(monto);
    }

}