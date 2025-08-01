// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {LimitOrderReactorTest} from "./LimitOrderReactor.t.sol";
import {MockERC777Reentrant} from "../util/mock/MockERC777Reentrant.sol";
import {MockFillContractTokenReentrant} from "../util/mock/MockFillContractTokenReentrant.sol";
import {InputToken, ResolvedOrder, SignedOrder, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";

using OrderInfoBuilder for OrderInfo;

contract LimitOrderReactorOutputTokenReentrancyTest is LimitOrderReactorTest {
    function testReentrancyDuringOutputTransfer() public {
        MockERC777Reentrant reentrantToken = new MockERC777Reentrant("OUT","OUT",18);
        tokenIn.mint(address(swapper), ONE);
        tokenIn.forceApprove(swapper, address(permit2), type(uint256).max);

        MockFillContractTokenReentrant fill = new MockFillContractTokenReentrant(address(reactor));
        reentrantToken.mint(address(fill), ONE);
        reentrantToken.setCallback(address(fill));

        ResolvedOrder memory order = ResolvedOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(address(swapper)).withDeadline(block.timestamp + 1000),
            input: InputToken(tokenIn, ONE, ONE),
            outputs: OutputsBuilder.single(address(reentrantToken), ONE, address(fill)),
            sig: hex"",
            hash: bytes32(0)
        });
        (SignedOrder memory signed,) = createAndSignOrder(order);

        vm.expectRevert("TRANSFER_FROM_FAILED");
        fill.execute(signed);
    }
}
