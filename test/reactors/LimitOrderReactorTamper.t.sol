// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {LimitOrderReactorTest} from "./LimitOrderReactor.t.sol";
import {LimitOrder, LimitOrderLib} from "../../src/lib/LimitOrderLib.sol";
import {OrderInfo, InputToken, OutputToken, SignedOrder} from "../../src/base/ReactorStructs.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {MockFillContractTamper} from "../util/mock/MockFillContractTamper.sol";

contract LimitOrderReactorTamperTest is LimitOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;
    using LimitOrderLib for LimitOrder;

    address attacker = address(0xdead);

    function testCallbackCanModifyOutputs() public {
        MockFillContractTamper fill = new MockFillContractTamper(address(reactor), attacker);
        tokenIn.forceApprove(swapper, address(permit2), ONE);
        tokenOut.mint(address(fill), ONE);

        LimitOrder memory order = LimitOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            input: InputToken(tokenIn, ONE, ONE),
            outputs: new OutputToken[](1)
        });
        order.outputs[0] = OutputToken(address(tokenOut), ONE, swapper);
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        bytes32 orderHash = order.hash();

        vm.expectEmit(false, true, true, false, address(reactor));
        emit Fill(orderHash, address(fill), swapper, order.info.nonce);
        fill.execute(SignedOrder(abi.encode(order), sig));

        assertEq(tokenOut.balanceOf(attacker), ONE);
        assertEq(tokenOut.balanceOf(swapper), 0);
    }
}
