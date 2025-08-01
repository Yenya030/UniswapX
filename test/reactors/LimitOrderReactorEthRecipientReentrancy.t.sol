// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {LimitOrderReactorTest} from "./LimitOrderReactor.t.sol";
import {LimitOrder} from "../../src/lib/LimitOrderLib.sol";
import {InputToken, OutputToken, OrderInfo, SignedOrder} from "../../src/base/ReactorStructs.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {MockRecipientReentrant} from "../util/mock/MockRecipientReentrant.sol";
import {CurrencyLibrary, NATIVE} from "../../src/lib/CurrencyLibrary.sol";

contract LimitOrderReactorEthRecipientReentrancyTest is LimitOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;

    function testReentrancyDuringNativeOutput() public {
        // prepare order
        tokenIn.forceApprove(swapper, address(permit2), ONE);
        vm.deal(address(fillContract), ONE);

        MockRecipientReentrant recipient = new MockRecipientReentrant(address(reactor));

        OutputToken[] memory outputs = new OutputToken[](1);
        outputs[0] = OutputToken(NATIVE, ONE, address(recipient));
        LimitOrder memory order = LimitOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            input: InputToken(tokenIn, ONE, ONE),
            outputs: outputs
        });
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);

        vm.expectRevert(CurrencyLibrary.NativeTransferFailed.selector);
        fillContract.execute(SignedOrder(abi.encode(order), sig));
    }
}
