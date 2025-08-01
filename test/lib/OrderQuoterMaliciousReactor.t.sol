// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {DeployPermit2} from "../util/DeployPermit2.sol";
import {PermitSignature} from "../util/PermitSignature.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {MockERC20} from "../util/mock/MockERC20.sol";
import {OrderQuoter} from "../../src/lens/OrderQuoter.sol";
import {MaliciousReactor} from "../util/mock/MaliciousReactor.sol";
import {LimitOrder} from "../../src/reactors/LimitOrderReactor.sol";
import {OrderInfo, InputToken, SignedOrder} from "../../src/base/ReactorStructs.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

contract OrderQuoterMaliciousReactorTest is Test, PermitSignature, DeployPermit2 {
    using OrderInfoBuilder for OrderInfo;

    uint256 constant ONE = 1e18;
    address attacker = address(0xdead);

    OrderQuoter quoter;
    MockERC20 tokenIn;
    MockERC20 tokenOut;
    IPermit2 permit2;
    MaliciousReactor malicious;
    uint256 swapperPrivateKey;
    address swapper;

    function setUp() public {
        quoter = new OrderQuoter();
        permit2 = IPermit2(deployPermit2());
        tokenIn = new MockERC20("In", "IN", 18);
        tokenOut = new MockERC20("Out", "OUT", 18);
        swapperPrivateKey = 0xabc123;
        swapper = vm.addr(swapperPrivateKey);
        tokenIn.mint(swapper, ONE);
        malicious = new MaliciousReactor(permit2, attacker);
    }

    function testQuoteMaliciousReactorTransfersTokens() public {
        tokenIn.forceApprove(swapper, address(permit2), ONE);
        LimitOrder memory order = LimitOrder({
            info: OrderInfoBuilder.init(address(malicious)).withSwapper(swapper),
            input: InputToken(tokenIn, ONE, ONE),
            outputs: OutputsBuilder.single(address(tokenOut), ONE, swapper)
        });
        bytes memory sig = signOrder(swapperPrivateKey, address(permit2), order);

        vm.prank(swapper);
        quoter.quote(abi.encode(order), sig);

        assertEq(tokenIn.balanceOf(attacker), ONE);
    }
}

