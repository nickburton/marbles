Getting set up from a clean repo:

```shell
npm install --save-dev hardhat-toolbox
npm install --save-dev @nomicfoundation/hardhat-toolbox
npm i @openzeppelin/contracts-upgradeable
```

```shell
npx hardhat compile
npx hardhat node
npx hardhat test
npx hardhat run scripts/deploy.ts
```
