// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ExclusiveDutchOrderReactorTest} from "./ExclusiveDutchOrderReactor.t.sol";
import {ExclusiveDutchOrder, DutchInput, DutchOutput} from "../../src/reactors/ExclusiveDutchOrderReactor.sol";
import {SignedOrder, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {NATIVE} from "../../src/lib/CurrencyLibrary.sol";

contract ExclusiveDutchOrderReactorZeroInputTest is ExclusiveDutchOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;

    function testExecuteZeroInput() public {
        tokenOut.mint(address(fillContract), ONE);
        ExclusiveDutchOrder memory order = ExclusiveDutchOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            decayStartTime: block.timestamp,
            decayEndTime: block.timestamp,
            exclusiveFiller: address(0),
            exclusivityOverrideBps: 300,
            input: DutchInput(ERC20(address(NATIVE)), 0, 0),
            outputs: OutputsBuilder.singleDutch(address(tokenOut), ONE, ONE, swapper)
        });
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        fillContract.execute(SignedOrder(abi.encode(order), sig));
        assertEq(tokenOut.balanceOf(address(fillContract)), 0);
        assertEq(tokenOut.balanceOf(address(swapper)), ONE);
    }
}
