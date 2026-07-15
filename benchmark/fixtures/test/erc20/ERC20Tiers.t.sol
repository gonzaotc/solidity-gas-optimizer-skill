// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "../../src/erc20/IERC20.sol";
import {BadERC20} from "../../src/erc20/BadERC20.sol";
import {MediumERC20} from "../../src/erc20/MediumERC20.sol";
import {GoodERC20} from "../../src/erc20/GoodERC20.sol";
import {ReferenceERC20} from "../../src/erc20/ReferenceERC20.sol";

abstract contract ERC20ConformanceTest is Test {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    IERC20 internal token;
    uint256 internal constant SUPPLY = 1_000_000e18;
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function _deploy() internal virtual returns (IERC20);

    function setUp() public {
        token = _deploy();
    }

    function test_metadata() public view {
        assertEq(token.name(), "Token");
        assertEq(token.symbol(), "TKN");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), SUPPLY);
    }

    function test_initialBalance() public view {
        assertEq(token.balanceOf(address(this)), SUPPLY);
    }

    function test_transfer() public {
        assertTrue(token.transfer(alice, 100e18));
        assertEq(token.balanceOf(alice), 100e18);
        assertEq(token.balanceOf(address(this)), SUPPLY - 100e18);

        vm.prank(alice);
        assertTrue(token.transfer(bob, 40e18));
        assertEq(token.balanceOf(bob), 40e18);
        assertEq(token.balanceOf(alice), 60e18);
    }

    function test_transferInsufficientReverts() public {
        vm.prank(alice);
        vm.expectRevert();
        token.transfer(bob, 1);
    }

    function test_approveAndAllowance() public {
        assertTrue(token.approve(alice, 50e18));
        assertEq(token.allowance(address(this), alice), 50e18);
    }

    function test_transferFrom() public {
        token.approve(alice, 200e18);
        vm.prank(alice);
        assertTrue(token.transferFrom(address(this), bob, 150e18));
        assertEq(token.balanceOf(bob), 150e18);
        assertEq(token.allowance(address(this), alice), 50e18);
    }

    function test_transferFromInsufficientAllowanceReverts() public {
        token.approve(alice, 10e18);
        vm.prank(alice);
        vm.expectRevert();
        token.transferFrom(address(this), bob, 20e18);
    }

    function test_transferEmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), alice, 5e18);
        token.transfer(alice, 5e18);
    }

    function test_approveEmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit Approval(address(this), alice, 7e18);
        token.approve(alice, 7e18);
    }

    function test_zeroValueTransfer() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(this), alice, 0);
        assertTrue(token.transfer(alice, 0));
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.balanceOf(address(this)), SUPPLY);
    }

    function test_selfTransferPreservesBalance() public {
        token.transfer(address(this), 100e18);
        assertEq(token.balanceOf(address(this)), SUPPLY);
    }

    function test_approveOverwrites() public {
        token.approve(alice, 30e18);
        token.approve(alice, 80e18);
        assertEq(token.allowance(address(this), alice), 80e18);
    }

    function test_allowanceDecrementsToExactZero() public {
        token.approve(alice, 100e18);
        vm.prank(alice);
        token.transferFrom(address(this), bob, 100e18);
        assertEq(token.allowance(address(this), alice), 0);
    }
}

contract BadERC20Test is ERC20ConformanceTest {
    function _deploy() internal override returns (IERC20) {
        return new BadERC20(SUPPLY);
    }
}

contract MediumERC20Test is ERC20ConformanceTest {
    function _deploy() internal override returns (IERC20) {
        return new MediumERC20(SUPPLY);
    }
}

contract GoodERC20Test is ERC20ConformanceTest {
    function _deploy() internal override returns (IERC20) {
        return new GoodERC20(SUPPLY);
    }
}

contract ReferenceERC20Test is ERC20ConformanceTest {
    function _deploy() internal override returns (IERC20) {
        return IERC20(address(new ReferenceERC20(SUPPLY)));
    }
}
