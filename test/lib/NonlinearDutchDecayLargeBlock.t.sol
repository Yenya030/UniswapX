// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {NonlinearDutchDecayLib} from "../../src/lib/NonlinearDutchDecayLib.sol";
import {V3DutchOutput, NonlinearDutchDecay} from "../../src/lib/V3DutchOrderLib.sol";
import {MockERC20} from "../util/mock/MockERC20.sol";
import {BlockNumberish} from "../../src/base/BlockNumberish.sol";

contract NonlinearDutchDecayLargeBlockTest is Test, BlockNumberish {
    MockERC20 token = new MockERC20("T", "T", 18);

    function testLargeRelativeBlockHandled() public {
        // relativeBlocks contains a value larger than uint16.max (70000)
        uint256 packedBlocks = 70000; // 0x11170
        int256[] memory amounts = new int256[](2);
        amounts[0] = -1 ether;
        amounts[1] = -2 ether;
        NonlinearDutchDecay memory curve = NonlinearDutchDecay({relativeBlocks: packedBlocks, relativeAmounts: amounts});
        V3DutchOutput memory output = V3DutchOutput(address(token), 3 ether, curve, address(this), 0, 0);
        vm.roll(80000);
        uint256 decayed = NonlinearDutchDecayLib.decay(output, 0, _getBlockNumberish()).amount;
        assertGt(decayed, 0);
    }
}
