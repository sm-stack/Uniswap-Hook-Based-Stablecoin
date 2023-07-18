// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {BaseHook} from "../../BaseHook.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUniUSD} from "../../interfaces/IUniUSD.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/libraries/PoolId.sol";


contract UniUSD is IUniUSD, ERC20, Ownable {

    address private _minter;

    mapping(PooId => bool) public isPoolRegistered;

    error NotMinter();

    constructor(address stableMinter) ERC20(
        "Uniswap Hook-Based USD",
        "UniUSD"
    ) {
        _minter = stableMinter;
    }

    function setRegisteredPool(PoolId[] memory poolId) public onlyOwner {
        if (!isPoolRegistered[poolId]) {
            isPoolRegistered[poolId] = true;
        }
    }

    function mint(address minter, uint256 amount) external override onlyStableMinter {
    }

    modifier onlyStableMinter() {
        if (msg.sender != _minter) revert NotMinter();
        _;
    }

}
