// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {DutchOrderReactorTest} from "./DutchOrderReactor.t.sol";
import {DutchOrder, DutchInput, DutchOutput} from "../../src/reactors/DutchOrderReactor.sol";
import {SignedOrder, InputToken, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";

contract DutchOrderReactorZeroOutputsTest is DutchOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;

    function testExecuteNoOutputs() public {
        tokenIn.mint(address(swapper), ONE);
        tokenIn.forceApprove(swapper, address(permit2), ONE);
        DutchOrder memory order = DutchOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            decayStartTime: block.timestamp,
            decayEndTime: block.timestamp,
            input: DutchInput(tokenIn, ONE, ONE),
            outputs: new DutchOutput[](0)
        });
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        fillContract.execute(SignedOrder(abi.encode(order), sig));
        assertEq(tokenIn.balanceOf(address(swapper)), 0);
        assertEq(tokenIn.balanceOf(address(fillContract)), ONE);
        assertEq(tokenOut.balanceOf(address(swapper)), 0);
    }
}
