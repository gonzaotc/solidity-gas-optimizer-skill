// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "./IERC20.sol";

contract MediumERC20 is IERC20 {
    error InsufficientBalance();
    error InsufficientAllowance();

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowances;
    uint256 public totalSupply;

    string public constant name = "Token";
    string public constant symbol = "TKN";
    uint8 public constant decimals = 18;

    constructor(uint256 initialSupply) {
        balances[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        uint256 fromBalance = balances[msg.sender];
        if (fromBalance < amount) revert InsufficientBalance();
        balances[msg.sender] = fromBalance - amount;
        balances[to] = balances[to] + amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 fromBalance = balances[from];
        if (fromBalance < amount) revert InsufficientBalance();
        uint256 currentAllowance = allowances[from][msg.sender];
        if (currentAllowance < amount) revert InsufficientAllowance();
        balances[from] = fromBalance - amount;
        balances[to] = balances[to] + amount;
        allowances[from][msg.sender] = currentAllowance - amount;
        emit Transfer(from, to, amount);
        return true;
    }
}
