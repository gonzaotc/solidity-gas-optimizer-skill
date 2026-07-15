// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "../../src/accesscontrol/IAccessControl.sol";
import {BadAccessControl} from "../../src/accesscontrol/BadAccessControl.sol";
import {MediumAccessControl} from "../../src/accesscontrol/MediumAccessControl.sol";
import {GoodAccessControl} from "../../src/accesscontrol/GoodAccessControl.sol";
import {ReferenceAccessControl} from "../../src/accesscontrol/ReferenceAccessControl.sol";

abstract contract AccessControlConformanceTest is Test {
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    IAccessControl internal ac;
    bytes32 internal constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    address internal alice = address(0xA11CE);
    address internal bob = address(0xB0B);

    function _deploy() internal virtual returns (IAccessControl);

    function setUp() public {
        ac = _deploy();
    }

    function test_adminBootstrapped() public view {
        assertTrue(ac.hasRole(ac.DEFAULT_ADMIN_ROLE(), address(this)));
    }

    function test_grantRole() public {
        ac.grantRole(MANAGER_ROLE, alice);
        assertTrue(ac.hasRole(MANAGER_ROLE, alice));
    }

    function test_grantByNonAdminReverts() public {
        vm.prank(bob);
        vm.expectRevert();
        ac.grantRole(MANAGER_ROLE, alice);
    }

    function test_revokeRole() public {
        ac.grantRole(MANAGER_ROLE, alice);
        ac.revokeRole(MANAGER_ROLE, alice);
        assertFalse(ac.hasRole(MANAGER_ROLE, alice));
    }

    function test_renounceSelf() public {
        ac.grantRole(MANAGER_ROLE, alice);
        vm.prank(alice);
        ac.renounceRole(MANAGER_ROLE, alice);
        assertFalse(ac.hasRole(MANAGER_ROLE, alice));
    }

    function test_renounceForOtherReverts() public {
        ac.grantRole(MANAGER_ROLE, alice);
        vm.expectRevert();
        ac.renounceRole(MANAGER_ROLE, alice);
    }

    function test_grantEmitsEvent() public {
        vm.expectEmit(true, true, true, true);
        emit RoleGranted(MANAGER_ROLE, alice, address(this));
        ac.grantRole(MANAGER_ROLE, alice);
    }

    function test_grantIsIdempotent() public {
        ac.grantRole(MANAGER_ROLE, alice);
        ac.grantRole(MANAGER_ROLE, alice);
        assertTrue(ac.hasRole(MANAGER_ROLE, alice));
    }

    function test_revokeUnheldIsNoop() public {
        ac.revokeRole(MANAGER_ROLE, alice);
        assertFalse(ac.hasRole(MANAGER_ROLE, alice));
    }

    function test_revokeEmitsEvent() public {
        ac.grantRole(MANAGER_ROLE, alice);
        vm.expectEmit(true, true, true, true);
        emit RoleRevoked(MANAGER_ROLE, alice, address(this));
        ac.revokeRole(MANAGER_ROLE, alice);
    }
}

contract BadAccessControlTest is AccessControlConformanceTest {
    function _deploy() internal override returns (IAccessControl) {
        return new BadAccessControl();
    }
}

contract MediumAccessControlTest is AccessControlConformanceTest {
    function _deploy() internal override returns (IAccessControl) {
        return new MediumAccessControl();
    }
}

contract GoodAccessControlTest is AccessControlConformanceTest {
    function _deploy() internal override returns (IAccessControl) {
        return new GoodAccessControl();
    }
}

contract ReferenceAccessControlTest is AccessControlConformanceTest {
    function _deploy() internal override returns (IAccessControl) {
        return IAccessControl(address(new ReferenceAccessControl()));
    }
}
