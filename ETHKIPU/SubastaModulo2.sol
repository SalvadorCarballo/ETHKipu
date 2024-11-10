// SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;

contract SubastaFinal {

    // Variables de estado
    address public subastador; // owner del contrato
    address public mejorOfertante;
    uint256 public mejorOferta;
    uint256 public inicioTiempo = 1730894400; // Timestamp para 6 de noviembre de 2024, 12:00 GMT obtenido a traves de https://www.epochconverter.com/
    uint256 public finTiempo = inicioTiempo + (7 * 24 * 60 * 60); // La subasta finaliza 7 días despues del inicio, el dato se maneja en segundos (X días * 24 hs/día * 60 min/hs * 60 s/min)
    uint256 public ofertaMinima = 5000000000000000; // oferta minima en 0.005 ether expresado en wei
    uint256 public extensionTiempo = 10 * 60; // Extensión de 10 minutos 
    uint256 public previofinTiempo = 10 * 60; // Para control de 10 minutos antes de que finalice la subasta
    uint256 public porcentajeIncrementoMinimo = 5;
    uint256 public porcentajeComision = 2;
    bool public finalizada = false;

    struct Oferta {
        address ofertante; // Dirección del ofertante.
        uint256 monto; // la cantidad de ether ofertada.
    }

    Oferta[] public ofertas; // array de todas las ofertas realizadas
    mapping(address => uint256) public depositos; // Mapping para poder rastrear lo depositado por cada dirección.
    mapping(address => uint256) public ultimaOferta; // Mapping para poder rastrear la última oferta de cada participante

    // Eventos
    event NuevaOferta(address ofertante, uint256 monto);
    event SubastaFinalizada(address ganador, uint256 montoGanador);

    // Modificadores
    modifier soloSubastador() {
        require(msg.sender == subastador, "Solo el subastador puede ejecutar esta funcion");  // Solo permite interactuar al subastador (owner), sino es emite el mensaje
        _;
    }

    modifier subastaHaIniciado() {
        require(block.timestamp >= inicioTiempo, "La subasta aun no ha iniciado"); // El tiempo actual debe ser igual o superior al inicial, sino se emite el mensaje
        _;
    }

    modifier subastaActiva() {
        require(block.timestamp >= inicioTiempo && block.timestamp < finTiempo, "La subasta no esta activa"); // El tiempo actual debe ser igual o superior al inicial e inferior al final, sino se emite el mensaje
        _;
    }

    modifier subastaFinalizada() {
        require(finalizada, "La subasta aun no ha finalizado"); // Verifica el flag para ver si la subasta esta finalizada, sino se emite el mensaje
        _;
    }

    // Constructor
    constructor() {
        subastador = msg.sender;
    }

    // Función para ofertar
    function ofertar() external payable subastaHaIniciado subastaActiva {
        address _ofertante = msg.sender;
        uint256 _oferta= msg.value;
        require(_oferta >= ofertaMinima, "La oferta debe ser al menos el minimo de 0.005 ETH");
        require(_oferta >= mejorOferta + (mejorOferta * porcentajeIncrementoMinimo / 100), "La oferta debe ser al menos un 5% mayor que la mejor oferta actual");

        // Reembolsar el depósito del anterior mejor ofertante si no es la primera oferta
        if (mejorOfertante != address(0)) {
            depositos[mejorOfertante] += mejorOferta;
        }

        // Actualizar mejor oferta y ofertante
        mejorOfertante = _ofertante;
        mejorOferta = _oferta;
        ofertas.push(Oferta(_ofertante, _oferta));

        //depositos[_ofertante] += _oferta;
        ultimaOferta[_ofertante] = _oferta; // Registra la última oferta del ofertante

        emit NuevaOferta(_ofertante, _oferta);

        // Extender la subasta si quedan menos de 10 minutos (previofinTiempo)
        if (block.timestamp > finTiempo - previofinTiempo) {
            finTiempo += extensionTiempo;
        }
    }

    // Mostrar ganador
    function mostrarGanador() external view subastaFinalizada returns (address, uint256) {
        return (mejorOfertante, mejorOferta);
    }

    // Mostrar todas las ofertas
    function mostrarOfertas() external view returns (Oferta[] memory) {
        return ofertas; // devuelve el array de estructura de ofertante y oferta
    }

    // Mostrar ultima oferta realizada
    function mostrarultOferta(address _sender) external view returns (uint256) {
        return ultimaOferta[_sender]; // devuelve valor de ultima oferta realizada
    }

    // Finalizar subasta
    function finalizarSubasta() external soloSubastador subastaActiva {
        require(block.timestamp >= finTiempo, "La subasta aun esta en curso");
        finalizada = true;
        emit SubastaFinalizada(mejorOfertante, mejorOferta);

        // Transferir la mejor oferta al subastador
        payable(subastador).transfer(mejorOferta);
    }

    // Devolver depósitos a los que no ganaron, descontando una comisión del 2% (porcentajeComision)
    function devolverDepositos() external subastaFinalizada {
        address _sender = msg.sender;
        uint256 deposito = depositos[_sender];
        require(deposito > 0, "No tienes deposito para reclamar");
        
        uint256 reembolso = deposito * (100 - porcentajeComision) / 100; // descuenta el porcentaje de comisión
        payable(_sender).transfer(reembolso);
        depositos[_sender] = 0; // actualiza el deposito del sender a cero
    }

    // Reembolso parcial: permite retirar el excedente de la última oferta
    function reembolsoParcial(uint256 monto) external subastaActiva {
        address _sender = msg.sender;
        uint256 depositoDisponible = depositos[_sender] - ultimaOferta[_sender]; // Calcula el saldo disponible para retirar por sobre su ultima oferta

        require(monto <= depositoDisponible, "Monto mayor al deposito disponible por encima de tu ultima oferta");

        depositos[_sender] -= monto; // se descuenta el monto solicitado del deposito
        payable(_sender).transfer(monto);
    }
}

