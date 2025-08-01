// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {V3DutchOrderTest} from "./V3DutchOrderReactor.t.sol";
import {
    V3DutchOrder,
    CosignerData,
    V3DutchInput,
    V3DutchOutput,
    NonlinearDutchDecay,
    V3DutchOrderLib
} from "../../src/lib/V3DutchOrderLib.sol";
import {V3DutchOrderReactor} from "../../src/reactors/V3DutchOrderReactor.sol";
import {SignedOrder, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {CurveBuilder} from "../util/CurveBuilder.sol";

contract V3DutchOrderReactorZeroOutputsTest is V3DutchOrderTest {
    using OrderInfoBuilder for OrderInfo;
    using V3DutchOrderLib for V3DutchOrder;

    function testExecuteNoOutputs() public {
        tokenIn.mint(address(swapper), ONE);
        tokenIn.forceApprove(swapper, address(permit2), ONE);
        CosignerData memory cosignerData = CosignerData({
            decayStartBlock: block.number,
            exclusiveFiller: address(0),
            exclusivityOverrideBps: 0,
            inputAmount: 0,
            outputAmounts: new uint256[](0)
        });
        V3DutchOrder memory order = V3DutchOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            cosigner: vm.addr(cosignerPrivateKey),
            startingBaseFee: block.basefee,
            baseInput: V3DutchInput(tokenIn, ONE, CurveBuilder.emptyCurve(), ONE, 0),
            baseOutputs: new V3DutchOutput[](0),
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
