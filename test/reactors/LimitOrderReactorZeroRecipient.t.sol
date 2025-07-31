// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {LimitOrderReactorTest} from "./LimitOrderReactor.t.sol";
import {LimitOrder} from "../../src/lib/LimitOrderLib.sol";
import {OutputToken, InputToken, SignedOrder, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";

contract LimitOrderReactorZeroRecipientTest is LimitOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;

    function testExecuteZeroRecipient() public {
        tokenIn.forceApprove(swapper, address(permit2), ONE);
        OutputToken[] memory outputs = new OutputToken[](1);
        outputs[0] = OutputToken(address(tokenOut), ONE, address(0));
        LimitOrder memory order = LimitOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            input: InputToken(tokenIn, ONE, ONE),
            outputs: outputs
        });
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        // Execute without expecting revert -- tokens are sent to the zero address
        fillContract.execute(SignedOrder(abi.encode(order), sig));
        // Verify that input tokens were transferred to the filler with no outputs produced
        assertEq(tokenIn.balanceOf(address(swapper)), 0);
        assertEq(tokenIn.balanceOf(address(fillContract)), ONE);
        assertEq(tokenOut.balanceOf(address(0)), ONE);
        assertEq(tokenOut.balanceOf(address(swapper)), 0);
    }
}
