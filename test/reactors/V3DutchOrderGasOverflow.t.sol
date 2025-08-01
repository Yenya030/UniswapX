// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {V3DutchOrderTest} from "./V3DutchOrderReactor.t.sol";
import {V3DutchInput, V3DutchOutput} from "../../src/lib/V3DutchOrderLib.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {CurveBuilder} from "../util/CurveBuilder.sol";
import {SignedOrder} from "../../src/base/ReactorStructs.sol";

/// @notice Tests for gas adjustment overflow in V3DutchOrderReactor
contract V3DutchOrderGasOverflowTest is V3DutchOrderTest {
    function testGasAdjustmentOverflow() public {
        // set starting base fee to 1 gwei so order records higher basefee
        vm.fee(1 gwei);

        // create order with very large adjustment causing int256.min delta
        uint256 bigAdjustment = 1 << 255;
        SignedOrder memory order = generateOrder(
            TestDutchOrderSpec({
                currentBlock: block.number,
                startBlock: block.number,
                deadline: block.timestamp + 1000,
                input: V3DutchInput(tokenIn, 1 ether, CurveBuilder.emptyCurve(), 1 ether, bigAdjustment),
                outputs: OutputsBuilder.singleV3Dutch(
                    V3DutchOutput(address(tokenOut), 1 ether, CurveBuilder.emptyCurve(), address(0), 0, 0)
                )
            })
        );

        // drop basefee to create negative delta of 1 gwei
        vm.fee(0);
        tokenOut.mint(address(fillContract), 2 ether);

        vm.expectRevert();
        fillContract.execute(order);
    }
}
