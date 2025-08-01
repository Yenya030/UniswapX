// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {LimitOrderReactorTest} from "./LimitOrderReactor.t.sol";
import {LimitOrder} from "../../src/lib/LimitOrderLib.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {InputToken, OrderInfo, SignedOrder} from "../../src/base/ReactorStructs.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {NATIVE} from "../../src/lib/CurrencyLibrary.sol";

contract LimitOrderReactorZeroInputExpiredDeadlineTest is LimitOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;

    function testExecuteExpiredDeadlineZeroInput() public {
        uint256 deadline = block.timestamp - 1;
        LimitOrder memory order = LimitOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper).withDeadline(deadline),
            input: InputToken(ERC20(address(NATIVE)), 0, 0),
            outputs: OutputsBuilder.single(address(tokenOut), ONE, swapper)
        });
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        // Despite the expired deadline, execution succeeds because permit2 is not consulted.
        fillContract.execute(SignedOrder(abi.encode(order), sig));
        assertEq(tokenOut.balanceOf(address(fillContract)), 0);
        assertEq(tokenOut.balanceOf(address(swapper)), ONE);
    }
}
