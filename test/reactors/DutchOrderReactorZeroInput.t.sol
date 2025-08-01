// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {DutchOrderReactorTest} from "./DutchOrderReactor.t.sol";
import {DutchOrder, DutchInput, DutchOutput} from "../../src/reactors/DutchOrderReactor.sol";
import {SignedOrder, InputToken, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {NATIVE} from "../../src/lib/CurrencyLibrary.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract DutchOrderReactorZeroInputTest is DutchOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;

    function testExecuteZeroInput() public {
        tokenOut.mint(address(fillContract), ONE);
        // create order with zero address input token and zero amount
        DutchOrder memory order = DutchOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            decayStartTime: block.timestamp,
            decayEndTime: block.timestamp,
            input: DutchInput(ERC20(address(NATIVE)), 0, 0),
            outputs: OutputsBuilder.singleDutch(address(tokenOut), ONE, ONE, swapper)
        });
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        // Execute without revert -- filler sends output tokens without receiving input
        fillContract.execute(SignedOrder(abi.encode(order), sig));
        // verify filler lost tokens and swapper gained them
        assertEq(tokenOut.balanceOf(address(fillContract)), 0);
        assertEq(tokenOut.balanceOf(address(swapper)), ONE);
    }
}
