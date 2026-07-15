// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// OpenZeppelin ERC20 v5.1.0, wrapped as a real-world reference baseline.
contract ReferenceERC20 is ERC20 {
    constructor(uint256 initialSupply) ERC20("Token", "TKN") {
        _mint(msg.sender, initialSupply);
    }
}
