pragma solidity ^0.5.1;
pragma experimental ABIEncoderV2;

import "./ERC20Interface.sol";
import "./rupee.sol";

contract MonedaFutura is Owned, RupeeToken {
    
    using SafeMath for uint;

    uint totalTransacciones;
    uint b; // desplazamiento recta regresion
    uint m; // pendiente recta regresion
    // Precio = B + M * Fecha

    struct Transaccion {
      uint time;
      uint price;
    }

    Transaccion[] transacciones;

    struct Futura {
      uint time;
      uint price;
      uint amount;

      bool chargeable;
      bool consumed;
      address holder;
    }

    Futura[] futuras;

    constructor() public {
      totalTransacciones = 0;
      b = 0;
      m = 0;
    }

    function ejecutarRegresion() public {
      uint max = 4;
      require(totalTransacciones >= max,
              "No hay suficientes transacciones para ejecutar la regresion");

      uint price = 0;
      uint time = 0;
      uint tprice = 0;
      uint ttime = 0;

      for (uint i = transacciones.length.sub(max); i < transacciones.length; i++) {
        Transaccion memory transaccion = transacciones[i];

        price = price.add(transaccion.price);
        time = time.add(transaccion.time);
        tprice = tprice.add(transaccion.time.mul(transaccion.price));
        ttime = ttime.add(transaccion.time.mul(transaccion.time));
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
      futuras.push(Futura(t, price, cantidad, false, false, msg.sender));
    }

    // -----------------------------------------------------------------------
    // consultarMisComprasFuturas(): método gratuito. Qué permitirá a una 
    // dirección (cuenta de etherum), visualizar todas las compras futuras 
    // que tiene por cobrar. Indicando si ya puede cobrarla o no.
    // -----------------------------------------------------------------------
    function consultarMisComprasFuturas() public view returns (Futura[] memory) {
      uint count = 0;
      for (uint i = 0; i < futuras.length; i++) {
        if (futuras[i].holder == msg.sender) {
          count = count + 1;
        }
      }
      
      Futura[] memory futures = new Futura[](count);
      count = 0; // Porque solidity es un parto para arrays dinamicos
      for (uint i = 0; i < futuras.length; i++) {
        if (futuras[i].holder == msg.sender) {
          Futura memory future = futuras[i];
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
    function consultarTodasLasComprasFuturas() public view onlyOwner returns (Futura[] memory) {
      uint count = 0;
      for (uint i = 0; i < futuras.length; i++) {
        Futura memory future = futuras[i];
        if (!future.consumed && future.time < now) {
          count = count + 1;
        }
      }
      
      Futura[] memory futures = new Futura[](count);
      count = 0; // Porque solidity es un parto para arrays dinamicos
      for (uint i = 0; i < futuras.length; i++) {
        Futura memory future = futuras[i];
        if (!future.consumed && future.time < now) {
          futures[count++] = futuras[i];
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
      for (uint i = 0; i < futuras.length; i++) {
        Futura memory future = futuras[i];
        if (future.holder == msg.sender && !future.consumed && future.time < now) {
          count = count + 1;
        }
      }
      
      for (uint i = 0; i < futuras.length; i++) {
        Futura memory future = futuras[i];
        if (future.holder == msg.sender && !future.consumed && future.time < now) {
          transferFromOrigin(future.holder, future.price / future.amount);
          future.consumed = true;
          future.chargeable = true;
        }
      }
    }

    // -----------------------------------------------------------------------
    // ejecutarTodosLosContratos(): método que podrá ejecutar el dueño del contrato. 
    // Deposita todos los tokens comprados a futuro, siempre que la fecha se haya cumplido.
    // -----------------------------------------------------------------------
    function ejecutarTodosLosContratos() public onlyOwner {
      require(msg.sender == address(0), "No es el dueño de este contrato");
              
      uint count = 0;
      for (uint i = 0; i < futuras.length; i++) {
        Futura memory future = futuras[i];
        if (!future.consumed && future.time < now) {
          count = count + 1;
        }
      }
      
      for (uint i = 0; i < futuras.length; i++) {
        Futura memory future = futuras[i];
        if (!future.consumed && future.time < now) {
          transferFromOrigin(future.holder, future.price / future.amount);
          future.consumed = true;
          future.chargeable = true;
        }
      }
    }

    function buy() public payable returns (uint amount) {
      amount = msg.value / rupeePrice;
      balances[msg.sender] = balances[msg.sender].add(amount);
      balances[owner] = balances[owner].sub(amount);

      // Subir valor de moneda
      rupeePrice += 2;
      // Registrar transacción
      totalTransacciones++;
      transacciones.push(Transaccion(now, rupeePrice));

      emit Transfer(owner, msg.sender, amount);
      return amount;
    }

    function sell(uint amount) public returns (uint revenue) {
      balances[owner] = balances[owner].add(amount);
      balances[msg.sender] = balances[msg.sender].sub(amount);
      msg.sender.transfer(amount * rupeePrice);

      // Bajar valor de moneda
      if (rupeePrice > 0) {
        rupeePrice = rupeePrice - 2;
      }
      // Registrar transacción
      totalTransacciones++;
      transacciones.push(Transaccion(now, rupeePrice));

      emit Transfer(msg.sender, owner, amount);
      return revenue;
    }
}

