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

The 'hack' in this challenge is simple. You have to call `flashLoan` function 10 times to drain all ETH funds from the user's contract. Or if you want to do it in a single transaction you can call it from another smart contract. I was looking for a smarter way to drain all eth in a single transaction tbh.
