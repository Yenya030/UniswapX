// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "forge-std/Test.sol";
import {ExclusivityLib} from "../../src/lib/ExclusivityLib.sol";
import {ResolvedOrder, OutputToken, OrderInfo, InputToken} from "../../src/base/ReactorStructs.sol";
import {IReactor} from "../../src/interfaces/IReactor.sol";
import {IValidationCallback} from "../../src/interfaces/IValidationCallback.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract ExclusivityOverrideTest is Test {
    using ExclusivityLib for ResolvedOrder;

    function testOverrideApplied() public {
        OutputToken[] memory outputs = new OutputToken[](1);
        outputs[0] = OutputToken(address(0x1234), 1 ether, address(0x5678));
        ResolvedOrder memory order = ResolvedOrder({
            info: OrderInfo({
                reactor: IReactor(address(this)),
                swapper: address(0),
                nonce: 0,
                deadline: block.timestamp + 1,
                additionalValidationContract: IValidationCallback(address(0)),
                additionalValidationData: ""
            }),
            input: InputToken({token: ERC20(address(0)), amount: 0, maxAmount: 0}),
            outputs: outputs,
            sig: "",
            hash: bytes32(0)
        });

        order.handleExclusiveOverrideTimestamp(address(1), block.timestamp + 100, 1000);
        assertEq(order.outputs[0].amount, 1.1 ether);
    }
}
