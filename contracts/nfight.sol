// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract Nfight {
    uint8 public constant HITS_COUNT = 5;
    uint8 public constant MAX_DUELS_PER_FIGHT_DAY = 100;

    enum Hit {
        UP,
        CENTER,
        DOWN
    }

    struct Moves {
        Hit[HITS_COUNT] hits;
    }
  
    struct MovesStorage {
        Moves moves;
        bool set;
    }

    struct Fighter {
        bool alive;
    }

    mapping(address => MovesStorage) public moves;
    mapping(address => Fighter) public fighters;
    address public arbiter;
    address[] public fighters_in_fight_day;

    constructor() {
        arbiter = msg.sender;
    }

    function enlist() external {
        fighters[msg.sender].alive = true;
    }

    function preMove(Moves calldata m) external {
        require(fighters[msg.sender].alive);
        require(!moves[msg.sender].set);
        require(fighters_in_fight_day.length < MAX_DUELS_PER_FIGHT_DAY);
        moves[msg.sender].moves = m;
        moves[msg.sender].set = true;
        fighters_in_fight_day.push(msg.sender);
    }

    function matchAndExecuteDuels() external {
        require(arbiter == msg.sender);
        for (uint i = 0; i < fighters_in_fight_day.length; i++) {

        }
        delete fighters_in_fight_day;
    }

    function executeDuel(address fighter1, address fighter2) private {

    }
}
