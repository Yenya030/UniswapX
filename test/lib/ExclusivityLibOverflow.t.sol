// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "../util/mock/MockERC20.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {MockExclusivityLib} from "../util/mock/MockExclusivityLib.sol";
import {ResolvedOrder} from "../../src/base/ReactorStructs.sol";

contract ExclusivityLibOverflowTest is Test {
    MockExclusivityLib exclusivity;
    MockERC20 token = new MockERC20("T","T",18);
    address recipient = address(0xdead);

    function setUp() public {
        exclusivity = new MockExclusivityLib();
    }

    function testExclusivityOverrideBpsOverflow() public {
        ResolvedOrder memory order;
        order.outputs = OutputsBuilder.single(address(token), 1 ether, recipient);
        uint256 hugeBps = type(uint256).max - 1000;
        vm.startPrank(address(2));
        vm.expectRevert();
        exclusivity.handleExclusiveOverrideTimestamp(order, address(1), block.timestamp + 1, hugeBps);
        vm.stopPrank();
    }
}
