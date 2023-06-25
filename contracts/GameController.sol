// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Marble.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract GameController is UUPSUpgradeable {
    Marble private _marble;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address marble) public initializer {
        _marble = Marble(marble);
    }

    function tradeMarble(address from, uint256 fromTokenId, address to, uint256 toTokenId) public {
        require(
            _marble.isApprovedForAll(from, address(this)),
            "GameController: Controller not approved to transfer from token"
        );
        require(
            _marble.isApprovedForAll(to, address(this)),
            "GameController: Controller not approved to transfer to token"
        );

        _marble.safeTransferFrom(from, to, fromTokenId, "");
        _marble.safeTransferFrom(to, from, toTokenId, "");
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {}
}
