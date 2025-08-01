// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {PriorityOrderReactorTest} from "./reactors/PriorityOrderReactor.t.sol";
import {PriorityOrderLib, PriorityOrder, PriorityInput, PriorityOutput, PriorityCosignerData} from "../src/lib/PriorityOrderLib.sol";
import {SignedOrder, OrderInfo} from "../src/base/ReactorStructs.sol";
import {OutputsBuilder} from "./util/OutputsBuilder.sol";
import {OrderInfoBuilder} from "./util/OrderInfoBuilder.sol";

contract PriorityOrderOverflowTest is PriorityOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;
    using PriorityOrderLib for PriorityOrder;

    function testInputScaleOverflow() public {
        vm.txGasPrice(1000 gwei);
        PriorityCosignerData memory cosignerData = PriorityCosignerData({auctionTargetBlock: block.number});
        PriorityOrder memory order = PriorityOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            cosigner: vm.addr(cosignerPrivateKey),
            auctionStartBlock: block.number,
            baselinePriorityFeeWei: 0,
            input: PriorityInput({token: tokenIn, amount: 1 ether, mpsPerPriorityFeeWei: type(uint256).max}),
            outputs: OutputsBuilder.singlePriority(address(tokenOut), 1 ether, 0, address(swapper)),
            cosignerData: cosignerData,
            cosignature: bytes("")
        });
        order.cosignature = _cosign(order.hash(), cosignerData);
        SignedOrder memory so = SignedOrder(abi.encode(order), signOrder(swapperPrivateKey, address(permit2), order));
        vm.expectRevert();
        fillContract.execute(so);
    }

    function _cosign(bytes32 orderHash, PriorityCosignerData memory cosignerData)
        private
        view
        returns (bytes memory sig)
    {
        bytes32 msgHash = keccak256(abi.encodePacked(orderHash, block.chainid, abi.encode(cosignerData)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(cosignerPrivateKey, msgHash);
        sig = bytes.concat(r, s, bytes1(v));
    }
}
