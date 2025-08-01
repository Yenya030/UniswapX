// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {V3DutchOrderTest} from "./V3DutchOrderReactor.t.sol";
import {V3DutchOrder, CosignerData, V3DutchInput, V3DutchOutput, V3DutchOrderLib} from "../../src/lib/V3DutchOrderLib.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {SignedOrder, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {NATIVE} from "../../src/lib/CurrencyLibrary.sol";
import {CurveBuilder} from "../util/CurveBuilder.sol";

using V3DutchOrderLib for V3DutchOrder;

contract V3DutchOrderReactorZeroInputTest is V3DutchOrderTest {
    using OrderInfoBuilder for OrderInfo;

    function testExecuteZeroInput() public {
        tokenOut.mint(address(fillContract), ONE);
        CosignerData memory cosignerData = CosignerData({
            decayStartBlock: block.number,
            exclusiveFiller: address(0),
            exclusivityOverrideBps: 0,
            inputAmount: 0,
            outputAmounts: new uint256[](1)
        });
        V3DutchOrder memory order = V3DutchOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            cosigner: vm.addr(cosignerPrivateKey),
            startingBaseFee: block.basefee,
            baseInput: V3DutchInput(ERC20(address(NATIVE)), 0, CurveBuilder.emptyCurve(), 0, 0),
            baseOutputs: OutputsBuilder.singleV3Dutch(
                address(tokenOut),
                ONE,
                ONE,
                CurveBuilder.emptyCurve(),
                swapper
            ),
            cosignerData: cosignerData,
            cosignature: bytes("")
        });
        bytes32 orderHash = order.hash();
        order.cosignature = _cosign(orderHash, cosignerData);
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        fillContract.execute(SignedOrder(abi.encode(order), sig));
        assertEq(tokenOut.balanceOf(address(fillContract)), 0);
        assertEq(tokenOut.balanceOf(address(swapper)), ONE);
    }

    function _cosign(bytes32 orderHash, CosignerData memory cosignerData) private view returns (bytes memory sig) {
        bytes32 msgHash = keccak256(abi.encodePacked(orderHash, block.chainid, abi.encode(cosignerData)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(cosignerPrivateKey, msgHash);
        sig = bytes.concat(r, s, bytes1(v));
    }
}
