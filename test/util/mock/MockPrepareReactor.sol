// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {BaseReactor} from "../../../src/reactors/BaseReactor.sol";
import {ResolvedOrder, SignedOrder} from "../../../src/base/ReactorStructs.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

/// @notice Reactor exposing _prepare for testing memory behavior
contract MockPrepareReactor is BaseReactor {
    constructor(IPermit2 permit2_, address feeOwner) BaseReactor(permit2_, feeOwner) {}

    function prepareOrders(ResolvedOrder[] memory orders) external returns (ResolvedOrder[] memory) {
        _prepare(orders);
        return orders;
    }

    function _resolve(SignedOrder calldata) internal pure override returns (ResolvedOrder memory) {
        revert("unused");
    }

    function _transferInputTokens(ResolvedOrder memory, address) internal override {}
}
