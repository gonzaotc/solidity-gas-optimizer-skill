// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IPriceSink {
    function onPrice(uint256 price) external;
}

contract PriceGuard {
    uint256 public price;

    function setPrice(uint256 p) external {
        price = p;
    }

    function pushAndAudit(address sink) external returns (uint256 before_, uint256 after_) {
        before_ = price;
        IPriceSink(sink).onPrice(before_);
        after_ = price;
    }
}
