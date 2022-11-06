// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

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
    mapping(address => address payable[]) private _affiliateAncestors;

    string private _baseImageURI =
        "https://bafybeifgbpikn4unzzewsb5p36ydmigbfqcu2pf6ap6dz4s4ckgayif2ua.ipfs.w3s.link/depth_";

    // approved addresses can call distribute function
    mapping(address => bool) public distributeWhitelist;

    constructor(address clientAccount) ERC721("ZampsToken", "ZTK") {
        // mint the original set of business cards to the Zamps client account
        uint256 starting_depth = 0;

        _createBusinessCardsForAffiliate(
            address(0), // the client account has no parent in the tree, set parent as zero account
            clientAccount,
            starting_depth
        );
    }

    // Generates a tokenURI using Base64 string as the image
    // Returns cached value if metadata for this depth already computed
    function getDataURI(uint256 depth) public view returns (string memory) {
        // Otherwise compute the metadata json, encode in Base64
        // Cache and return formatted data uri
        string memory name = string(
            string.concat("Zamps token depth ", Strings.toString(depth))
        );
        string memory description = "Zamps Business Cards";
        string memory imageURI = string.concat(
            _baseImageURI,
            Strings.toString(depth),
            ".svg"
        );

        string memory metadataJson = string.concat(
            '{"name": "',
            name,
            '", ',
            '"description": "',
            description,
            '", ',
            '"image": "',
            imageURI,
            '"}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(metadataJson))
                )
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

        // Set depth dependent tokenURI
        string memory dataURI = getDataURI(depth); // cache this if depth already reached

        // mint a set of business cards to the receiving affiliate
        for (uint256 i = 0; i < _branchingFactor; i++) {
            require(depth <= _maxDepth, "Max depth reached");
            uint256 tokenId = _tokenIdCounter.current();
            _tokenIdCounter.increment();
            _affiliatedTokens[newAffiliateAccount].push(tokenId);

            // mint the token
            _safeMint(newAffiliateAccount, tokenId);
            _setTokenURI(tokenId, dataURI);

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

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) onlyAffiliate(tokenId) {
        require(
            balanceOf(to) < 1,
            "Receiving address is already an affiliate of this Zamps business network."
        );

        // Pass on the business card to the new affiliate
        super._transfer(from, to, tokenId);

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
        _affiliateAncestors[newAffiliateAccount].push(payable(parentAccount));
    }

    function ancestorsOf(address affiliateAccount)
        public
        view
        returns (address payable[] memory)
    {
        require(
            balanceOf(affiliateAccount) > 0,
            "Must hold a business card and thus be a member of the affiliate network"
        );

        return _affiliateAncestors[affiliateAccount];
    }

    function distribute(address cardHolder) public payable {
        require(
            balanceOf(cardHolder) >= 1,
            "Address is not current an affiliate in the network."
        );
        address payable[] memory ancestors;

        ancestors = _affiliateAncestors[cardHolder];
        uint256 payout = msg.value;

        for (uint256 i = ancestors.length - 1; i > 1; i--) {
            address payable ancestor = ancestors[i];
            ancestor.transfer((payout * 8500) / 10000);
            payout = (payout * 1500) / 10000; //still got the research about floats...
        }
    }

    function addToWhitelist(address[] calldata addressesToAdd)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addressesToAdd.length; i++) {
            distributeWhitelist[addressesToAdd[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata addressesToRemove)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < addressesToRemove.length; i++) {
            delete distributeWhitelist[addressesToRemove[i]];
        }
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

//this is how we can make the TOKEN_URI dynamic. We can start off simple and
//in the input the business puts the IPFS string to describe their business card
//later we can take inputs and create the IPFS content url in our code

contract ZampsTokenFactory {
    mapping(address => address[]) public businessOwnersContracts;

    ZampsToken[] public tokens;

    event Created(address _tokenAddress);

    function create(address origin) public {
        ZampsToken token = new ZampsToken(origin);
        tokens.push(token);
        businessOwnersContracts[origin].push(address(token));
        emit Created(address(token));
    }
}
