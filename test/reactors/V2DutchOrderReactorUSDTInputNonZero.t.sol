// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {V2DutchOrderTest} from "./V2DutchOrderReactor.t.sol";
import {V2DutchOrder, CosignerData, DutchInput, DutchOutput, V2DutchOrderLib} from "../../src/lib/V2DutchOrderLib.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {SignedOrder, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {TetherToken} from "../Mock-USDT.sol";

contract V2DutchOrderReactorUSDTInputNonZeroTest is V2DutchOrderTest {
    using OrderInfoBuilder for OrderInfo;
    using V2DutchOrderLib for V2DutchOrder;

    function testExecuteUSDTInputNonZeroAmount() public {
        TetherToken usdt = new TetherToken(0, "Tether USD", "USDT", 6);
        tokenOut.mint(address(fillContract), ONE);
        CosignerData memory cosignerData = CosignerData({
            decayStartTime: block.timestamp,
            decayEndTime: block.timestamp,
            exclusiveFiller: address(0),
            exclusivityOverrideBps: 0,
            inputAmount: 0,
            outputAmounts: new uint256[](1)
        });
        V2DutchOrder memory order = V2DutchOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            cosigner: vm.addr(cosignerPrivateKey),
            baseInput: DutchInput(ERC20(address(usdt)), ONE, ONE),
            baseOutputs: OutputsBuilder.singleDutch(address(tokenOut), ONE, ONE, swapper),
            cosignerData: cosignerData,
            cosignature: bytes("")
        });
        bytes32 orderHash = order.hash();
        order.cosignature = _cosign(orderHash, cosignerData);
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        uint256 startBalance = tokenOut.balanceOf(address(fillContract));
        vm.expectRevert("TRANSFER_FROM_FAILED");
        fillContract.execute(SignedOrder(abi.encode(order), sig));
        assertEq(tokenOut.balanceOf(address(fillContract)), startBalance);
        assertEq(tokenOut.balanceOf(address(swapper)), 0);
    }

    function _cosign(bytes32 orderHash, CosignerData memory cosignerData) private view returns (bytes memory sig) {
        bytes32 msgHash = keccak256(abi.encodePacked(orderHash, block.chainid, abi.encode(cosignerData)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(cosignerPrivateKey, msgHash);
        sig = bytes.concat(r, s, bytes1(v));
    }
}

