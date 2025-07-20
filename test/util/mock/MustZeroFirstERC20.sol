// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";

contract MustZeroFirstERC20 is ERC20 {
    error MustSetZeroFirst();

    constructor(string memory name, string memory symbol, uint8 decimals) ERC20(name, symbol, decimals) {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        if (amount != 0 && allowance[msg.sender][spender] != 0) {
            revert MustSetZeroFirst();
        }
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function forceApprove(address from, address to, uint256 amount) public returns (bool) {
        allowance[from][to] = amount;
        emit Approval(from, to, amount);
        return true;
    }
}
