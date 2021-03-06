// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract Nfight {
    uint8 public constant MOVES_COUNT = 5;
    uint32 public constant MAX_FIGHTERS_PER_FIGHT_DAY = 100;
    uint8 public constant UP_DAMAGE = 4;
    uint8 public constant CENTER_DAMAGE = 3;
    uint8 public constant DOWN_DAMAGE = 2;
    uint8 public constant BLOCKER_RECEIVED_DAMAGE = 1;
    uint8 public constant BLOCKED_RECEIVED_DAMAGE = 3;

    enum Move {
        UP,
        CENTER,
        DOWN,
        BLOCK
    }
  
    struct MovesStorage {
        Move[MOVES_COUNT] moves;
        bool set;
    }

    struct Fighter {
        bool alive;
    }

    mapping(address => MovesStorage) public moves;
    mapping(address => Fighter) public fighters;
    address public immutable arbiter;
    address[] public fightersPerFightDay;

    modifier onlyArbiter() {
        require(msg.sender == arbiter);
        _;
    }

    constructor() {
        arbiter = msg.sender;
    }

    function enlist(address a) internal {
        fighters[a].alive = true;
    }

    function enlist() external {
        enlist(msg.sender);
    }

    function preMove(address a, Move[MOVES_COUNT] memory m) internal {
        require(fighters[a].alive);
        require(!moves[a].set);
        require(fightersPerFightDay.length < MAX_FIGHTERS_PER_FIGHT_DAY);
        moves[a].moves = m;
        moves[a].set = true;
        fightersPerFightDay.push(a);
    }

    function preMove(Move[MOVES_COUNT] calldata m) external {
        preMove(msg.sender, m);
    }

    function countOfWaitingFighters() external view returns (uint) {
        return fightersPerFightDay.length;
    }

    function random(uint seed, uint to) public pure returns (uint) {
        uint h = uint(keccak256(abi.encodePacked(seed)));
        return (h % to);
    }

    function random(uint to) private view returns(uint) {
        require(block.number >= 1);
        return random(block.number, to);
    }

    function matchFightersAndExecuteDuels() external onlyArbiter {
        if (fightersPerFightDay.length < 2) {
            return;
        }

        // There can be up to 1 fighter who will have to wait for a subsequent fight day.
        while (fightersPerFightDay.length > 1) {
            uint fighter1Idx = random(fightersPerFightDay.length);
            address fighter1 = fightersPerFightDay[fighter1Idx];
            fightersPerFightDay[fightersPerFightDay.length - 1] = fighter1;
            fightersPerFightDay.pop();

            uint fighter2Idx = random(fightersPerFightDay.length);
            address fighter2 = fightersPerFightDay[fighter2Idx];
            fightersPerFightDay[fightersPerFightDay.length - 1] = fighter2;
            fightersPerFightDay.pop();

            executeDuel(fighter1, fighter2);
        }
    }

    function toDamage(Move m) private pure returns(uint8) {
        require(m != Move.BLOCK);
        if (m == Move.UP) {
            return UP_DAMAGE;
        } else if (m == Move.CENTER) {
            return CENTER_DAMAGE;
        } else if (m == Move.DOWN) {
            return DOWN_DAMAGE;
        }
        return 0;
    }

    function executeDuel(address fighter1, address fighter2) private onlyArbiter {
        Move[MOVES_COUNT] storage moves1 = moves[fighter1].moves;
        Move[MOVES_COUNT] storage moves2 = moves[fighter2].moves;
        uint16 receivedDamage1 = 0;
        uint16 receivedDamage2 = 0;

        for (uint8 i = 0; i < MOVES_COUNT; i++) {
            if (moves1[i] == moves2[i]) {
                // If players have done the same move, don't do anything.
                continue;
            } else if (moves1[i] == Move.BLOCK && moves2[i] != Move.BLOCK) {
                // fighter1 has blocked.
                receivedDamage2 += BLOCKED_RECEIVED_DAMAGE;
                receivedDamage1 += BLOCKER_RECEIVED_DAMAGE;
            } else if (moves2[i] == Move.BLOCK && moves1[i] != Move.BLOCK) {
                // fighter2 has blocked.
                receivedDamage2 += BLOCKER_RECEIVED_DAMAGE;
                receivedDamage1 += BLOCKED_RECEIVED_DAMAGE;
            } else {
                // No block - both players do damage.
                receivedDamage2 = toDamage(moves1[i]);
                receivedDamage1 = toDamage(moves2[i]);
            }
        }

        if (receivedDamage1 > receivedDamage2) {
            fighters[fighter1].alive = false;
        } else if (receivedDamage2 > receivedDamage1) {
            fighters[fighter2].alive = false;
        } else {
            fighters[fighter1].alive = false;
            fighters[fighter2].alive = false;
        }
    }
}
