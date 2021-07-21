// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./interfaces/INonfungiblePositionManager.sol";
import "./libraries/Position.sol";

contract UniswapV3LiquidityLocker {
    using Position for Position.Info;

    mapping(uint256 => Position.Info) public lockedLiquidityPositions;

    INonfungiblePositionManager private uniswapNFPositionManager;
    uint128 private constant MAX_UINT128 = type(uint128).max;

    constructor() {
        uniswapNFPositionManager = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    }

    function lockLPToken(Position.Info calldata params) external {
        uniswapNFPositionManager.transferFrom(msg.sender, address(this), params.tokenId);

        params.isPositionValid();

        lockedLiquidityPositions[params.tokenId] = params;
    }

    function claimLPFee(uint256 tokenId) external returns (uint256 amount0, uint256 amount1) {
        Position.Info memory llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isFeeClaimAllowed();

        return
            uniswapNFPositionManager.collect(
                INonfungiblePositionManager.CollectParams(tokenId, llPosition.feeReciever, MAX_UINT128, MAX_UINT128)
            );
    }

    function updateOwner(uint256 tokenId, address owner) external {
        Position.Info storage llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isOnwer();

        llPosition.owner = owner;
    }

    function updateFeeReciever(uint256 tokenId, address feeReciever) external {
        Position.Info storage llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isOnwer();

        llPosition.feeReciever = feeReciever;
    }

    function removeToken(uint256 tokenId) external {
        Position.Info storage llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isTokenUnlocked();

        uniswapNFPositionManager.transferFrom(address(this), llPosition.owner, tokenId);
    }
}
