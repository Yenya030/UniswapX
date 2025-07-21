// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {Permit2Lib} from "permit2/src/libraries/Permit2Lib.sol";

contract Permit2LibWrapper {
    function callPermit2(
        ERC20 token,
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        Permit2Lib.permit2(token, owner, spender, amount, deadline, v, r, s);
    }
}
