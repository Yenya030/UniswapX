// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ExclusiveDutchOrderReactorTest} from "./ExclusiveDutchOrderReactor.t.sol";
import {ExclusiveDutchOrder, DutchInput, DutchOutput} from "../../src/reactors/ExclusiveDutchOrderReactor.sol";
import {SignedOrder, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";

contract ExclusiveDutchOrderReactorZeroOutputsTest is ExclusiveDutchOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;

    function testExecuteNoOutputs() public {
        tokenIn.mint(address(swapper), ONE);
        tokenIn.forceApprove(swapper, address(permit2), ONE);
        ExclusiveDutchOrder memory order = ExclusiveDutchOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            decayStartTime: block.timestamp,
            decayEndTime: block.timestamp,
            exclusiveFiller: address(0),
            exclusivityOverrideBps: 300,
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
