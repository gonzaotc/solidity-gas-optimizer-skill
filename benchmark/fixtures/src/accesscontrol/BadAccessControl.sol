// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IAccessControl} from "./IAccessControl.sol";

contract BadAccessControl is IAccessControl {
    mapping(bytes32 => mapping(address => bool)) internal _roles;
    mapping(bytes32 => bytes32) internal _adminRoles;
    bytes32 public DEFAULT_ADMIN_ROLE;

    modifier onlyAdmin(bytes32 role) {
        require(_roles[getRoleAdmin(role)][msg.sender], "AccessControl: sender missing admin role");
        _;
    }

    constructor() {
        DEFAULT_ADMIN_ROLE = 0x00;
        _roles[DEFAULT_ADMIN_ROLE][msg.sender] = true;
        emit RoleGranted(DEFAULT_ADMIN_ROLE, msg.sender, msg.sender);
    }

    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role][account];
    }

    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _adminRoles[role];
    }

    function grantRole(bytes32 role, address account) public onlyAdmin(role) {
        if (!_roles[role][account]) {
            _roles[role][account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    function revokeRole(bytes32 role, address account) public onlyAdmin(role) {
        if (_roles[role][account]) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    function renounceRole(bytes32 role, address account) public {
        require(account == msg.sender, "AccessControl: can only renounce for self");
        if (_roles[role][account]) {
            _roles[role][account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}
