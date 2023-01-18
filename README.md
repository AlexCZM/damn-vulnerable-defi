![](cover.png)

**A set of challenges to learn offensive security of smart contracts in Ethereum.**

Featuring flash loans, price oracles, governance, NFTs, lending pools, smart contract wallets, timelocks, and more!

## Play

Visit [damnvulnerabledefi.xyz](https://damnvulnerabledefi.xyz)

## Disclaimer

All Solidity code, practices and patterns in this repository are DAMN VULNERABLE and for educational purposes only.

DO NOT USE IN PRODUCTION.

#

# Personal notes about challenges:

## 1. Unstoppable

-   A nice [video](https://www.youtube.com/watch?v=Aw7yvGFtOvI) explaining flash loans and small tutorial on how to use aave flash loan.

*   The challenge ask to 'stop the pool from offering flash loans'.
    Possible attack vector:

    -   empties the pool
    -   put the UnstoppableLender in an unusable state

    We can abuse line `assert(poolBalance == balanceBefore);` to block any future flash loans.

## 2. Naive Receiver

-   The 'hack' in this challenge is simple. You have to call `flashLoan` function 10 times to drain all ETH funds from the user's contract. Or if you want to do it in a single transaction you can call it from another smart contract. I was looking for a smarter way to drain all eth in a single transaction tbh.

## 3. Truster

Ok, for this challenge I spend way to much time after I found the attack entry point. You may saw already that the weak point is `target.functionCall(data);` line from TrusterLenderPool. On short you have to pass the (erc20) approve function signature with attacker address and TrusterLenderPool balance. That's it! Next all you have to do is to call `transferFrom` function. (pay attention, token contract must be connected to `attacker` address).
Payload can be computed offchain or onchain. `truster.challenge.js` script has both solutions, modify `onChainAttack` as you wish. Also `damnValuableTokenAbiPath` variable is hardcoded, you may need to update it.

Some of the things I've tried:

-   I order to repay the loan I was thinking how can I call the `approve` function and to repay the loan by passing 2 function in same payload. If I wanted to pass my 'attack' function to payload and my 'attack' to call both approve and repay function I was losing `TrusterLenderPool` msg.sender context required for `approve`. It took me a few minutes to see I can call `flashLoan` with 0 `borrowAmount`.
-   I was getting a failed low level call because I added a space between arguments type when calculating function signature:

    `abi.encodeWithSignature("approve(address, uint256)", _attacker, poolBalance);` instead of

    `abi.encodeWithSignature("approve(address,uint256)", _attacker, poolBalance);`

-   I called `transferFrom` with token contract connected to `deployer` instead of `attacker`.

## 4. Side Entrance

-   This one is nice. At first I was focusing only on `execute` function and asking myself how I can repay the loan but also to insert a back door (I was thinking something similar to erc20 approve) so I can get the ether later. After a longer break I saw it: I can use `deposit` to repay the loan and to have a trackable balance within lender pool. Ta daa! :)

## 5. The Rewarder

-   This was a nice challenge. Intuitively I had an idea what I have to do (get a flash loan, deposit to reward pool right before the snapshot is taken, repay the loan). The most time I spend to check how ERC20Snapshot works (just wow :) ), AccessControl and ERC165 (even if I still have questions for this standard). I don't have more to say about this challenge, I enjoy it a lot and I added plenty of comments in `TheRewardAttacker` contract and `the-reward.challenge.js` script.

## 6. Selfie

-   After I got familiar with snapshot functionality from previous challenge, this one went fast.
-   On short:

    -   create an attacker smart contract:
        -   Implement `receiveTokens`;
            -   get `drainAllFunds` function signature;
            -   call token `snapshot`;
            -   call `queueAction` and pass signature calculated above;
            -   repay the loan;
        -   invoke `flashLoan`;

    *   time travel 2 days;
    *   execute `executeAction`;

## 7. tbd

## 8. Puppet

-   UniswapV1 is based on a simple formula:
    `x * y = k`
    Meaning that at any point in time the product of tokens from a (liquidity) pool must be constant.
    For our pool we have 10(eth) \* 10(DVT) = 100.
    To keep things simple I ignore the fee factor(0.3%).
    If we sell our 1k DVT tokens:

x \* (1000 + 10) = 100 => x ~= 0.1 ETH

-> 1 DVT = 0.0001 ETH

-   Puppet pool offers loans if the value of collateral is 2x the value of DVT tokens you want to borrow. This means we can drain all tokens for as much as 0.1 /1010 \* 100000 \* 2 ~= 20 ETH.

    NOTES:

-   If you get `Error: Transaction reverted without a reason string` error when interacting with UniswapV1 add a gas limit of `{ gasLimit: 1e6 }` to transaction.

*   Usefull links:
    -   [UniswapV1 interfaces](https://docs.uniswap.org/contracts/v1/reference/interfaces#solidity-1)
    -   [UniswapV1 vyper implementations](https://github.com/Uniswap/v1-contracts/blob/master/contracts/uniswap_exchange.vy)

## 9. Puppet v2

-   This challenge is mostly identical to previous one. The price oracle is based on a low liquidity (100 tokens) which is susceptible to price manipulation (attacker balance is 10k tokens, 100x more).
-   You can read about Uniswap V2 on [github](https://github.com/Uniswap/v2-core) or on [this](https://jeiwan.net/posts/programming-defi-uniswapv2-1/) blog post.

## 10. Free-rider

-   The vulnerability in this challenge was sitting in plain sight; I was looking for different kind of problems but this is a good example of how wrong developer assumption can lead to loss of assets. Moreover check if code is doing what's in comments.
-   The vulnerability lays in `payable(token.ownerOf(tokenId)).sendValue(priceToPay);` line. First the tokenId is sent to msg.sender, next the intention is to send the `priceToPay` amount to seller. But the token has a **new** owner already. The fix is simple in this case: transfer `tokenId` AFTER seller was paid.

## 11. Backdoor

-   One of the difficult challenge until now. Main reason for this is I didn't knew GnosisSafe previously. It took me a few days to understand it and poke it here and there.
-   A good [video](https://www.youtube.com/watch?v=_2ZJ5HBEfUk) explaining it. And the [slides](https://hackmd.io/@kyzooghost/HJMi2Nllq#/36).
-   Since the script didn't create the wallets, 'attacker' will do it in the name of users:
    -   `GnosisSafeProxyFactory` (note: GnosisSafe == GS) deploy new GSProxy using `createProxyWithCallback`.(or createProxy but we need the other method withCallback).
    -   `_singleton` is the 'logic' contract. Each call to GSProxy will be delegatecall-ed to logic contract. 'logic' contract methods are executed in the context(storage -- even if storage variables aren't declared, storage is changed --,msg.sender, msg.value) of GSProxy.
    -   `initializer` is first call to GSProxy. `WalletRegistry` requires to call `GnosisSafe::setup`.
    -   initially I wanted to abuse the 'module' functionality (`setupModules` method). But the execute function enters `if(operation == Enum.Operation.DelegateCall)` branch and msg.sender is not GSProxy. Still I don't think it's not possible to get tokens using module functionality.
    -   but since `internalSetFallbackHandler` provides the low level `call` I needed, I passed token address as `fallbackHandler`. Each ERC20::transfer() passed to GSProxy will be executed by token contract. Moreover `msg.sender` inside token contract will be....GSProxy contract, exactly. The contract that received 10 tokens.
