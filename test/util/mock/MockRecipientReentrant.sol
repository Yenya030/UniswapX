// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IReactor} from "../../../src/interfaces/IReactor.sol";
import {SignedOrder} from "../../../src/base/ReactorStructs.sol";

/// @notice Recipient contract that attempts reentrancy when receiving ETH
contract MockRecipientReentrant {
    IReactor public immutable reactor;

    constructor(address _reactor) {
        reactor = IReactor(_reactor);
    }

    receive() external payable {
        // attempt to reenter via executeBatch with empty orders
        SignedOrder[] memory orders = new SignedOrder[](0);
        reactor.executeBatch(orders);
    }
}
