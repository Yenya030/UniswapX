pragma solidity ^0.8.0;

import {Test, stdError} from "forge-std/Test.sol";
import {MockExclusivityLib} from "../util/mock/MockExclusivityLib.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {ResolvedOrder} from "../../src/base/ReactorStructs.sol";

contract ExclusivityLibOverflowTest is Test {
    MockExclusivityLib exclusivity;

    function setUp() public {
        exclusivity = new MockExclusivityLib();
    }

    function testExclusivityOverrideBpsOverflow() public {
        ResolvedOrder memory order;
        order.outputs = OutputsBuilder.single(address(1), 1 ether, address(2));
        vm.expectRevert(stdError.arithmeticError);
        exclusivity.handleExclusiveOverrideTimestamp(order, address(3), block.timestamp + 1, type(uint256).max);
    }
}
