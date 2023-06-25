import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';
import { Marble } from '../typechain-types';

describe('Marblez', function () {
  let deployer: SignerWithAddress;
  let marble: Marble;

  before(async function () {
    const signers = await ethers.getSigners();
    deployer = signers[0];

    const Marble = await ethers.getContractFactory('Marble');
    marble = (await upgrades.deployProxy(Marble, ['Marble', 'MBL'])) as Marble;
    await marble.deployed();

    return { deployer, marble };
  });

  it('Must grant DEFAULT_ADMIN_ROLE, PAUSER_ROLE, MINTER_ROLE, UPGRADER_ROLE to msg.sender', async function () {
    expect(await marble.hasRole(await marble.DEFAULT_ADMIN_ROLE(), deployer.address)).to.be.true;
    expect(await marble.hasRole(await marble.PAUSER_ROLE(), deployer.address)).to.be.true;
    expect(await marble.hasRole(await marble.MINTER_ROLE(), deployer.address)).to.be.true;
    expect(await marble.hasRole(await marble.UPGRADER_ROLE(), deployer.address)).to.be.true;
  });
});
