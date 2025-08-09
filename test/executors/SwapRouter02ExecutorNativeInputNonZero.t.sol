// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {V2DutchOrderTest} from "../reactors/V2DutchOrderReactor.t.sol";
import {V2DutchOrder, CosignerData, DutchInput, DutchOutput, V2DutchOrderLib} from "../../src/lib/V2DutchOrderLib.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {SignedOrder, OrderInfo} from "../../src/base/ReactorStructs.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {NATIVE} from "../../src/lib/CurrencyLibrary.sol";
import {SwapRouter02Executor} from "../../src/sample-executors/SwapRouter02Executor.sol";
import {MockSwapRouter} from "../util/mock/MockSwapRouter.sol";
import {WETH} from "solmate/src/tokens/WETH.sol";
import {ISwapRouter02} from "../../src/external/ISwapRouter02.sol";

contract SwapRouter02ExecutorNativeInputNonZeroTest is V2DutchOrderTest {
    using OrderInfoBuilder for OrderInfo;
    using V2DutchOrderLib for V2DutchOrder;

    SwapRouter02Executor internal executor;
    WETH internal weth;
    MockSwapRouter internal mockSwapRouter;

    constructor() {
        weth = new WETH();
        mockSwapRouter = new MockSwapRouter(address(weth));
        executor = new SwapRouter02Executor(
            address(this),
            reactor,
            address(this),
            ISwapRouter02(address(mockSwapRouter))
        );
    }

    function testExecuteNativeInputNonZeroAmount() public {
        tokenOut.mint(address(executor), ONE);
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
            baseInput: DutchInput(ERC20(address(NATIVE)), ONE, ONE),
            baseOutputs: OutputsBuilder.singleDutch(address(tokenOut), ONE, ONE, swapper),
            cosignerData: cosignerData,
            cosignature: bytes("")
        });
        bytes32 orderHash = order.hash();
        order.cosignature = _cosign(orderHash, cosignerData);
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);
        uint256 startBalance = tokenOut.balanceOf(address(executor));
        address[] memory tokensToApproveForSwapRouter02 = new address[](0);
        address[] memory tokensToApproveForReactor = new address[](1);
        tokensToApproveForReactor[0] = address(tokenOut);
        bytes[] memory multicallData = new bytes[](0);
        executor.execute(
            SignedOrder(abi.encode(order), sig),
            abi.encode(tokensToApproveForSwapRouter02, tokensToApproveForReactor, multicallData)
        );
        assertEq(tokenOut.balanceOf(address(executor)), startBalance - ONE);
        assertEq(tokenOut.balanceOf(address(swapper)), ONE);
        assertEq(address(executor).balance, 0);
    }

    function _cosign(bytes32 orderHash, CosignerData memory cosignerData) private view returns (bytes memory sig) {
        bytes32 msgHash = keccak256(abi.encodePacked(orderHash, block.chainid, abi.encode(cosignerData)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(cosignerPrivateKey, msgHash);
        sig = bytes.concat(r, s, bytes1(v));
    }
}

