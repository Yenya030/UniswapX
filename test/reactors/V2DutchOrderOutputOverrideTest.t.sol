// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {DeployPermit2} from "../util/DeployPermit2.sol";
import {PermitSignature} from "../util/PermitSignature.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {ArrayBuilder} from "../util/ArrayBuilder.sol";
import {V2DutchOrderReactor} from "../../src/reactors/V2DutchOrderReactor.sol";
import {CosignerData, V2DutchOrder, DutchInput, V2DutchOrderLib} from "../../src/lib/V2DutchOrderLib.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {MockERC20} from "../util/mock/MockERC20.sol";
import {MockFillContract} from "../util/mock/MockFillContract.sol";
import {SignedOrder, OrderInfo} from "../../src/base/ReactorStructs.sol";

/// @notice Demonstrates that cosigner output overrides are not applied
contract V2DutchOrderOutputOverrideBugTest is Test, DeployPermit2, PermitSignature {
    using OrderInfoBuilder for OrderInfo;
    using V2DutchOrderLib for V2DutchOrder;

    uint256 constant cosignerPrivateKey = 0x99999999;
    uint256 constant swapperPrivateKey = 0x12341234;
    address swapper = vm.addr(swapperPrivateKey);

    MockERC20 tokenIn;
    MockERC20 tokenOut;
    V2DutchOrderReactor reactor;
    MockFillContract fillContract;
    IPermit2 permit2;

    function setUp() public {
        tokenIn = new MockERC20("In", "IN", 18);
        tokenOut = new MockERC20("Out", "OUT", 18);
        permit2 = IPermit2(deployPermit2());
        reactor = new V2DutchOrderReactor(permit2, address(1));
        fillContract = new MockFillContract(address(reactor));
        tokenIn.forceApprove(swapper, address(permit2), type(uint256).max);
    }

    /// @dev Test demonstrating cosigner output amounts are ignored
    error Bug();

    function test_outputOverrideBug() public {
        _run();
    }

    function _run() internal {
        uint256 inputAmount = 1 ether;
        uint256 overriddenOutputAmount = 1.1 ether;
        tokenIn.mint(swapper, inputAmount);
        tokenOut.mint(address(fillContract), overriddenOutputAmount);

        CosignerData memory cosignerData = CosignerData({
            decayStartTime: block.timestamp,
            decayEndTime: block.timestamp + 100,
            exclusiveFiller: address(0),
            exclusivityOverrideBps: 0,
            inputAmount: 0,
            outputAmounts: ArrayBuilder.fill(1, overriddenOutputAmount)
        });

        V2DutchOrder memory order = V2DutchOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper),
            cosigner: vm.addr(cosignerPrivateKey),
            baseInput: DutchInput(tokenIn, inputAmount, inputAmount),
            baseOutputs: OutputsBuilder.singleDutch(address(tokenOut), 1 ether, 0.9 ether, swapper),
            cosignerData: cosignerData,
            cosignature: bytes("")
        });

        bytes32 orderHash = order.hash();
        order.cosignature = _cosign(orderHash, cosignerData);
        SignedOrder memory signedOrder =
            SignedOrder(abi.encode(order), signOrder(swapperPrivateKey, address(permit2), order));

        fillContract.execute(signedOrder);
        uint256 bal = tokenOut.balanceOf(swapper);
        emit log_uint(bal);
        if (bal != overriddenOutputAmount) {
            revert Bug();
        }
    }

    function _cosign(bytes32 orderHash, CosignerData memory cosignerData) internal view returns (bytes memory sig) {
        bytes32 msgHash = keccak256(abi.encodePacked(orderHash, block.chainid, abi.encode(cosignerData)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(cosignerPrivateKey, msgHash);
        sig = bytes.concat(r, s, bytes1(v));
    }
}

