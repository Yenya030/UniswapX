// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {PriorityOrderReactorTest} from "./PriorityOrderReactor.t.sol";
import {PriorityOrderLib, PriorityOrder, PriorityInput, PriorityCosignerData} from "../../src/lib/PriorityOrderLib.sol";
import {SignedOrder, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {NATIVE} from "../../src/lib/CurrencyLibrary.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract PriorityOrderReactorNativeInputNonZeroTest is PriorityOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;
    using PriorityOrderLib for PriorityOrder;

    function testExecuteNativeInputNonZeroAmount() public {
        PriorityCosignerData memory cosignerData = PriorityCosignerData({auctionTargetBlock: block.number});
        PriorityOrder memory order = PriorityOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            cosigner: vm.addr(cosignerPrivateKey),
            auctionStartBlock: block.number,
            baselinePriorityFeeWei: 0,
            input: PriorityInput({token: ERC20(address(NATIVE)), amount: ONE, mpsPerPriorityFeeWei: 0}),
            outputs: OutputsBuilder.singlePriority(address(tokenOut), ONE, 0, swapper),
            cosignerData: cosignerData,
            cosignature: bytes("")
        });
        order.cosignature = _cosign(order.hash(), cosignerData);
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        uint256 startBalance = tokenOut.balanceOf(address(fillContract));
        fillContract.execute(SignedOrder(abi.encode(order), sig));
        // filler loses output tokens and receives no native input
        assertEq(tokenOut.balanceOf(address(fillContract)), startBalance - ONE);
        assertEq(tokenOut.balanceOf(address(swapper)), ONE);
        assertEq(address(fillContract).balance, 0);
    }

    function _cosign(bytes32 orderHash, PriorityCosignerData memory cosignerData) internal view returns (bytes memory sig) {
        bytes32 msgHash = keccak256(abi.encodePacked(orderHash, block.chainid, abi.encode(cosignerData)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(cosignerPrivateKey, msgHash);
        sig = bytes.concat(r, s, bytes1(v));
    }
}

