// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Marble.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

contract GameController is ERC721HolderUpgradeable {
    Marble private _marbleContract;

    constructor(address marbleContractAddress) {
        _marbleContract = Marble(marbleContractAddress);
    }

    function tradeMarble(address from, uint256 fromTokenId, address to, uint256 toTokenId) public {
        require(
            _marbleContract.getApproved(fromTokenId) == address(this),
            "Controller not approved to transfer from token"
        );
        require(
            _marbleContract.getApproved(toTokenId) == address(this),
            "Controller not approved to transfer to token"
        );

        _marbleContract.safeTransferFrom(from, to, fromTokenId, "");
        _marbleContract.safeTransferFrom(to, from, toTokenId, "");
    }
}
