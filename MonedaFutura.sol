pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;

import "./ERC20Interface.sol";
import "./rupee.sol";

contract MonedaFutura is Owned {
    
    using SafeMath for uint;

    RupeeToken rupeeToken;

    uint totalTransactions;
    uint b; // desplazamiento recta regresion
    uint m; // pendiente recta regresion
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

      bool chargeable;
      bool consumed;
      address holder;
    }

    Future[] allFutures;

    Transaction[] transactions;

    constructor() public {
      totalTransactions = 0;
      b = 0;
      m = 0;
    }

    function ejecutarRegresion() public {
      uint max = 4;
      require(totalTransactions >= max,
              "No hay suficientes transacciones para ejecutar la regresion");

      uint price = 0;
      uint time = 0;
      uint tprice = 0;
      uint ttime = 0;

      for (uint i = transactions.length.sub(max); i < transactions.length; i++) {
        Transaction memory transaction = transactions[i];

        price = price.add(transaction.price);
        time = time.add(transaction.time);
        tprice = tprice.add(transaction.time.mul(transaction.price));
        ttime = ttime.add(transaction.time.mul(transaction.time));
      }

      b = price.sub((b.mul(time))).div(max);
      m = (max.mul(tprice).sub((time.mul(price)))).div((max.mul(ttime)).sub((time.mul(time))));
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
      allFutures.push(Future(t, price, cantidad, false, false, msg.sender));
    }

    // -----------------------------------------------------------------------
    // consultarMisComprasFuturas(): método gratuito. Qué permitirá a una 
    // dirección (cuenta de etherum), visualizar todas las compras futuras 
    // que tiene por cobrar. Indicando si ya puede cobrarla o no.
    // -----------------------------------------------------------------------
    function consultarMisComprasFuturas() public view returns (Future[] memory) {
      uint count = 0;
      for (uint i = 0; i < allFutures.length; i++) {
        if (allFutures[i].holder == msg.sender) {
          count = count + 1;
        }
      }
      
      Future[] memory futures = new Future[](count);
      count = 0; // Porque solidity es un parto para arrays dinamicos
      for (uint i = 0; i < allFutures.length; i++) {
        if (allFutures[i].holder == msg.sender) {
          Future memory future = allFutures[i];
          if (future.time < now) {
                future.chargeable = true;
          }
          futures[count++] = future;
        }
      }
      
      return futures;
    }

    // -----------------------------------------------------------------------
    // consultarTodasLasComprasFuturas(): método que podrá ejecutar el dueño 
    // del contrato para ver todas las compras futuras no ejecutadas aun.
    // -----------------------------------------------------------------------
    function consultarTodasLasComprasFuturas() public view onlyOwner returns (Future[] memory) {
      uint count = 0;
      for (uint i = 0; i < allFutures.length; i++) {
        Future memory future = allFutures[i];
        if (!future.consumed && future.time < now) {
          count = count + 1;
        }
      }
      
      Future[] memory futures = new Future[](count);
      count = 0; // Porque solidity es un parto para arrays dinamicos
      for (uint i = 0; i < allFutures.length; i++) {
        Future memory future = allFutures[i];
        if (!future.consumed && future.time < now) {
          futures[count++] = allFutures[i];
        }
      }
      return futures;
    }

    // -----------------------------------------------------------------------
    // ejecutarMisContratos(): método que podrá ejecutar una dirección para 
    // que se acrediten en su cuenta todos los tokens comprados con comprarMonedaFutura().
    // Siempre y cuando la fecha ya haya pasado.
    // -----------------------------------------------------------------------
    function ejecutarMisContratos() public {
      uint count = 0;
      for (uint i = 0; i < allFutures.length; i++) {
        Future memory future = allFutures[i];
        if (future.holder == msg.sender && !future.consumed && future.time < now) {
          count = count + 1;
        }
      }
      
      for (uint i = 0; i < allFutures.length; i++) {
        Future memory future = allFutures[i];
        if (future.holder == msg.sender && !future.consumed && future.time < now) {
          // Como ejecuto el future? -> seria aca.
          future.consumed = true;
        }
      }
    }

    // -----------------------------------------------------------------------
    // ejecutarTodosLosContratos(): método que podrá ejecutar el dueño del contrato. 
    // Deposita todos los tokens comprados a futuro, siempre que la fecha se haya cumplido.
    // -----------------------------------------------------------------------
    function ejecutarTodosLosContratos() public onlyOwner {
      uint count = 0;
      for (uint i = 0; i < allFutures.length; i++) {
        Future memory future = allFutures[i];
        if (!future.consumed && future.time < now) {
          count = count + 1;
        }
      }
      
      for (uint i = 0; i < allFutures.length; i++) {
        Future memory future = allFutures[i];
        if (!future.consumed && future.time < now) {
          // Como ejecuto el future? -> seria aca.
          future.consumed = true;
        }
      }
    }
}

