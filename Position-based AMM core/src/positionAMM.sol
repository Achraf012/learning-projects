// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.29;

contract PositionAMM {
    // Positions define where liquidity exists.
    // Ticks define when liquidity becomes active

    // A position’s liquidity becomes active when the current tick crosses its lower boundary, and becomes inactive when the current tick crosses its upper boundary.
    struct Position {
        uint256 tickUpper;
        uint256 tickLower;
        uint256 liquidity;
        address owner;
        bool exist;
    }
    uint256 positionId;
    mapping(uint256 positionId => Position) public ids;

    mapping(uint256 tick => int256 liquidityDelta) public liquidityDeltas;

    int256 public activeLiquidity;

    uint256 currentTick;

    function mintPosition(
        uint256 liquidity,
        uint256 tickLower,
        uint256 tickUpper
    ) external {
        ids[positionId] = Position({
            tickUpper: tickUpper,
            tickLower: tickLower,
            liquidity: liquidity,
            owner: msg.sender,
            exist: true
        });
        positionId += 1;
        liquidityDeltas[tickLower] += int256(liquidity);
        liquidityDeltas[tickUpper] -= int256(liquidity);
        if (tickLower < currentTick && currentTick <= tickUpper) {
            activeLiquidity += int256(liquidity);
        }
    }

    function burnPosition(uint256 Id) external {
        Position storage user = ids[Id];

        require(user.exist, "position doesnt exist");
        uint256 tickLower = user.tickLower;
        uint256 tickUpper = user.tickUpper;
        address owner = user.owner;
        uint256 liquidity = user.liquidity;
        require(owner == msg.sender, "not owner");
        liquidityDeltas[tickLower] -= int256(liquidity);
        liquidityDeltas[tickUpper] += int256(liquidity);
        if (tickLower < currentTick && currentTick <= tickUpper) {
            activeLiquidity -= int256(liquidity);
        }
        user.exist = false;
    }

    function moveTick(uint256 newTick) external {
        require(newTick != currentTick, "same Tick");
        bool moveUp = newTick > currentTick;
        if (moveUp) {
            for (uint256 i = currentTick + 1; i <= newTick; i++) {
                int256 delta = liquidityDeltas[i];
                if (delta != 0) {
                    activeLiquidity += delta;
                }
            }
        } else {
            for (uint256 i = currentTick; i >= newTick; i--) {
                int256 delta = liquidityDeltas[i];
                if (delta != 0) {
                    activeLiquidity -= delta;
                }
            }
        }
        currentTick = newTick;
    }

    function partialBurn(uint256 positionID, uint256 lq) external {
        require(ids[positionID].exist == true, "position doesnt exist");
        require(msg.sender == ids[positionID].owner, "not owner");
        require(
            ids[positionID].liquidity > lq && lq > 0,
            "must burn less than full liquidity"
        );
        ids[positionID].liquidity -= lq;
        uint256 ticklower = ids[positionID].tickLower;
        uint256 tickupper = ids[positionID].tickUpper;

        liquidityDeltas[ticklower] -= int256(lq);
        liquidityDeltas[tickupper] += int256(lq);
        if (ticklower < currentTick && currentTick <= tickupper) {
            activeLiquidity -= int256(lq);
        }
    }
}
