// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {PriorityOutput} from "../../src/lib/PriorityOrderLib.sol";
import {PriorityFeeLib} from "../../src/lib/PriorityFeeLib.sol";
import {OutputToken} from "../../src/base/ReactorStructs.sol";

contract PriorityFeeLibOutputOverflowTest is Test {
    uint256 constant MPS = 1e7;
    uint256 constant amount = 1111111111111111111; // 1.111111111111111111 ether

    function testScaleOutputPriorityFeeOverflow() public {
        uint256 priorityFee = 1 << 255;
        vm.txGasPrice(priorityFee);

        PriorityOutput memory output = PriorityOutput({
            token: address(0),
            amount: amount,
            mpsPerPriorityFeeWei: 2,
            recipient: address(0)
        });

        OutputToken memory scaled = PriorityFeeLib.scale(output, tx.gasprice);

        // multiplication overflow should saturate, but instead wraps and leaves amount unchanged
        assertEq(scaled.amount, output.amount);
    }
}
