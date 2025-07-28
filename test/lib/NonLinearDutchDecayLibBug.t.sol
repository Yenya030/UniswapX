// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {NonlinearDutchDecayLib} from "../../src/lib/NonlinearDutchDecayLib.sol";
import {CurveBuilder} from "../util/CurveBuilder.sol";
import {NonlinearDutchDecay} from "../../src/lib/V3DutchOrderLib.sol";
import {BlockNumberish} from "../../src/base/BlockNumberish.sol";
import {MockERC20} from "../util/mock/MockERC20.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {V3DutchOutput} from "../../src/lib/V3DutchOrderLib.sol";

contract NonlinearDutchDecayLibBugTest is Test, BlockNumberish {
    MockERC20 token = new MockERC20("T","T",18);

    function testMismatchedBlocksAndAmounts() public {
        uint16[] memory blocks = new uint16[](2);
        blocks[0] = 100;
        blocks[1] = 200;
        int256[] memory amounts = new int256[](1);
        amounts[0] = -1 ether;
        NonlinearDutchDecay memory curve = CurveBuilder.multiPointCurve(blocks, amounts);
        V3DutchOutput memory output = V3DutchOutput(address(token), 1 ether, curve, address(0), 0, 0);
        vm.expectRevert(NonlinearDutchDecayLib.InvalidDecayCurve.selector);
        NonlinearDutchDecayLib.decay(output, 0, _getBlockNumberish());
    }
}
