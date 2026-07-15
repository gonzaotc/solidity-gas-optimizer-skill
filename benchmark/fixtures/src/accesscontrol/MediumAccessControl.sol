// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IAccessControl} from "./IAccessControl.sol";

contract MediumAccessControl is IAccessControl {
    error MissingAdminRole();
    error BadConfirmation();

    mapping(bytes32 => mapping(address => bool)) internal _roles;
    mapping(bytes32 => bytes32) internal _adminRoles;
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    constructor() {
        _roles[DEFAULT_ADMIN_ROLE][msg.sender] = true;
        emit RoleGranted(DEFAULT_ADMIN_ROLE, msg.sender, msg.sender);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _adminRoles[role];
    }

    function _checkAdmin(bytes32 role) internal view {
        if (!_roles[getRoleAdmin(role)][msg.sender]) revert MissingAdminRole();
    }

    function grantRole(bytes32 role, address account) public {
        _checkAdmin(role);
        if (!_roles[role][account]) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function revokeRole(bytes32 role, address account) public {
        _checkAdmin(role);
        if (_roles[role][account]) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    function renounceRole(bytes32 role, address account) public {
        if (account != msg.sender) revert BadConfirmation();
        if (_roles[role][account]) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}
