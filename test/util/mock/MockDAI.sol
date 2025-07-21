// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IDAIPermit} from "permit2/src/interfaces/IDAIPermit.sol";

contract MockDAI is ERC20, IDAIPermit {
    bytes32 public constant DAI_DOMAIN_SEPARATOR = 0xdbb8cf42e1ecb028be3f3dbc922e1d878b963f411dc388ced501601c60f7c6f7;

    function DOMAIN_SEPARATOR() public pure override returns (bytes32) {
        return DAI_DOMAIN_SEPARATOR;
    }

    constructor() ERC20("Dai Stablecoin", "DAI", 18) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function forceApprove(address owner, address spender, uint256 amount) external returns (bool) {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 /*expiry*/,
        bool allowed,
        uint8 /*v*/,
        bytes32 /*r*/,
        bytes32 /*s*/
    ) external override {
        require(nonce == nonces[holder], "bad nonce");
        nonces[holder]++;
        allowance[holder][spender] = allowed ? type(uint256).max : 0;
        emit Approval(holder, spender, allowance[holder][spender]);
    }
}
