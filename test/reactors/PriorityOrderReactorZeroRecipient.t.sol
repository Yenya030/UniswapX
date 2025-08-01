// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {PriorityOrderReactorTest} from "./PriorityOrderReactor.t.sol";
import {PriorityOrderLib, PriorityOrder, PriorityInput, PriorityOutput, PriorityCosignerData} from "../../src/lib/PriorityOrderLib.sol";
import {SignedOrder, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract PriorityOrderReactorZeroRecipientTest is PriorityOrderReactorTest {
    using OrderInfoBuilder for OrderInfo;
    using PriorityOrderLib for PriorityOrder;

    function testExecuteZeroRecipient() public {
        tokenIn.forceApprove(swapper, address(permit2), ONE);
        PriorityCosignerData memory cosignerData = PriorityCosignerData({auctionTargetBlock: block.number});
        PriorityOutput[] memory outputs = new PriorityOutput[](1);
        outputs[0] = PriorityOutput({token: address(tokenOut), amount: ONE, mpsPerPriorityFeeWei: 0, recipient: address(0)});
        PriorityOrder memory order = PriorityOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            cosigner: vm.addr(cosignerPrivateKey),
            auctionStartBlock: block.number,
            baselinePriorityFeeWei: 0,
            input: PriorityInput({token: tokenIn, amount: ONE, mpsPerPriorityFeeWei: 0}),
            outputs: outputs,
            cosignerData: cosignerData,
            cosignature: bytes("")
        });
        order.cosignature = _cosign(order.hash(), cosignerData);
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        fillContract.execute(SignedOrder(abi.encode(order), sig));
        assertEq(tokenIn.balanceOf(address(swapper)), 0);
        assertEq(tokenOut.balanceOf(address(swapper)), 0);
    }

    function _cosign(bytes32 orderHash, PriorityCosignerData memory cosignerData) internal view returns (bytes memory sig) {
        bytes32 msgHash = keccak256(abi.encodePacked(orderHash, block.chainid, abi.encode(cosignerData)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(cosignerPrivateKey, msgHash);
        sig = bytes.concat(r, s, bytes1(v));
    }
}
