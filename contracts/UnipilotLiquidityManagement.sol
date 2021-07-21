// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./interfaces/INonfungiblePositionManager.sol";

contract UnipilotLiquidityManagement {
    uint256 public unlockingTimestamp;
    uint256 public tokenId;
    address public indexFund;
    address public timelock;

    INonfungiblePositionManager private uniswapNFPositionManager;

    modifier unlocked() {
        require(unlockingTimestamp < block.timestamp, "ULM::TOKEN_LOCKED");
        _;
    }

    modifier onlyTimelock {
        require(msg.sender == timelock, "ULM::NOT_TIMELOCK");
        _;
    }

    constructor(
        address timelockAddress,
        uint256 cliffDuration,
        uint256 nftTokenId
    ) {
        require(cliffDuration > 0, "ULM::INVALID_CLIFF");
        unlockingTimestamp = block.timestamp + cliffDuration;
        indexFund = address(0);
        tokenId = nftTokenId;
        timelock = timelockAddress;
        uniswapNFPositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    }

    function transferFeesToIndexFund() external returns (uint256 amount0, uint256 amount1) {
        require(indexFund != address(0), "ULM::INDEX_FUND_NOT_INITIALIZED");
        uint128 maxUint128 = type(uint128).max;
        return
            uniswapNFPositionManager.collect(
                INonfungiblePositionManager.CollectParams(tokenId, indexFund, maxUint128, maxUint128)
            );
    }

    function updateIndexFund(address indexFundAddress) external onlyTimelock {
        require(indexFund == address(0), "ULM::INDEX_FUND_ALREADY_INITIALIZED");
        indexFund = indexFundAddress;
    }

    function updateTokenId(uint256 nftTokenId) external unlocked onlyTimelock {
        tokenId = nftTokenId;
    }

    function removeToken(address to) external unlocked onlyTimelock {
        uniswapNFPositionManager.safeTransferFrom(address(this), to, tokenId);
    }
}
