// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {DeployPermit2} from "../util/DeployPermit2.sol";
import {PermitSignature} from "../util/PermitSignature.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {ArrayBuilder} from "../util/ArrayBuilder.sol";
import {CurveBuilder} from "../util/CurveBuilder.sol";
import {V3DutchOrderReactor} from "../../src/reactors/V3DutchOrderReactor.sol";
import {
    CosignerData, V3DutchOrder, V3DutchInput, V3DutchOutput, V3DutchOrderLib
} from "../../src/lib/V3DutchOrderLib.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {MockERC20} from "../util/mock/MockERC20.sol";
import {MockFillContract} from "../util/mock/MockFillContract.sol";
import {SignedOrder, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {CosignerLib} from "../../src/lib/CosignerLib.sol";

contract V3DutchOrderChainReplayTest is Test, DeployPermit2, PermitSignature {
    using OrderInfoBuilder for OrderInfo;
    using ArrayBuilder for uint256[];
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

    function testChainReplayReverts() public {
        uint256 amount = 1 ether;
        tokenIn.mint(swapper, amount);
        tokenOut.mint(address(fillContract), amount);
        tokenIn.forceApprove(swapper, address(permit2), type(uint256).max);

        CosignerData memory cosignerData = CosignerData({
            decayStartBlock: block.number,
            exclusiveFiller: address(0),
            exclusivityOverrideBps: 0,
            inputAmount: amount,
            outputAmounts: ArrayBuilder.fill(1, amount)
        });

        V3DutchOrder memory order = V3DutchOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            cosigner: vm.addr(cosignerPrivateKey),
            startingBaseFee: block.basefee,
            baseInput: V3DutchInput(tokenIn, amount, CurveBuilder.emptyCurve(), amount, 0),
            baseOutputs: OutputsBuilder.singleV3Dutch(address(tokenOut), amount, amount, CurveBuilder.emptyCurve(), swapper),
            cosignerData: cosignerData,
            cosignature: bytes("")
        });
        bytes32 orderHash = order.hash();
        order.cosignature = _cosign(orderHash, cosignerData);
        SignedOrder memory signedOrder =
            SignedOrder(abi.encode(order), signOrder(swapperPrivateKey, address(permit2), order));

        vm.chainId(block.chainid + 1);
        vm.expectRevert(CosignerLib.InvalidCosignature.selector);
        fillContract.execute(signedOrder);
    }

    function _cosign(bytes32 orderHash, CosignerData memory cosignerData) private view returns (bytes memory sig) {
        bytes32 msgHash = keccak256(abi.encodePacked(orderHash, block.chainid, abi.encode(cosignerData)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(cosignerPrivateKey, msgHash);
        sig = bytes.concat(r, s, bytes1(v));
    }
}
