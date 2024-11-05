// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract BidSC {

    uint256 finishTimestamp;
    uint256 maxBid;
    address maxBidder;

    constructor (uint256 _durationInSeconds) {
        finishTimestamp = block.timestamp + _durationInSeconds;
    }

    function makeBid() external payable{
        require(block.timestamp < finishTimestamp, "The BID finished");

        if (msg.value > maxBid) {
            maxBid = msg.value;
            maxBidder = msg.sender;

        }

        else {
            revert ("The BID is not enough");
        }
    }

    }