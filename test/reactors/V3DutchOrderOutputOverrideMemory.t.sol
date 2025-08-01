// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {DeployPermit2} from "../util/DeployPermit2.sol";
import {PermitSignature} from "../util/PermitSignature.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {ArrayBuilder} from "../util/ArrayBuilder.sol";
import {V3DutchOrderReactor} from "../../src/reactors/V3DutchOrderReactor.sol";
import {CosignerData, V3DutchOrder, V3DutchInput, V3DutchOutput, V3DutchOrderLib} from "../../src/lib/V3DutchOrderLib.sol";
import {CurveBuilder} from "../util/CurveBuilder.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {MockERC20} from "../util/mock/MockERC20.sol";
import {MockFillContract} from "../util/mock/MockFillContract.sol";
import {SignedOrder, OrderInfo} from "../../src/base/ReactorStructs.sol";

// Ensure cosigner output overrides are properly applied and not lost due to memory semantics
contract V3DutchOrderOutputOverrideMemoryTest is Test, DeployPermit2, PermitSignature {
    using OrderInfoBuilder for OrderInfo;
    using V3DutchOrderLib for V3DutchOrder;

    uint256 constant cosignerPrivateKey = 0x99999999;
    uint256 constant swapperPrivateKey = 0x12341234;
    address swapper = vm.addr(swapperPrivateKey);

    MockERC20 tokenIn;
    MockERC20 tokenOut;
    V3DutchOrderReactor reactor;
    MockFillContract fillContract;
    IPermit2 permit2;

    function setUp() public {
        tokenIn = new MockERC20("In", "IN", 18);
        tokenOut = new MockERC20("Out", "OUT", 18);
        permit2 = IPermit2(deployPermit2());
        reactor = new V3DutchOrderReactor(permit2, address(1));
        fillContract = new MockFillContract(address(reactor));
    }

    function testOverrideAmountApplied() public {
        uint256 baseOutput = 1 ether;
        uint256 overrideOutput = 1.1 ether;
        uint256 inputAmount = 1 ether;

        tokenIn.mint(swapper, inputAmount);
        tokenOut.mint(address(fillContract), overrideOutput);
        tokenIn.forceApprove(swapper, address(permit2), type(uint256).max);

        CosignerData memory cosignerData = CosignerData({
            decayStartBlock: block.number,
            exclusiveFiller: address(0),
            exclusivityOverrideBps: 0,
            inputAmount: 0,
            outputAmounts: ArrayBuilder.fill(1, overrideOutput)
        });

        V3DutchOrder memory order = V3DutchOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            cosigner: vm.addr(cosignerPrivateKey),
            startingBaseFee: block.basefee,
            baseInput: V3DutchInput(tokenIn, inputAmount, CurveBuilder.emptyCurve(), inputAmount, 0),
            baseOutputs: OutputsBuilder.singleV3Dutch(
                address(tokenOut), baseOutput, baseOutput, CurveBuilder.emptyCurve(), swapper
            ),
            cosignerData: cosignerData,
            cosignature: bytes("")
        });
        bytes32 orderHash = order.hash();
        order.cosignature = _cosign(orderHash, cosignerData);
        SignedOrder memory signedOrder = SignedOrder(abi.encode(order), signOrder(swapperPrivateKey, address(permit2), order));

        fillContract.execute(signedOrder);

        assertEq(tokenOut.balanceOf(swapper), overrideOutput);
    }

    function _cosign(bytes32 orderHash, CosignerData memory cosignerData) private view returns (bytes memory sig) {
        bytes32 msgHash = keccak256(abi.encodePacked(orderHash, block.chainid, abi.encode(cosignerData)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(cosignerPrivateKey, msgHash);
        sig = bytes.concat(r, s, bytes1(v));
    }
}
