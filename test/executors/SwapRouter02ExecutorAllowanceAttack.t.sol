// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {SwapRouter02Executor} from "../../src/sample-executors/SwapRouter02Executor.sol";
import {MockERC20} from "../util/mock/MockERC20.sol";
import {MaliciousRouter} from "../util/mock/MaliciousRouter.sol";
import {IReactor} from "../../src/interfaces/IReactor.sol";
import {ISwapRouter02} from "../../src/external/ISwapRouter02.sol";
import {WETH} from "solmate/src/tokens/WETH.sol";
import {ResolvedOrder} from "../../src/base/ReactorStructs.sol";

contract SwapRouter02ExecutorAllowanceAttackTest is Test {
    SwapRouter02Executor executor;
    MockERC20 token;
    MaliciousRouter router;
    WETH weth;
    address filler = address(0xbeef);

    function setUp() public {
        token = new MockERC20("T", "T", 18);
        weth = new WETH();
        router = new MaliciousRouter(address(weth));
        executor = new SwapRouter02Executor(filler, IReactor(address(this)), address(this), ISwapRouter02(address(router)));
    }

    function testFillerCanDrainApprovedTokens() public {
        // Set unlimited approval via callback
        address[] memory approveSwap = new address[](1);
        approveSwap[0] = address(token);
        address[] memory approveReactor = new address[](0);
        bytes[] memory data = new bytes[](0);
        vm.prank(address(this));
        executor.reactorCallback(new ResolvedOrder[](0), abi.encode(approveSwap, approveReactor, data));

        // Approval for router should be max
        assertEq(token.allowance(address(executor), address(router)), type(uint256).max);

        // Tokens accrue in executor
        uint256 amount = 1 ether;
        token.mint(address(executor), amount);

        // Filler drains tokens via router using leftover approval
        vm.prank(filler);
        router.drain(address(token), address(executor), filler, amount);

        assertEq(token.balanceOf(address(executor)), 0);
        assertEq(token.balanceOf(filler), amount);
    }
}

