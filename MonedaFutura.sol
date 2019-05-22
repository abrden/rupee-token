pragma solidity ^0.4.24;

contract MonedaFutura is Owned {
    
    using SafeMath for uint;
    using SafeMath for int;

    uint totalTransactions;
    int b; // desplazamiento recta regresion
    int m; // pendiente recta regresion
    // Precio = B + M * Fecha

    mapping(uint => uint) valorToken; // mapa tiempo -> valor
    
    struct Transaction {
      uint time;
      uint price;
    }

    struct Future {
      uint time;
      uint price;
      uint amount;

      bool done;
      address holder;
    }

    struct OwnerFutures {
      Future[] futures;
    }

    mapping(address => OwnerFutures) ownerFutures;

    Transaction[] transactions;

    constructor() public {
      totalTransactions = 0;
      b = 0;
      m = 0;
    }

    function ejecutarRegresion() public {
      require(totalTransactions >= 4,
              "No hay suficientes transacciones para ejecutar la regresion");

      uint price = 0;
      uint time = 0;
      uint tprice = 0;
      uint ttime = 0;

      for (uint i = transactions.length.sub(4); i < transactions.length; i++) {
        Transaction transaction = transactions[i];

        price = price.add(transaction.price);
        time = time.add(transaction.time);
        tprice = tprice.add(transaction.time.mul(transaction.price));
        ttime = ttime.add(transaction.time.mul(transaction.time));
      }

      b = price.sub((b.mul(time))).div(4);
      m = (4.mul(tprice).sub((time.mul(price)))).div((4.mul(ttime)).sub((time.mul(time))));
    }

    // -----------------------------------------------------------------------
    // Este método será un método “gratuito” (no consumirá ether) y
    // devolverá el valor del token, para un fecha t pasada por parámetro.
    // -----------------------------------------------------------------------
    function calcularValorFuturo(uint t) public view returns (uint valorFuturo) {
      return b.add(m.mul(t));
    }

    // -----------------------------------------------------------------------
    // comprarMonedaFutura(fecha, cantidad): Este es un método payable, 
    // el precio estará dado por la función calcularValorFuturo. 
    // Y lo que hará es dejar asentado que una dirección dada compró 
    // “cantidad” de tokens para la fecha estipulada por parámetro. 
    // No podrá comprar a más de 90 días.
    // -----------------------------------------------------------------------
    function comprarMonedaFutura(uint t, uint cantidad) public payable {
      require(t > now, "La fecha no puede haber pasado ya");
      require(t < now.add(90 days), "No se puede comprar para despues de 90 dias");

      uint price = calcularValorFuturo(t);
      ownerFutures[msg.sender].futures.push(Future(t, price, cantidad, false, msg.sender));
    }

    // -----------------------------------------------------------------------
    // consultarMisComprasFuturas(): método gratuito. Qué permitirá a una 
    // dirección (cuenta de etherum), visualizar todas las compras futuras 
    // que tiene por cobrar. Indicando si ya puede cobrarla o no.
    // -----------------------------------------------------------------------
    function consultarMisComprasFuturas() public view returns (Future[] memory) {
      for (uint i=0; i < ownerFutures[msg.sender].futures.length; i++) {
        if (ownerFutures[msg.sender].futures[i].time > now) {
          ownerFutures[msg.sender].futures[i].done = true;
        }
      }
      return ownerFutures[msg.sender].futures;
    }

    // -----------------------------------------------------------------------
    // consultarTodasLasComprasFuturas(): método que podrá ejecutar el dueño 
    // del contrato para ver todas las compras futuras no ejecutadas aun.
    // -----------------------------------------------------------------------
    function consultarTodasLasComprasFuturas() public onlyOwner {
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
    function ejecutarTodosLosContratos() public onlyOwner {
        return; // TODO
    }
}
