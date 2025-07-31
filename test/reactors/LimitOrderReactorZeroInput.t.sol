// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {LimitOrderReactorTest} from "./LimitOrderReactor.t.sol";
import {LimitOrder} from "../../src/lib/LimitOrderLib.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {OutputToken, InputToken, SignedOrder, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {NATIVE} from "../../src/lib/CurrencyLibrary.sol";

contract LimitOrderReactorZeroInputTest is LimitOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;

    function testExecuteZeroInput() public {
        // order specifies zero address as input token
        LimitOrder memory order = LimitOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            input: InputToken(ERC20(address(NATIVE)), 0, 0),
            outputs: OutputsBuilder.single(address(tokenOut), ONE, swapper)
        });
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        // Execute without expecting revert -- filler sends tokens without receiving input
        fillContract.execute(SignedOrder(abi.encode(order), sig));
        // verify filler lost tokens and swapper gained them
        assertEq(tokenOut.balanceOf(address(fillContract)), 0);
        assertEq(tokenOut.balanceOf(address(swapper)), ONE);
    }
}
