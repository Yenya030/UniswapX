// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "forge-std/Test.sol";
import {ExclusivityLib, ResolvedOrder} from "../../src/lib/ExclusivityLib.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";

contract ExclusivityLibOverflowTest is Test {
    function testOverflowExclusivityOverrideBps() public {
        ResolvedOrder memory order;
        order.outputs = OutputsBuilder.single(address(0x1), 1 ether, address(0x2));
        uint256 hugeBps = type(uint256).max;
        ExclusivityLib.handleExclusiveOverrideTimestamp(order, address(0), block.timestamp - 1, hugeBps);
        // Overflowed addition causes no increase; amount remains unchanged
        assertEq(order.outputs[0].amount, 1 ether);
    }
}
