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


    constructor(
        uint256 maExpTime, 
        address _priceOracleContract, 
        bytes4 _priceOracleSigMethod
    ) {
        if (maExpTime < MIN_MA_EXP_TIME || maExpTime > MAX_MA_EXP_TIME) revert PriceOutOfRange();
        MA_EXP_TIME = maExpTime;
        SIG_ADDRESS = _priceOracleContract;
        SIG_METHOD = _priceOracleSigMethod;

        bytes32 response = this.callPriceOracle(SIG_ADDRESS, SIG_METHOD);
        
        lastPrice = uint256(response);
        lastTimestamp = block.timestamp;
    }

    function callPriceOracle(address sigAddress, bytes calldata sigMethod) external view returns (bytes32) {
        (bool success, bytes memory data) = sigAddress.staticcall(sigMethod);
        if (!success) revert OracleCallFailed();
        if (data.length > 32) revert ReturnedDataTooLong();
        
        bytes32 result;
        assembly {
            result := mload(add(data, 32))
        }
        return result;
    }

    function getMaExpTime() external view returns (uint256) {
        return MA_EXP_TIME;
    }

    

     function exp(int256 power) public pure returns (uint256) {
        if (power <= int256(-0x2505F590F663E60BFF7)) {
            return 0;
        }

        if (power >= int256(0x1D68BF83FEE7DC3D3D5)) revert ExpOverflow();
        

        int256 x;
        int256 k;
        int256 y;
        int256 p;
        int256 q;

        assembly {
            // x = (power * 2**96) / 10**18;
            x := div(mul(power, 0x1000000000000000000000000), 0xDE0B6B3A7640000)

            // k calculations
            k := div(add(div(mul(x, 0x1000000000000000000000000), 0x78A8EF5A9E3F3945E6FA6A8A80CC), 0x800000000000000000000000), 0x1000000000000000000000000)
            x := sub(x, mul(k, 0x78A8EF5A9E3F3945E6FA6A8A80CC))

            // y calculations
            y := add(x, 0x12B3A41E28400F48F6D6E6C05700)
            y := add(div(mul(y, x), 0x1000000000000000000000000), 0x7DE9C58C9F6C4D3EA9FAC7B32A6)

            // p calculations
            p := add(add(y, x), sub(0xD1F4DF252D70C520B348B62AD4, y))
            p := add(div(mul(p, y), 0x1000000000000000000000000), 0x3F84647840CFB8F9DDF02A1800)
            p := add(mul(p, x), mul(0x3D588567D8AC59E1B9A6, 0x1000000000000000000000000))

            // q calculations
            q := sub(x, 0x27B6BFA0C9D0D5FABB53E4D800)
            q := add(div(mul(q, x), 0x1000000000000000000000000), 0xB16B9F3AB8BFDAAAFB2735409)
            q := sub(div(mul(q, x), 0x1000000000000000000000000), 0x76D7D1F2E05A87BC99F460C44)
            q := add(div(mul(q, x), 0x1000000000000000000000000), 0x321E9555752AE1A8E18BD5DD5)
            q := sub(div(mul(q, x), 0x1000000000000000000000000), 0xC8DB26C67F465F197E38FAB9)
            q := add(div(mul(q, x), 0x1000000000000000000000000), 0x3A2A9EC03E471F7863E8EF2F)
        }

        return shift(uint256(p / q) * 0x359534FE706B174E892099AA8D03, k - 195);
    }

    function shift(uint256 value, int256 offset) internal pure returns (uint256) {
        if (offset >= 0) {
            return value << uint256(offset);
        } else {
            return value >> uint256(offset);
        }
    }

    function price() external view returns (uint256) {
        return _emaPrice();
    }

    function price_w() external view returns (uint256) {
        uint256 _price = _emaPrice();
        if (lastTimestamp < block.timestamp) {
            lastPrice = _price;
            lastTimestamp = block.timestamp;
        }
        return _price;
    }

    function _emaPrice() internal view returns (uint256) {
        uint256 newTimestamp = lastTimestamp;
        uint256 newPrice = lastPrice;
        if (block.timestamp > newTimestamp) {
            uint256 currentPrice = uint256(this.callPriceOracle(SIG_ADDRESS, SIG_METHOD));
            uint256 alpha = exp(-int256((block.timestamp - newTimestamp) / MA_EXP_TIME));
            return (currentPrice * (10**18 - alpha) + newPrice * alpha) / 10**18;
        }
        else {
            return newPrice;
        }
    }

    
}