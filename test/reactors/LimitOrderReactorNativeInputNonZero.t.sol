// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {LimitOrderReactorTest} from "./LimitOrderReactor.t.sol";
import {LimitOrder} from "../../src/lib/LimitOrderLib.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {InputToken, SignedOrder, OrderInfo, OutputToken} from "../../src/base/ReactorStructs.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {NATIVE} from "../../src/lib/CurrencyLibrary.sol";

contract LimitOrderReactorNativeInputNonZeroTest is LimitOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;

    function testExecuteNativeInputNonZeroAmount() public {
        uint256 startBalance = tokenOut.balanceOf(address(fillContract));
        // create order with native (zero address) input token and non-zero amount
        LimitOrder memory order = LimitOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            input: InputToken(ERC20(address(NATIVE)), ONE, ONE),
            outputs: OutputsBuilder.single(address(tokenOut), ONE, swapper)
        });
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        // filler executes order; call should not revert and filler receives no input
        fillContract.execute(SignedOrder(abi.encode(order), sig));
        // verify filler lost output tokens and received no native input
        assertEq(tokenOut.balanceOf(address(fillContract)), startBalance - ONE);
        assertEq(tokenOut.balanceOf(address(swapper)), ONE);
        assertEq(address(fillContract).balance, 0);
    }
}
