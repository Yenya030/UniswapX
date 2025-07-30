// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {NonlinearDutchDecayLib} from "../../src/lib/NonlinearDutchDecayLib.sol";
import {V3DutchOutput, NonlinearDutchDecay} from "../../src/lib/V3DutchOrderLib.sol";
import {MockERC20} from "../util/mock/MockERC20.sol";
import {CurveBuilder} from "../util/CurveBuilder.sol";
import {BlockNumberish} from "../../src/base/BlockNumberish.sol";

contract NonlinearDutchDecayLibOutOfOrderTest is Test, BlockNumberish {
    MockERC20 token = new MockERC20("T", "T", 18);

    function testOutOfOrderBlocks() public {
        uint16[] memory blocks = new uint16[](2);
        blocks[0] = 100;
        blocks[1] = 50;
        int256[] memory amounts = new int256[](2);
        amounts[0] = -1 ether;
        amounts[1] = -2 ether;
        NonlinearDutchDecay memory curve = CurveBuilder.multiPointCurve(blocks, amounts);
        V3DutchOutput memory output = V3DutchOutput(address(token), 3 ether, curve, address(this), 0, 0);
        vm.roll(150);
        uint256 decayed = NonlinearDutchDecayLib.decay(output, 0, _getBlockNumberish()).amount;
        emit log_uint(decayed);
    }
}
