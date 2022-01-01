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
    address public arbiter;
    address[] public fightersPerFightDay;

    modifier onlyArbiter() {
        require(msg.sender == arbiter);
        _;
    }

    constructor() {
        arbiter = msg.sender;
    }

    function enlist() external {
        fighters[msg.sender].alive = true;
    }

    function preMove(Move[MOVES_COUNT] calldata m) external {
        require(fighters[msg.sender].alive);
        require(!moves[msg.sender].set);
        require(fightersPerFightDay.length < MAX_FIGHTERS_PER_FIGHT_DAY);
        moves[msg.sender].moves = m;
        moves[msg.sender].set = true;
        fightersPerFightDay.push(msg.sender);
    }

    function random(uint to) private view returns(uint) {
        require(block.number >= 1);
        uint h = uint(blockhash(block.number - 1));
        return (h % to);
    }

    function matchFightersAndExecuteDuels() external onlyArbiter {
        if (fightersPerFightDay.length < 2) {
            return;
        }

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
        // TODO: handle leftover fighters
        require(fightersPerFightDay.length == 0);
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
