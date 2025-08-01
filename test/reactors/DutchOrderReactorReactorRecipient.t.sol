// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {DutchOrderReactorTest} from "./DutchOrderReactor.t.sol";
import {DutchOrder, DutchInput, DutchOutput} from "../../src/reactors/DutchOrderReactor.sol";
import {SignedOrder, InputToken, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {NATIVE} from "../../src/lib/CurrencyLibrary.sol";

contract DutchOrderReactorReactorRecipientTest is DutchOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;

    function testReactorRecipientRefundsFiller() public {
        tokenIn.mint(address(swapper), ONE);
        tokenIn.forceApprove(swapper, address(permit2), ONE);
        vm.deal(address(fillContract), ONE);

        DutchOutput[] memory outputs = new DutchOutput[](1);
        outputs[0] = DutchOutput(NATIVE, ONE, ONE, address(reactor));
        DutchOrder memory order = DutchOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            decayStartTime: block.timestamp,
            decayEndTime: block.timestamp,
            input: DutchInput(tokenIn, ONE, ONE),
            outputs: outputs
        });
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);

        uint256 startBalance = address(fillContract).balance;
        fillContract.execute(SignedOrder(abi.encode(order), sig));

        assertEq(tokenIn.balanceOf(address(swapper)), 0);
        assertEq(tokenIn.balanceOf(address(fillContract)), ONE);
        assertEq(address(fillContract).balance, startBalance);
        assertEq(address(reactor).balance, 0);
    }
}
