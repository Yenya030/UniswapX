// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {PriorityOrderReactorTest} from "./PriorityOrderReactor.t.sol";
import {PriorityOrder, PriorityInput, PriorityOutput, PriorityCosignerData} from "../../src/lib/PriorityOrderLib.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {InputToken, OrderInfo, SignedOrder} from "../../src/base/ReactorStructs.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {PriorityOrderReactor} from "../../src/reactors/PriorityOrderReactor.sol";

contract PriorityOrderReactorExpiredDeadlineTest is PriorityOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;

    function testExecuteExpiredDeadline() public {
        tokenIn.forceApprove(swapper, address(permit2), ONE);
        uint256 deadline = block.timestamp - 1;
        PriorityOrder memory order = PriorityOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper).withDeadline(deadline),
            cosigner: address(0),
            auctionStartBlock: block.number,
            baselinePriorityFeeWei: 0,
            input: PriorityInput(tokenIn, ONE, 0),
            outputs: OutputsBuilder.singlePriority(address(tokenOut), ONE, 0, swapper),
            cosignerData: PriorityCosignerData({auctionTargetBlock: 0}),
            cosignature: bytes("")
        });
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        vm.expectRevert(PriorityOrderReactor.InvalidDeadline.selector);
        fillContract.execute(SignedOrder(abi.encode(order), sig));
    }
}
