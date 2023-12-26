// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;
pragma abicoder v2;

import "./libraries/Position.sol";
import "@cryptoalgebra/periphery/contracts/interfaces/INonfungiblePositionManager.sol";

contract A51LiquidityLocker {
    using Position for Position.Info;

    mapping(uint256 => Position.Info) public lockedLiquidityPositions;

    INonfungiblePositionManager private _positionManager;
    uint128 private constant MAX_UINT128 = type(uint128).max;

    event TokenUnlocked(uint256 tokenId);
    event PositionUpdated(Position.Info position);
    event FeeClaimed(uint256 tokenId, uint256 fee0, uint256 fee1);

    constructor() {
        _positionManager = INonfungiblePositionManager(0x8eF88E4c7CfbbaC1C163f7eddd4B578792201de6);
    }

    function lockLPToken(Position.Info calldata params) external {
        _positionManager.transferFrom(msg.sender, address(this), params.tokenId);

        params.isPositionValid();

        lockedLiquidityPositions[params.tokenId] = params;

        emit PositionUpdated(params);
    }

    function claimLPFee(uint256 tokenId) external returns (uint256 amount0, uint256 amount1) {
        Position.Info memory llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isFeeClaimAllowed();

        (amount0, amount1) = _positionManager.collect(
            INonfungiblePositionManager.CollectParams(tokenId, llPosition.feeReciever, MAX_UINT128, MAX_UINT128)
        );

        emit FeeClaimed(tokenId, amount0, amount1);
    }

    function updateOwner(uint256 tokenId, address owner) external {
        Position.Info storage llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isOwner();

        llPosition.owner = owner;

        emit PositionUpdated(llPosition);
    }

    function updateFeeReciever(uint256 tokenId, address feeReciever) external {
        Position.Info storage llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isOwner();

        llPosition.feeReciever = feeReciever;

        emit PositionUpdated(llPosition);
    }

    function renounceBeneficiaryUpdate(uint256 tokenId) external {
        Position.Info storage llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isOwner();

        llPosition.allowBeneficiaryUpdate = false;

        emit PositionUpdated(llPosition);
    }

    function unlockToken(uint256 tokenId) external {
        Position.Info memory llPosition = lockedLiquidityPositions[tokenId];

        llPosition.isTokenIdValid(tokenId);
        llPosition.isTokenUnlocked();

        _positionManager.transferFrom(address(this), llPosition.owner, tokenId);

        delete lockedLiquidityPositions[tokenId];

        emit TokenUnlocked(tokenId);
    }
}
