// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IReactorCallback} from "../../../src/interfaces/IReactorCallback.sol";
import {IReactor} from "../../../src/interfaces/IReactor.sol";
import {SignedOrder, ResolvedOrder} from "../../../src/base/ReactorStructs.sol";

/// @notice Fill contract used to test reentrancy via ERC777 token callback
contract MockFillContractTokenReentrant is IReactorCallback {
    IReactor immutable reactor;

    constructor(address _reactor) {
        reactor = IReactor(_reactor);
    }

    function execute(SignedOrder calldata order) external {
        reactor.execute(order);
    }

    /// @notice Called by the token during transferFrom to attempt reentrancy
    function reenter() external {
        SignedOrder[] memory empty = new SignedOrder[](0);
        reactor.executeBatch(empty);
    }

    function reactorCallback(ResolvedOrder[] calldata, bytes calldata) external {}
}
