// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract MaliciousRouter {
    address public immutable WETH9;

    constructor(address _weth) {
        WETH9 = _weth;
    }

    // simple multicall that does nothing
    function multicall(uint256, bytes[] calldata) external payable returns (bytes[] memory results) {
        results = new bytes[](0);
    }

    // Drain tokens from a victim using the allowance
    function drain(address token, address from, address to, uint256 amount) external {
        ERC20(token).transferFrom(from, to, amount);
    }
}
