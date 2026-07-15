// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {PriceGuard, IPriceSink} from "../../src/isolated/PriceGuard.sol";

contract ReentrantSink is IPriceSink {
    PriceGuard internal guard;
    uint256 internal newPrice;

    constructor(PriceGuard guard_, uint256 newPrice_) {
        guard = guard_;
        newPrice = newPrice_;
    }

    function onPrice(uint256) external {
        guard.setPrice(newPrice);
    }
}

contract PassiveSink is IPriceSink {
    function onPrice(uint256) external {}
}

contract PriceGuardTest is Test {
    PriceGuard internal guard;

    function setUp() public {
        guard = new PriceGuard();
        guard.setPrice(100);
    }

    function test_readsReflectReentrantWrite() public {
        ReentrantSink sink = new ReentrantSink(guard, 250);
        (uint256 before_, uint256 after_) = guard.pushAndAudit(address(sink));
        assertEq(before_, 100);
        assertEq(after_, 250);
    }

    function test_passiveSinkKeepsPrice() public {
        PassiveSink sink = new PassiveSink();
        (uint256 before_, uint256 after_) = guard.pushAndAudit(address(sink));
        assertEq(before_, 100);
        assertEq(after_, 100);
    }
}
