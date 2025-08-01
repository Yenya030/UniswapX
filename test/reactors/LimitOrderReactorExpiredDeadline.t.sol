// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {LimitOrderReactorTest} from "./LimitOrderReactor.t.sol";
import {LimitOrder} from "../../src/lib/LimitOrderLib.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {InputToken, OrderInfo, SignedOrder} from "../../src/base/ReactorStructs.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {OrderQuoterTest, SignatureExpired} from "../lib/OrderQuoter.t.sol";

contract LimitOrderReactorExpiredDeadlineTest is LimitOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;

    function testExecuteExpiredDeadline() public {
        tokenIn.forceApprove(swapper, address(permit2), ONE);
        uint256 deadline = block.timestamp - 1;
        LimitOrder memory order = LimitOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper).withDeadline(deadline),
            input: InputToken(tokenIn, ONE, ONE),
            outputs: OutputsBuilder.single(address(tokenOut), ONE, swapper)
        });
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        vm.expectRevert(abi.encodeWithSelector(SignatureExpired.selector, deadline));
        fillContract.execute(SignedOrder(abi.encode(order), sig));
    }
}