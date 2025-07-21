// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Permit2LibWrapper} from "../util/mock/Permit2LibWrapper.sol";
import {MockDAI} from "../util/mock/MockDAI.sol";

contract Permit2DaiBugTest is Test {
    Permit2LibWrapper wrapper;
    MockDAI dai;

    address owner = address(0x1);
    address spender = address(0x2);

    function setUp() public {
        wrapper = new Permit2LibWrapper();
        dai = new MockDAI();
    }

    function testPermit2SetsUnlimitedAllowance() public {
        uint256 amount = 50 * 1e18;
        uint256 deadline = block.timestamp + 1 days;

        assertEq(dai.allowance(owner, spender), 0);

        wrapper.callPermit2(dai, owner, spender, amount, deadline, 0, bytes32(0), bytes32(0));

        assertEq(dai.allowance(owner, spender), type(uint256).max);
    }
}
