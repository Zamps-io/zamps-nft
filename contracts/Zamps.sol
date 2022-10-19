// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ZampsToken is ERC721, ERC721URIStorage, Ownable, ERC721Enumerable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 private constant _maxDepth = 5; // maximum number of links in the affiliate chain, indexed at 0

    uint256 private constant _branchingFactor = 10; // number of business cards each affiliate can distribute

    // Struct to hold affiliate
    struct Affiliate {
        uint256 depth; // the depth of the affiliate in the network (tree) of affiliates
        address account; // the address of the affiliate account
        address parentAccount; // the address that referred the affiliate
    }

    // Array of all affiliates in the order they joined the nework
    Affiliate[] private _affiliates;

    // Mapping from token ID to affiliate
    mapping(uint256 => Affiliate) private _tokenAffiliates;

    // Mapping from account address to owned token id array
    mapping(address => uint256[]) private _accountTokens;

    // Mapping from account address to affiliated token id array
    mapping(address => uint256[]) private _affiliatedTokens;

    // Mapping from addresses to their direct ancestors in the network in order (not including the contract owner account)
    mapping(address => address[]) private _affiliateAncestors;

    address private _clientAddress; // the address of the client business that the contract was created for

    // TODO - think about how to make the metadata unique/dynamic for each affiliate
    string private _tokenURI;

    constructor(address clientAccount, string memory clientTokenURI)
        ERC721("ZampsToken", "ZTK")
    {
        // mint the original set of business cards to the Zamps client account
        uint256 starting_depth = 0;

        // set the client account address and tokenURI
        _clientAddress = clientAccount;
        _tokenURI = clientTokenURI;

        _createBusinessCardsForAffiliate(
            address(0), // the client account has no parent in the tree, set parent as zero account
            clientAccount,
            starting_depth
        );
    }

    // listen to transfer event -> grab the sender and receiver -> mint business cards for receiver
    function _createBusinessCardsForAffiliate(
        address parentAccount,
        address newAffiliateAccount,
        // string memory _tokenURI,
        uint256 depth
    ) private {
        // update affiliate state
        Affiliate memory newAffilaite = Affiliate({
            depth: depth,
            account: newAffiliateAccount,
            parentAccount: parentAccount
        });
        _affiliates.push(newAffilaite);
        _updateAncestors(newAffilaite.account, parentAccount);

        // mint a set of business cards to the receiving affiliate
        for (uint256 i = 0; i < _branchingFactor; i++) {
            require(depth <= _maxDepth, "Max depth reached");
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _affiliatedTokens[newAffiliateAccount].push(tokenId);

            // mint ther token
            _safeMint(newAffiliateAccount, tokenId);

            // Right now the same tokenURI is used for all affiliates
            // TODO - make this dynamic in some way?
            _setTokenURI(tokenId, _tokenURI);

            // register the token with the affiliate
            _tokenAffiliates[tokenId] = Affiliate({
                depth: depth,
                account: newAffiliateAccount,
                parentAccount: parentAccount
            });
        }
    }

    modifier onlyAffiliate(uint256 tokenId) {
        require(
            _tokenAffiliates[tokenId].account == _msgSender(),
            "Caller is not the affiliate"
        );
        _;
    }

    modifier onlyClient() {
        require(
            _clientAddress == _msgSender(),
            "Caller is not the client that this contract was deployed for."
        );
        _;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAffiliate(tokenId) {
        require(
            balanceOf(to) < 1,
            "Receiving address is already an affiliate of this Zamps business network."
        );

        // Pass on the business card to the new affiliate
        super.transferFrom(from, to, tokenId);

        uint256 new_depth = _tokenAffiliates[tokenId].depth + 1;

        // Automatically cenerate a new set of business cards for the new affiliate
        _createBusinessCardsForAffiliate(from, to, new_depth);
    }

    function affiliates() public view returns (Affiliate[] memory) {
        return _affiliates;
    }

    function tokensOwnedBy(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256[] memory _tokensOfOwner = new uint256[](
            ERC721.balanceOf(_owner)
        );
        uint256 i;

        for (i = 0; i < ERC721.balanceOf(_owner); i++) {
            _tokensOfOwner[i] = ERC721Enumerable.tokenOfOwnerByIndex(_owner, i);
        }
        return (_tokensOfOwner);
    }

    function tokensAffiliatedTo(address affiliateAccount)
        public
        view
        returns (uint256[] memory)
    {
        require(
            balanceOf(affiliateAccount) >= 1,
            "Address is not current an affiliate in the network."
        );
        return _affiliatedTokens[affiliateAccount];
    }

    function _updateAncestors(
        address newAffiliateAccount,
        address parentAccount
    ) private {
        _affiliateAncestors[newAffiliateAccount] = _affiliateAncestors[
            parentAccount
        ];
        _affiliateAncestors[newAffiliateAccount].push(parentAccount);
    }

    function ancestorsOf(address affiliateAccount)
        public
        view
        returns (address[] memory)
    {
        require(
            balanceOf(affiliateAccount) > 0,
            "Must hold a business card and thus be a member of the affiliate network"
        );

        return _affiliateAncestors[affiliateAccount];
    }

    function processCommissions(address affiliateAccount, uint256 priceInWei)
        public
        onlyClient
    {
        require(
            balanceOf(affiliateAccount) > 0,
            "Only affiliates can receive commissions"
        );
        // TODO implement commisions calculations and distribution among ancestor affiliates of the purchaser
    }

    // The following are required function overrides to resolve multiple inheritance issues.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
