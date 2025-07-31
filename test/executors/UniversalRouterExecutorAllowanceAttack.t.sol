// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {UniversalRouterExecutor} from "../../src/sample-executors/UniversalRouterExecutor.sol";
import {MockERC20} from "../util/mock/MockERC20.sol";
import {MaliciousRouter} from "../util/mock/MaliciousRouter.sol";
import {IReactor} from "../../src/interfaces/IReactor.sol";
import {WETH} from "solmate/src/tokens/WETH.sol";
import {ResolvedOrder} from "../../src/base/ReactorStructs.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {Permit2Stub} from "../util/mock/Permit2Stub.sol";

contract UniversalRouterExecutorAllowanceAttackTest is Test {
    UniversalRouterExecutor executor;
    MockERC20 token;
    MaliciousRouter router;
    WETH weth;
    IPermit2 permit2;
    address filler = address(0xbeef);

    function setUp() public {
        token = new MockERC20("T", "T", 18);
        weth = new WETH();
        router = new MaliciousRouter(address(weth));
        permit2 = IPermit2(address(new Permit2Stub()));
        address[] memory callers = new address[](1);
        callers[0] = filler;
        executor = new UniversalRouterExecutor(callers, IReactor(address(this)), address(this), address(router), permit2);
    }

    function testFillerCanDrainApprovedTokens() public {
        // Initial callback to set unlimited approval
        address[] memory approveUR = new address[](1);
        approveUR[0] = address(token);
        address[] memory approveReactor = new address[](0);
        bytes memory data = abi.encodeWithSelector(router.multicall.selector, 0, new bytes[](0));
        vm.prank(address(this));
        executor.reactorCallback(new ResolvedOrder[](0), abi.encode(approveUR, approveReactor, data));

        // Allowance to permit2 should be max
        assertEq(token.allowance(address(executor), address(permit2)), type(uint256).max);

        uint256 amount = 1 ether;
        token.mint(address(executor), amount);

        // Approval remains and could be used by permit2 to move funds
        assertEq(token.allowance(address(executor), address(permit2)), type(uint256).max);
        assertEq(token.balanceOf(address(executor)), amount);
    }
}
