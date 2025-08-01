// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IValidationCallback} from "../../../src/interfaces/IValidationCallback.sol";
import {IReactor} from "../../../src/interfaces/IReactor.sol";
import {ResolvedOrder, SignedOrder} from "../../../src/base/ReactorStructs.sol";

/// @notice Validation contract that attempts to reenter the reactor during validation
contract MockValidationContractReentrant is IValidationCallback {
    IReactor public immutable reactor;
    bytes public storedOrder;
    bytes public storedSig;

    constructor(IReactor _reactor) {
        reactor = _reactor;
    }

    function setOrder(SignedOrder calldata order) external {
        storedOrder = order.order;
        storedSig = order.sig;
    }

    function validate(address, ResolvedOrder calldata) external view override {
        SignedOrder memory order = SignedOrder(storedOrder, storedSig);
        // attempt reentrancy using staticcall (will revert inside)
        (bool success,) = address(reactor).staticcall(
            abi.encodeWithSelector(IReactor.execute.selector, order)
        );
        require(success, "call failed");
    }
}
