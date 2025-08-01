// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {LimitOrderReactorTest} from "./LimitOrderReactor.t.sol";
import {SignedOrder, ResolvedOrder, InputToken, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {IReactor} from "../../src/interfaces/IReactor.sol";
import {MockValidationContractReentrant} from "../util/mock/MockValidationContractReentrant.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";

contract LimitOrderReactorValidationReentrancyTest is LimitOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;

    function testValidationReentrancy() public {
        // deploy reentrant validation contract
        MockValidationContractReentrant validator = new MockValidationContractReentrant(IReactor(address(reactor)));

        // prepare second order that will be executed during validation
        ResolvedOrder memory order2 = ResolvedOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(address(swapper)).withDeadline(block.timestamp + 1000).withNonce(1234),
            input: InputToken(tokenIn, ONE, ONE),
            outputs: OutputsBuilder.single(address(tokenOut), ONE, address(swapper)),
            sig: hex"00",
            hash: bytes32(0)
        });
        (SignedOrder memory signed2,) = createAndSignOrder(order2);
        validator.setOrder(signed2);

        // seed balances and approvals
        tokenIn.mint(address(swapper), 2 ether);
        tokenOut.mint(address(fillContract), 2 ether);
        tokenIn.forceApprove(swapper, address(permit2), type(uint256).max);

        // main order using the reentrant validator
        ResolvedOrder memory order1 = ResolvedOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(address(swapper)).withDeadline(block.timestamp + 1000).withValidationContract(validator),
            input: InputToken(tokenIn, ONE, ONE),
            outputs: OutputsBuilder.single(address(tokenOut), ONE, address(swapper)),
            sig: hex"00",
            hash: bytes32(0)
        });
        (SignedOrder memory signed1,) = createAndSignOrder(order1);

        vm.expectRevert("call failed");
        fillContract.execute(signed1);
    }
}
