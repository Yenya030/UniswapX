// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {V2DutchOrderTest} from "./V2DutchOrderReactor.t.sol";
import {V2DutchOrder, CosignerData, DutchInput, DutchOutput, V2DutchOrderLib} from "../../src/lib/V2DutchOrderLib.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {OrderInfo} from "../../src/base/ReactorStructs.sol";

import {SignedOrder} from "../../src/base/ReactorStructs.sol";

using V2DutchOrderLib for V2DutchOrder;

contract V2DutchOrderReactorZeroOutputsTest is V2DutchOrderTest {
    using OrderInfoBuilder for OrderInfo;

    function testExecuteNoOutputs() public {
        tokenIn.mint(address(swapper), ONE);
        tokenIn.forceApprove(swapper, address(permit2), ONE);
        CosignerData memory cosignerData = CosignerData({
            decayStartTime: block.timestamp,
            decayEndTime: block.timestamp,
            exclusiveFiller: address(0),
            exclusivityOverrideBps: 0,
            inputAmount: 0,
            outputAmounts: new uint256[](0)
        });
        V2DutchOrder memory order = V2DutchOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            cosigner: vm.addr(cosignerPrivateKey),
            baseInput: DutchInput(tokenIn, ONE, ONE),
            baseOutputs: new DutchOutput[](0),
            cosignerData: cosignerData,
            cosignature: bytes("")
        });
        bytes32 orderHash = order.hash();
        order.cosignature = _cosign(orderHash, cosignerData);
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        fillContract.execute(SignedOrder(abi.encode(order), sig));
        assertEq(tokenIn.balanceOf(address(swapper)), 0);
        assertEq(tokenIn.balanceOf(address(fillContract)), ONE);
    }

    function _cosign(bytes32 orderHash, CosignerData memory cosignerData) private view returns (bytes memory sig) {
        bytes32 msgHash = keccak256(abi.encodePacked(orderHash, block.chainid, abi.encode(cosignerData)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(cosignerPrivateKey, msgHash);
        sig = bytes.concat(r, s, bytes1(v));
    }
}
