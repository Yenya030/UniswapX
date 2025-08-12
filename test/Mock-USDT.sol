// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @notice Minimal USDT-like token used for testing.
/// @dev Implements the ERC20 interface but without return values for
///      transfer and transferFrom to mimic USDT's non-standard behaviour.
contract MockUSDT {
    string public constant name = "Tether USD";
    string public constant symbol = "USDT";
    uint8 public constant decimals = 6;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function approve(address spender, uint256 amount) external {
        allowance[msg.sender][spender] = amount;
        // no return value
    }

    function transfer(address to, uint256 amount) external {
        uint256 bal = balanceOf[msg.sender];
        if (bal >= amount) {
            balanceOf[msg.sender] = bal - amount;
            balanceOf[to] += amount;
        }
        // silently succeeds even if balance is insufficient
    }

    function transferFrom(address from, address to, uint256 amount) external {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) {
            if (allowed >= amount) {
                allowance[from][msg.sender] = allowed - amount;
            } else {
                allowance[from][msg.sender] = 0;
            }
        }
        uint256 bal = balanceOf[from];
        if (bal >= amount) {
            balanceOf[from] = bal - amount;
            balanceOf[to] += amount;
        }
        // silently succeeds even if balance or allowance is insufficient
    }
}
