// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

interface IReenter {
    function reenter() external;
}

/// @notice ERC20 that triggers a callback after transferFrom to simulate ERC777 tokens
contract MockERC777Reentrant is ERC20 {
    address public callback;

    constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol, decimals) {}

    function setCallback(address _callback) external {
        callback = _callback;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function forceApprove(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][to] = amount;
        emit Approval(from, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        bool success = super.transferFrom(from, to, amount);
        if (callback != address(0)) {
            IReenter(callback).reenter();
        }
        return success;
    }
}
