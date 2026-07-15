// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "./IERC20.sol";

contract BadERC20 is IERC20 {
    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowances;

    uint256 public totalSupply = 0;
    string public name;
    string public symbol;
    uint8 public decimals;

    constructor(uint256 initialSupply) {
        name = "Token";
        symbol = "TKN";
        decimals = 18;
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
        require(balanceOf(msg.sender) >= amount, "ERC20: transfer amount exceeds balance");
        balances[msg.sender] = balances[msg.sender] - amount;
        balances[to] = balances[to] + amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        require(balanceOf(from) >= amount, "ERC20: transfer amount exceeds balance");
        require(allowance(from, msg.sender) >= amount, "ERC20: insufficient allowance");
        balances[from] = balances[from] - amount;
        balances[to] = balances[to] + amount;
        allowances[from][msg.sender] = allowances[from][msg.sender] - amount;
        emit Transfer(from, to, amount);
        return true;
    }
}
