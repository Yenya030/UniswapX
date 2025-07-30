// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {DeployPermit2} from "../util/DeployPermit2.sol";
import {OrderInfo, SignedOrder} from "../../src/base/ReactorStructs.sol";
import {DutchOrderReactor, DutchOrder, DutchInput} from "../../src/reactors/DutchOrderReactor.sol";
import {OutputsBuilder} from "../util/OutputsBuilder.sol";
import {OrderInfoBuilder} from "../util/OrderInfoBuilder.sol";
import {MockERC20} from "../util/mock/MockERC20.sol";
import {MockFillContractNoReceive} from "../util/mock/MockFillContractNoReceive.sol";
import {PermitSignature} from "../util/PermitSignature.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {CurrencyLibrary, NATIVE} from "../../src/lib/CurrencyLibrary.sol";

contract EthOutputNoReceiveTest is Test, DeployPermit2, PermitSignature {
    using OrderInfoBuilder for OrderInfo;

    address constant PROTOCOL_FEE_OWNER = address(2);
    uint256 constant ONE = 1 ether;

    MockERC20 tokenIn;
    IPermit2 permit2;
    DutchOrderReactor reactor;
    MockFillContractNoReceive fillContract;
    uint256 swapperKey;
    address swapper;

    function setUp() public {
        tokenIn = new MockERC20("T", "T", 18);
        swapperKey = 0x12341234;
        swapper = vm.addr(swapperKey);
        permit2 = IPermit2(deployPermit2());
        reactor = new DutchOrderReactor(permit2, PROTOCOL_FEE_OWNER);
        fillContract = new MockFillContractNoReceive(address(reactor));
        tokenIn.forceApprove(swapper, address(permit2), type(uint256).max);
    }

    function testRefundToNonPayableReverts() public {
        // deposit stray ETH to reactor
        address stranger = address(9999);
        vm.deal(stranger, ONE);
        vm.prank(stranger);
        address(reactor).call{value: ONE}("");

        tokenIn.mint(swapper, ONE);
        DutchOrder memory order = DutchOrder({
            info: OrderInfoBuilder.init(address(reactor)).withSwapper(swapper).withDeadline(block.timestamp + 100),
            decayStartTime: block.timestamp,
            decayEndTime: block.timestamp + 100,
            input: DutchInput(tokenIn, ONE, ONE),
            outputs: OutputsBuilder.singleDutch(NATIVE, ONE, ONE, swapper)
        });

        SignedOrder memory signedOrder = SignedOrder(abi.encode(order), signOrder(swapperKey, address(permit2), order));
        vm.expectRevert(CurrencyLibrary.NativeTransferFailed.selector);
        fillContract.execute(signedOrder);
    }
}
