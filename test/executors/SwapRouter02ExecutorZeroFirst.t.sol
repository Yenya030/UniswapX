// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {SwapRouter02Executor} from "../../src/sample-executors/SwapRouter02Executor.sol";
import {MultiFillerSwapRouter02Executor} from "../../src/sample-executors/MultiFillerSwapRouter02Executor.sol";
import {DutchOrderReactor, DutchOrder, DutchInput, DutchOutput} from "../../src/reactors/DutchOrderReactor.sol";
import {MustZeroFirstERC20} from "../util/mock/MustZeroFirstERC20.sol";
import {MockSwapRouter} from "../util/mock/MockSwapRouter.sol";
import {OutputToken, OrderInfo, InputToken, SignedOrder, ResolvedOrder} from "../../src/base/ReactorStructs.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {DeployPermit2} from "../util/DeployPermit2.sol";
import {ISwapRouter02, ExactInputParams} from "../../src/external/ISwapRouter02.sol";
import {PermitSignature} from "../util/PermitSignature.sol";

contract SwapRouter02ExecutorZeroFirstTest is Test, DeployPermit2, PermitSignature {
    using OrderInfoBuilder for OrderInfo;

    MustZeroFirstERC20 tokenIn;
    MustZeroFirstERC20 tokenOut;
    MockSwapRouter mockSwapRouter;
    DutchOrderReactor reactor;
    SwapRouter02Executor executor;
    IPermit2 permit2;
    address swapper;
    uint256 swapperKey;
    uint24 constant FEE = 3000;
    uint256 constant ONE = 1 ether;
    address constant PROTOCOL_FEE_OWNER = address(1);

    function setUp() public {
        tokenIn = new MustZeroFirstERC20("Input", "IN", 18);
        tokenOut = new MustZeroFirstERC20("Output", "OUT", 18);
        mockSwapRouter = new MockSwapRouter(address(0));
        permit2 = IPermit2(deployPermit2());
        reactor = new DutchOrderReactor(permit2, PROTOCOL_FEE_OWNER);
        executor =
            new SwapRouter02Executor(address(this), reactor, address(this), ISwapRouter02(address(mockSwapRouter)));
        swapperKey = 0x99;
        swapper = vm.addr(swapperKey);
        vm.startPrank(swapper);
        tokenIn.approve(address(permit2), type(uint256).max);
        vm.stopPrank();
    }

    function _order(uint256 nonce) internal view returns (DutchOrder memory order) {
        order = DutchOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper).withDeadline(block.timestamp + 1).withNonce(
                nonce
            ),
            decayStartTime: block.timestamp - 1,
            decayEndTime: block.timestamp + 1,
            input: DutchInput(tokenIn, ONE, ONE),
            outputs: OutputsBuilder.singleDutch(address(tokenOut), ONE, 0, swapper)
        });
    }

    function testExecuteReapproveReverts() public {
        tokenIn.mint(swapper, 2 * ONE);
        tokenOut.mint(address(mockSwapRouter), 2 * ONE);

        address[] memory approveSwap = new address[](1);
        approveSwap[0] = address(tokenIn);
        address[] memory approveReactor = new address[](1);
        approveReactor[0] = address(tokenOut);
        bytes[] memory data = new bytes[](1);
        ExactInputParams memory params = ExactInputParams({
            path: abi.encodePacked(tokenIn, FEE, tokenOut),
            recipient: address(executor),
            amountIn: ONE,
            amountOutMinimum: 0
        });
        data[0] = abi.encodeWithSelector(ISwapRouter02.exactInput.selector, params);

        executor.execute(
            SignedOrder(abi.encode(_order(0)), signOrder(swapperKey, address(permit2), _order(0))),
            abi.encode(approveSwap, approveReactor, data)
        );
        vm.expectRevert(bytes("APPROVE_FAILED"));
        executor.execute(
            SignedOrder(abi.encode(_order(1)), signOrder(swapperKey, address(permit2), _order(1))),
            abi.encode(approveSwap, approveReactor, data)
        );
    }
}

contract MultiFillerSwapRouter02ExecutorZeroFirstTest is Test, DeployPermit2 {
    MustZeroFirstERC20 token;
    MockSwapRouter mockSwapRouter;
    DutchOrderReactor reactor;
    MultiFillerSwapRouter02Executor executor;
    IPermit2 permit2;

    function setUp() public {
        token = new MustZeroFirstERC20("Token", "TKN", 18);
        mockSwapRouter = new MockSwapRouter(address(0));
        permit2 = IPermit2(deployPermit2());
        reactor = new DutchOrderReactor(permit2, address(1));
        address[] memory callers = new address[](1);
        callers[0] = address(this);
        executor =
            new MultiFillerSwapRouter02Executor(callers, reactor, address(this), ISwapRouter02(address(mockSwapRouter)));
    }

    function testReactorCallbackReapproveReverts() public {
        address[] memory approveSwap = new address[](1);
        approveSwap[0] = address(token);
        address[] memory approveReactor = new address[](1);
        approveReactor[0] = address(token);
        bytes[] memory data = new bytes[](0);

        vm.prank(address(reactor));
        executor.reactorCallback(new ResolvedOrder[](0), abi.encode(approveSwap, approveReactor, data));
        vm.prank(address(reactor));
        vm.expectRevert(bytes("APPROVE_FAILED"));
        executor.reactorCallback(new ResolvedOrder[](0), abi.encode(approveSwap, approveReactor, data));
    }
}
