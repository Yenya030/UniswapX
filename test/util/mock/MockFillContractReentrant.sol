// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {CurrencyLibrary} from "../../../src/lib/CurrencyLibrary.sol";
import {ResolvedOrder, OutputToken, SignedOrder} from "../../../src/base/ReactorStructs.sol";
import {IReactor} from "../../../src/interfaces/IReactor.sol";
import {IReactorCallback} from "../../../src/interfaces/IReactorCallback.sol";

/// @notice Fill contract that attempts to reenter the same reactor during callback
contract MockFillContractReentrant is IReactorCallback {
    using CurrencyLibrary for address;

    IReactor immutable reactor;

    constructor(address _reactor) {
        reactor = IReactor(_reactor);
    }

    /// @notice execute first order and attempt to execute second order reentrantly
    function execute(SignedOrder calldata order, SignedOrder calldata other) external {
        reactor.executeWithCallback(order, abi.encode(other));
    }

    /// @notice During callback try to execute the second order on the same reactor
    function reactorCallback(ResolvedOrder[] memory resolvedOrders, bytes memory otherSignedOrder) external {
        for (uint256 i = 0; i < resolvedOrders.length; i++) {
            for (uint256 j = 0; j < resolvedOrders[i].outputs.length; j++) {
                OutputToken memory output = resolvedOrders[i].outputs[j];
                if (output.token.isNative()) {
                    CurrencyLibrary.transferNative(msg.sender, output.amount);
                } else {
                    ERC20(output.token).approve(msg.sender, type(uint256).max);
                }
            }
        }

        if (msg.sender == address(reactor)) {
            reactor.executeWithCallback(abi.decode(otherSignedOrder, (SignedOrder)), hex"");
        }
    }
}
