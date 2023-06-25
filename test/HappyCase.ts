import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';
import { GameController, Marble } from '../typechain-types';

describe.only('Marblez', function () {
  let deployer: SignerWithAddress;
  let playerOne: SignerWithAddress;
  let playerTwo: SignerWithAddress;
  let marble: Marble;
  let controller: GameController;

  before(async function () {
    const signers = await ethers.getSigners();
    deployer = signers[0];
    playerOne = signers[1];
    playerTwo = signers[2];

    const Marble = await ethers.getContractFactory('Marble');
    marble = (await upgrades.deployProxy(Marble, ['Marble', 'MBL'])) as Marble;
    await marble.deployed();

    const GameController = await ethers.getContractFactory('GameController');
    controller = (await upgrades.deployProxy(GameController, [marble.address])) as GameController;
    await controller.deployed();
  });

  it('Must grant DEFAULT_ADMIN_ROLE, PAUSER_ROLE, MINTER_ROLE, UPGRADER_ROLE to msg.sender', async function () {
    expect(await marble.hasRole(await marble.DEFAULT_ADMIN_ROLE(), deployer.address)).to.be.true;
    expect(await marble.hasRole(await marble.PAUSER_ROLE(), deployer.address)).to.be.true;
    expect(await marble.hasRole(await marble.MINTER_ROLE(), deployer.address)).to.be.true;
    expect(await marble.hasRole(await marble.UPGRADER_ROLE(), deployer.address)).to.be.true;
  });

  it('Must grant Marble.MINTER_ROLE to PlayerOne', async function () {
    let txn = await marble.grantRole(await marble.MINTER_ROLE(), playerOne.address);
    await txn.wait();
    expect(await marble.hasRole(await marble.MINTER_ROLE(), playerOne.address)).to.be.true;
  });

  it('Must grant Marble.MINTER_ROLE to PlayerTwo', async function () {
    let txn = await marble.grantRole(await marble.MINTER_ROLE(), playerTwo.address);
    await txn.wait();
    expect(await marble.hasRole(await marble.MINTER_ROLE(), playerTwo.address)).to.be.true;
  });

  it('Must mint 1 token to PlayerOne and 1 token to PlayerTwo', async function () {
    let txn = await marble.safeMint(playerOne.address);
    await txn.wait();
    txn = await marble.safeMint(playerTwo.address);
    await txn.wait();
    expect(await marble.balanceOf(playerOne.address)).to.equal(1);
    expect(await marble.balanceOf(playerTwo.address)).to.equal(1);
  });

  it('Must grant controller approval to trade', async function () {
    let txn = await marble.connect(playerOne).setApprovalForAll(controller.address, true);
    await txn.wait();

    txn = await marble.connect(playerTwo).setApprovalForAll(controller.address, true);
    await txn.wait();

    expect(await marble.isApprovedForAll(playerOne.address, controller.address)).to.be.true;
    expect(await marble.isApprovedForAll(playerTwo.address, controller.address)).to.be.true;
  });

  it('Must trade tokens using the Game Controller', async function () {
    expect(await marble.ownerOf(0)).to.equal(playerOne.address);
    expect(await marble.ownerOf(1)).to.equal(playerTwo.address);

    let txn = await controller.connect(deployer).tradeMarble(playerOne.address, 0, playerTwo.address, 1);
    await txn.wait();

    expect(await marble.ownerOf(0)).to.equal(playerTwo.address);
    expect(await marble.ownerOf(1)).to.equal(playerOne.address);
  });
});
