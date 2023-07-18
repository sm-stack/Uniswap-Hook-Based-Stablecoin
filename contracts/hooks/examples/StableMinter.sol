// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {IDynamicFeeManager} from "@uniswap/v4-core/contracts/interfaces/IDynamicFeeManager.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {BaseHook} from "../../BaseHook.sol";
import {Fees} from "@uniswap/v4-core/contracts/libraries/Fees.sol";
import {IUniUSD} from "../../interfaces/IUniUSD.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";



contract StableMinter is BaseHook, IDynamicFeeManager, Ownable {
    using Fees for uint24;

    error PositionsMustBeFullRange();
    error PoolMustLockLiquidity();
    error MustUseDynamicFee();

    event SetOracle(address indexed newOracle);

    uint32 deployTimestamp;
    address uniusd;
    IOracle public oracle;


    constructor(IPoolManager _poolManager, address _uniusd) BaseHook(_poolManager) {
        deployTimestamp = _blockTimestamp();
        uniusd = _uniusd;
    }

    function getFee(IPoolManager.PoolKey calldata) external view returns (uint24) {
        uint24 startingFee = 3000;
        uint32 lapsed = _blockTimestamp() - deployTimestamp;
        return startingFee + (uint24(lapsed) * 100) / 60; // 100 bps a minute
    }

    /// @dev For mocking
    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp);
    }

    function setOracle(address newOracle) external onlyOwner {
        _setOracle(newOracle);
    }

    function _setOracle(address newOracle) internal {
        oracle = IOracle(newOracle);
        emit SetOracle(newOracle);
    }

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return Hooks.Calls({
            beforeInitialize: true,
            afterInitialize: false,
            beforeModifyPosition: false,
            afterModifyPosition: false,
            beforeSwap: false,
            afterSwap: false,
            beforeDonate: false,
            afterDonate: false
        });
    }

    function beforeModifyPosition(
        address,
        IPoolManager.PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata params
    )
        external
        pure
        override
        returns (bytes4)
    {
        if (params.liquidityDelta < 0) revert PoolMustLockLiquidity();
        int24 maxTickSpacing = poolManager.MAX_TICK_SPACING();
        if (
            params.tickLower != TickMath.minUsableTick(maxTickSpacing)
                || params.tickUpper != TickMath.maxUsableTick(maxTickSpacing)
        ) revert PositionsMustBeFullRange();

        

        return StableMinter.beforeModifyPosition.selector;
    }

    function afterModifyPosition(
        address,
        IPoolManager.PoolKey calldata key,
        IPoolManager.ModifyPositionParams calldata params,
        BalanceDelta
    )
        external
        pure
        override
        returns (bytes4)
    {
        price0 = oracle.getLatestPrice(priceQuoteToken);
        IUniUSD(uniusd).mint(msg.sender, 1e18);
        return StableMinter.afterModifyPosition.selector;
    }
}
