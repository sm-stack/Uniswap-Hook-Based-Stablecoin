// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {IOracle} from "../../interfaces/IOracle.sol";

contract Oracle is IOracle {
    uint256 public lastPrice;
    uint256 public lastTimestamp;

    uint256 immutable public MA_EXP_TIME;
    address immutable public SIG_ADDRESS;
    bytes4 immutable public SIG_METHOD;

    uint256 constant public MIN_MA_EXP_TIME = 30;
    uint256 constant public MAX_MA_EXP_TIME = 365 * 86400; 

    error PriceOutOfRange();

    constructor(
        uint256 maExpTime, 
        address _priceOracleContract, 
        bytes32 _priceOracleSig
    ) {
        if (maExpTime < MIN_MA_EXP_TIME || maExpTime > MAX_MA_EXP_TIME) revert PriceOutOfRange();
        MA_EXP_TIME = maExpTime;
        SIG_ADDRESS = _priceOracleContract;
        SIG_METHOD = _priceOracleSig[28:];

        bytes32 response = _callPriceOracle(SIG_ADDRESS, SIG_METHOD);
        
        lastPrice = uint256(response);
        lastTimestamp = block.timestamp;
    }

    function _callPriceOracle(address sigAddress, bytes memory sigMethod) internal view returns (bytes32) {
        (bool success, bytes memory data) = sigAddress.staticcall(sigMethod);
        require(success, "Oracle call failed");
        require(data.length <= 32, "Returned data too long");
        
        bytes32 result;
        assembly {
            result := mload(add(data, 32))
        }
        return result;
    }

    function getMaExpTime() external view returns (uint256) {
        return MA_EXP_TIME;
    }

    

    // function exp(int256) external pure returns (uint256) {
        
    // }

    function price() external view returns (uint256) {
        return _emaPrice();
    }

    function price_w() external view returns (uint256) {
        uint256 price = _emaPrice();
        if lastTimestamp < block.timestamp {
            lastPrice = price;
            lastTimestamp = block.timestamp;
        }
        return price;
    }

    function _emaPrice() internal view returns (uint256) {
        uint256 newTimestamp = lastTimestamp;
        uint256 newPrice = lastPrice;
        if (block.timestamp > newTimestamp) {
            uint256 currentPrice = _callPriceOracle(SIG_ADDRESS, SIG_METHOD);
            uint256 alpha = exp(-int256((block.timestamp - newTimestamp) / MA_EXP_TIME));
            return (currentPrice * (10**18 - alpha) + newPrice * alpha) / 10**18
        }
        else {
            return newPrice;
        }
    }

    
}