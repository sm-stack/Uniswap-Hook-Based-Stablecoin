// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IOracle {

    error PriceOutOfRange();
    error OracleCallFailed();
    error ReturnedDataTooLong();
    error ExpOverflow();

    function getMaExpTime() external view returns (uint256);
    function exp(int256) external pure returns (uint256);
    function price() external view returns (uint256);
    function price_w() external view returns (uint256);
}
