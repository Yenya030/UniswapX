// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {LimitOrderReactorTest} from "./LimitOrderReactor.t.sol";
import {MockERC777Reentrant} from "../util/mock/MockERC777Reentrant.sol";
import {MockFillContractTokenReentrant} from "../util/mock/MockFillContractTokenReentrant.sol";
import {InputToken, ResolvedOrder, SignedOrder, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";

using OrderInfoBuilder for OrderInfo;

contract LimitOrderReactorTokenReentrancyTest is LimitOrderReactorTest {
    function testReentrancyDuringTransferFrom() public {
        MockERC777Reentrant reentrantToken = new MockERC777Reentrant("IN","IN",18);
        reentrantToken.mint(address(swapper), ONE);
        reentrantToken.forceApprove(swapper, address(permit2), type(uint256).max);

        MockFillContractTokenReentrant fill = new MockFillContractTokenReentrant(address(reactor));
        reentrantToken.setCallback(address(fill));
        tokenOut.mint(address(fill), ONE);

        ResolvedOrder memory order = ResolvedOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(address(swapper)).withDeadline(block.timestamp + 1000),
            input: InputToken(reentrantToken, ONE, ONE),
            outputs: OutputsBuilder.single(address(tokenOut), ONE, address(swapper)),
            sig: hex"",
            hash: bytes32(0)
        });
        (SignedOrder memory signed,) = createAndSignOrder(order);

        vm.expectRevert("TRANSFER_FROM_FAILED");
        fill.execute(signed);
    }
}
