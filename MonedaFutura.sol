pragma solidity ^0.4.24;

contract MonedaFutura is Owned {
    mapping(uint => uint) valorToken; // mapa tiempo -> valor

    function ejecutarRegresion() private {
        return; // TODO
    }

    // -----------------------------------------------------------------------
    // Este método será un método “gratuito” (no consumirá ether) y
    // devolverá el valor del token, para un fecha t pasada por parámetro.
    // -----------------------------------------------------------------------
    function calcularValorFuturo(uint t) public returns (uint valorFuturo) {
        return valor[t]; // TODO
    }

    // -----------------------------------------------------------------------
    // comprarMonedaFutura(fecha, cantidad): Este es un método payable, 
    // el precio estará dado por la función calcularValorFuturo. 
    // Y lo que hará es dejar asentado que una dirección dada compró 
    // “cantidad” de tokens para la fecha estipulada por parámetro. 
    // No podrá comprar a más de 90 días.
    // -----------------------------------------------------------------------
    function comprarMonedaFutura(uint t, uint cantidad) public payable {
        return; // TODO
    }

    // -----------------------------------------------------------------------
    // consultarMisComprasFuturas(): método gratuito. Qué permitirá a una 
    // dirección (cuenta de etherum), visualizar todas las compras futuras 
    // que tiene por cobrar. Indicando si ya puede cobrarla o no.
    // -----------------------------------------------------------------------
    function consultarMisComprasFuturas() public {
        return; // TODO
    }

    // -----------------------------------------------------------------------
    // consultarTodasLasComprasFuturas(): método que podrá ejecutar el dueño 
    // del contrato para ver todas las compras futuras no ejecutadas aun.
    // -----------------------------------------------------------------------
    function consultarTodasLasComprasFuturas() public {
        require(msg.sender == owner);
        return; // TODO
    }

    // -----------------------------------------------------------------------
    // ejecutarMisContratos(): método que podrá ejecutar una dirección para 
    // que se acrediten en su cuenta todos los tokens comprados con comprarMonedaFutura().
    // Siempre y cuando la fecha ya haya pasado.
    // -----------------------------------------------------------------------
    function ejecutarMisContratos() public {
        return; // TODO
    }

    // -----------------------------------------------------------------------
    // ejecutarTodosLosContratos(): método que podrá ejecutar el dueño del contrato. 
    // Deposita todos los tokens comprados a futuro, siempre que la fecha se haya cumplido.
    // -----------------------------------------------------------------------
    function ejecutarTodosLosContratos() public {
        require(msg.sender == owner);
        return; // TODO
    }
}