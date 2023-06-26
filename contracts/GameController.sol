// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./Marble.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

contract GameController is UUPSUpgradeable, IERC721Receiver, PausableUpgradeable {
    struct Bid {
        address bidder;
        uint256 bidderTokenId;
        uint256 bidderHitsToWin;
        address opponent;
        uint256 opponentTokenId;
        uint256 opponentHitsToWin;
        bool accepted;
        bool tokenOneReceived;
        bool tokenTwoReceived;
        uint256 id;
    }

    mapping(uint256 => Bid) public bids;
    mapping(uint256 => Bid) public counters;

    Marble public marble;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _marble) public initializer {
        marble = Marble(_marble);
    }

    function submitBid(
        uint256 tokenId,
        uint256 hitsToWin,
        address opponent,
        uint256 opponentTokenId,
        uint256 opponentHitsToWin
    ) external {
        require(
            marble.ownerOf(tokenId) == msg.sender,
            "GameController: Caller is not owner of `tokenId"
        );
        require(
            marble.ownerOf(opponentTokenId) == opponent,
            "GameController: Opponent is not owner of `opponentTokenId`"
        );
        Bid memory bid = bids[tokenId];
        require(bid.accepted == false, "GameController: Bid already accepted");

        uint256 bidId = 1;
        if (bid.bidder != address(0)) {
            bidId = bid.id + 1;
        }
        bid = Bid({
            bidder: msg.sender,
            bidderTokenId: tokenId,
            bidderHitsToWin: hitsToWin,
            opponent: opponent,
            opponentTokenId: opponentTokenId,
            opponentHitsToWin: opponentHitsToWin,
            accepted: false,
            tokenOneReceived: false,
            tokenTwoReceived: false,
            id: bidId
        });
        bids[tokenId] = bid;
        counters[opponentTokenId] = bid;
    }

    function acceptBid(uint256 tokenId, uint256 _bidId) external {
        Bid memory bid = bids[tokenId];
        require(bid.bidder != address(0), "GameController: Bid does not exist");
        require(bid.accepted == false, "GameController: Bid already accepted");
        require(bid.id == _bidId, "GameController: `_bidId` refers to old bid"); // Note: prevents frontrunning
        require(
            marble.ownerOf(bid.opponentTokenId) == msg.sender,
            "GameController: Caller is not owner of `tokenId"
        );
        bids[tokenId].accepted = true;
        _takeMarbles(bid.bidder, bid.bidderTokenId, bid.opponent, bid.opponentTokenId);
    }

    function _takeMarbles(
        address bidder,
        uint256 bidderTokenId,
        address opponent,
        uint256 opponentTokenId
    ) internal {
        require(
            marble.isApprovedForAll(bidder, address(this)),
            "GameController: Controller not approved to transfer from bidder"
        );
        require(
            marble.isApprovedForAll(opponent, address(this)),
            "GameController: Controller not approved to transfer frp, opponent"
        );

        marble.safeTransferFrom(bidder, address(this), bidderTokenId, "");
        marble.safeTransferFrom(opponent, address(this), opponentTokenId, "");
    }

    function _playGame() internal pure returns (uint256) {
        uint256 winner = 1;
    }

    function _transferTokensTo(address to, uint256 tokenId) internal {
        marble.safeTransferFrom(address(this), to, tokenId, "");
    }

    function _authorizeUpgrade(address newImplementation) internal virtual override {}

    function onERC721Received(
        address,
        address from,
        uint256 tokenId,
        bytes memory
    ) public virtual whenNotPaused returns (bytes4) {
        Bid memory bid = bids[tokenId];
        Bid memory counter = counters[tokenId];
        require(
            bid.bidder != address(0) || counter.bidder != address(0),
            "GameController: Bid does not exist"
        );
        require(bid.accepted == true || counter.accepted == true, "GameController: Bid not accepted");
        require(
            bid.bidder == from || bid.opponent == from,
            "GameController: Caller is not opponent or bidder"
        );
        require(address(marble) == msg.sender, "GameController: Caller is not Marble contract");

        if (bid.bidder == from) {
            bids[tokenId].tokenOneReceived = true;
            counters[tokenId].tokenOneReceived = true;
        } else {
            bids[tokenId].tokenTwoReceived = true;
            counters[tokenId].tokenTwoReceived = true;
            uint256 winner = _playGame();
            if (winner == 0) {
                _transferTokensTo(bid.bidder, bid.opponentTokenId);
            } else {
                _transferTokensTo(bid.opponent, bid.bidderTokenId);
            }
        }

        return this.onERC721Received.selector;
    }
}
