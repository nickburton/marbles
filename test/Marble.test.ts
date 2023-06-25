import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { expect } from 'chai';
import { ethers, upgrades } from 'hardhat';

describe('Marble', function () {
  async function deployContracts() {
    const signers = await ethers.getSigners();
    const deployer = signers[0];

    const Marble = await ethers.getContractFactory('Marble');
    const marble = await upgrades.deployProxy(Marble, ['Marble', 'MBL']);
    await marble.deployed();

    return { deployer, marble };
  }

  describe('initialize', function () {
    it('Must grant DEFAULT_ADMIN_ROLE, PAUSER_ROLE, MINTER_ROLE, UPGRADER_ROLE to msg.sender', async function () {
      const { deployer, marble } = await loadFixture(deployContracts);

      expect(await marble.hasRole(await marble.DEFAULT_ADMIN_ROLE(), deployer.address)).to.be.true;
      expect(await marble.hasRole(await marble.PAUSER_ROLE(), deployer.address)).to.be.true;
      expect(await marble.hasRole(await marble.MINTER_ROLE(), deployer.address)).to.be.true;
      expect(await marble.hasRole(await marble.UPGRADER_ROLE(), deployer.address)).to.be.true;
    });
  });
});
