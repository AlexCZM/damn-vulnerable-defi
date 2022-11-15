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

- A nice [video](https://www.youtube.com/watch?v=Aw7yvGFtOvI) explaining flash loans and small tutorial on hot to use aave flash loan.

* The challenge ask to 'stop the pool from offering flash loans'.
  Possible attack vector:

  - empties the pool
  - put the UnstoppableLender in an unusable state

  We can abuse line `assert(poolBalance == balanceBefore);` to block any future flash loans.

## 2. Naive Receiver

- The 'hack' in this challenge is simple. You have to call `flashLoan` function 10 times to drain all ETH funds from the user's contract. Or if you want to do it in a single transaction you can call it from another smart contract. I was looking for a smarter way to drain all eth in a single transaction tbh.

## 3. Truster

Ok, for this challenge I spend way to much time after I found the attack entry point. You may saw already that the weak point is `target.functionCall(data);` line from TrusterLenderPool. On short you have to pass the (erc20) approve function signature with attacker address and TrusterLenderPool balance. That's it! Next all you have to do is to call `transferFrom` function. (pay attention, token contract must be connected to `attacker` address).
Payload can be computed offchain or onchain. `truster.challenge.js` script has both solutions, modify `onChainAttack` as you wish. Also `damnValuableTokenAbiPath` variable is hardcoded, you may need to update it.

Some of the things I've tried:

- I order to repay the loan I was thinking how can I call the `approve` function and to repay the loan by passing 2 function in same payload. If I wanted to pass my 'attack' function to payload and my 'attack' to call both approve and repay function I was losing `TrusterLenderPool` msg.sender context required for `approve`. It took me a few minutes to see I can call `flashLoan` with 0 `borrowAmount`.
- I was getting a failed low level call because I added a space between arguments type when calculating function signature:

  `abi.encodeWithSignature("approve(address, uint256)", _attacker, poolBalance);` instead of

  `abi.encodeWithSignature("approve(address,uint256)", _attacker, poolBalance);`

- I called `transferFrom` with token contract connected to `deployer` instead of `attacker`.

## 4. Side Entrance

- This one is nice. At first I was focusing only on `execute` function and asking myself how I can repay the loan but also to insert a back door (I was thinking something similar to erc20 approve) so I can get the ether later. After a longer break I saw it: I can use `deposit` to repay the loan and to have a trackable balance within lender pool. Ta daa! :)
