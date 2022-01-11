// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol"; // import from @chainlink NPM package
// interfaces don't have full function implementations
// interfaces compile down to an ABI
// ABI tells solidity how it can interact with another contract, e.g., what functions to call
// always need an ABI to interact with a contract

import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe { // We want this contract to accept payment
    using SafeMathChainlink for uint256; // prevent integer overflow

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    function fund() public payable { // payable with ETH
        uint256 minimumUSD = 30 * 10 ** 18; // in wei terms
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");

        // Keep track of who pays something
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);

        // Getting external data with chainlink
        // what the ETH -> USD conversion rate is
    }

    // Working with interfaces
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        (,int256 answer,,,) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000); // type-casting
        // return price in 18 decimals, originally has 8 decimals
        // 4063636305820000000000
    }

    function getConversionRate(uint256 ethAmount) public view returns (uint256) { // ethAmount in wei
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000; // both ethPrice and ethAmount has 10**18 attached to them
        return ethAmountInUsd;
    }

    function getEntranceFee() public view returns (uint256) {
      uint256 minimumUSD = 50 * 10**18;
      uint256 price = getPrice();
      uint256 precision = 1 * 10**18;
      return (minimumUSD * precision) / price;
    }

    // modifiers are used to change the behavior of a function in a declarative way
    modifier onlyOwner {
        require (msg.sender == owner); 
        _;
    }

    function withdraw() payable onlyOwner public {
        // only want the contract admin/owner
        msg.sender.transfer(address(this).balance); // this = the contract you're currently in
        // reset everyone's balance to zero
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}