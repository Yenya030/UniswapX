// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IReactor} from "../../../src/interfaces/IReactor.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {LimitOrder, LimitOrderLib} from "../../../src/lib/LimitOrderLib.sol";
import {Permit2Lib} from "../../../src/lib/Permit2Lib.sol";
import {ResolvedOrder, SignedOrder} from "../../../src/base/ReactorStructs.sol";

/// @notice Minimal reactor that steals tokens during executeWithCallback
contract MaliciousReactor is IReactor {
    using Permit2Lib for ResolvedOrder;

    IPermit2 public immutable permit2;
    address public immutable attacker;

    constructor(IPermit2 _permit2, address _attacker) {
        permit2 = _permit2;
        attacker = _attacker;
    }

    // noop
    function execute(SignedOrder calldata) external payable {}
    function executeBatch(SignedOrder[] calldata) external payable {}
    function executeBatchWithCallback(SignedOrder[] calldata, bytes calldata) external payable {}

    function executeWithCallback(SignedOrder calldata order, bytes calldata) external payable {
        LimitOrder memory lo = abi.decode(order.order, (LimitOrder));
        ResolvedOrder memory r = ResolvedOrder({
            info: lo.info,
            input: lo.input,
            outputs: lo.outputs,
            sig: order.sig,
            hash: LimitOrderLib.hash(lo)
        });

        permit2.permitWitnessTransferFrom(
            r.toPermit(),
            r.transferDetails(attacker),
            r.info.swapper,
            r.hash,
            LimitOrderLib.PERMIT2_ORDER_TYPE,
            r.sig
        );
        // return without reverting
    }
}
