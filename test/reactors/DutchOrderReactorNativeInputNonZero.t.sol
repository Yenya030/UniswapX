// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {DutchOrderReactorTest} from "./DutchOrderReactor.t.sol";
import {DutchOrder, DutchInput} from "../../src/lib/DutchOrderLib.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {InputToken, SignedOrder, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {NATIVE} from "../../src/lib/CurrencyLibrary.sol";

contract DutchOrderReactorNativeInputNonZeroTest is DutchOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;

    function testExecuteNativeInputNonZeroAmount() public {
        uint256 startBalance = tokenOut.balanceOf(address(fillContract));
        DutchOrder memory order = DutchOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            decayStartTime: block.timestamp,
            decayEndTime: block.timestamp,
            input: DutchInput(ERC20(address(NATIVE)), ONE, ONE),
            outputs: OutputsBuilder.singleDutch(address(tokenOut), ONE, ONE, swapper)
        });
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        vm.expectRevert("TRANSFER_FROM_FAILED");
        fillContract.execute(SignedOrder(abi.encode(order), sig));
        assertEq(tokenOut.balanceOf(address(fillContract)), startBalance);
        assertEq(tokenOut.balanceOf(address(swapper)), 0);
    }
}
