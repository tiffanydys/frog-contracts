// SPDX-License-Identifier: MIT LICENSE
// Contract: Sunflower Land - Frogs
// Token ID: "SunflowerLandFrogs"
// Token Symbol: "SFL-F"
// Author: tiffanydys
// Coder: tiffanydys
// Artists: paluras & vadimas (VP)
// Initiator: Donatas (Dee)
// ---- CONTRACT BEGINS HERE ----

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

pragma solidity ^0.8.0;

// copied from Farm.sol
struct Farm {
    address ownerAddress;
    address farmAddress;
    uint256 farmId;
}

interface SFLFarmContract {
    function getFarm(uint256 tokenId) external view returns (Farm memory); // external needed not public
}

contract Frogs is ERC721Enumerable, Ownable {
    SFLFarmContract private sflFarmContract;

    struct TokenInfo {
        IERC20 paytoken;
        uint256 costvalue;
    }

    TokenInfo[] public AllowedCrypto;
    
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public frogSupply = 0;
    uint256 public maxSupply = 520; // 500 total supply + 16 for giveaway + 4 for the team
    bool public paused = false;
    bool public whitelistOnly = false;
    uint256 founderSize;
    uint256 whitelistSize;
    uint256 blacklistSize;
    mapping(address => bool) public founder;
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public blacklisted;

    constructor(
      string memory _name,
      string memory _symbol,
      string memory _initBaseURI,
      address farmContractAddress
    ) ERC721(_name, _symbol) {
      setBaseURI(_initBaseURI);
      sflFarmContract = SFLFarmContract(farmContractAddress);
    }

    function addCurrency(
        IERC20 _paytoken,
        uint256 _costvalue
    ) public onlyOwner {
        AllowedCrypto.push(
            TokenInfo({
                paytoken: _paytoken,
                costvalue: _costvalue
            })
        );
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
    }

    function mint(uint256 _pid, uint256 _farmId) public payable {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        uint256 cost;
        cost = tokens.costvalue;
        address ownerAddress = getFarmOwner(_farmId);

        // if you are one of the founders (Tiff,Dee,paluras,VP) you get a free mint
        if (founder[ownerAddress] == true) {
            cost = 0;
        }
        
        require(!paused, "Minting is paused.");
        require(frogSupply + 1 <= maxSupply, "Max supply reached!");
        require(msg.sender == ownerAddress, "You are not the owner of this farm.");
        require(blacklisted[ownerAddress] != true, "This farm has already minted a frog.");

        if (whitelistOnly == true) {
            require(whitelisted[ownerAddress] == true, "This farm is not whitelisted.");
        }

        // Send SFL token to dead address
        paytoken.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, cost);
        _safeMint(ownerAddress, frogSupply + 1);
        frogSupply = frogSupply + 1;
        blacklisted[ownerAddress] = true;
        blacklistSize = blacklistSize + 1;
    }

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    
    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory) {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
            );
            
            string memory currentBaseURI = _baseURI();
            return
            bytes(currentBaseURI).length > 0 
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    // Check if address is whitelisted
    function isAddressWhitelisted(address _address) public view returns (bool) {
        return whitelisted[_address] == true;
    }

    // Check if address is blacklisted
    function isAddressBlacklisted(address _address) public view returns (bool) {
        return blacklisted[_address] == true;
    }

    // Check if address is founder
    function isAddressFounder(address _address) public view returns (bool) {
        return founder[_address] == true;
    }

    function retrieveMapSize(uint256 mapId) public view returns (uint256) {
        if (mapId == 1) {
            return founderSize;
        } else if (mapId == 2) {
            return whitelistSize;
        } else if (mapId == 3) {
            return blacklistSize;
        }
        return 0;
    } 

    // --------------- OWNLY OWNER FUNCTIONS ---------------
    // Blacklist an address format: ["0x0000...",...]
    function blacklistUser(address[] memory _user) public onlyOwner() {
        uint256 x = 0;
        for (x = 0; x < _user.length; x++) {
            blacklisted[_user[x]] = true;
            blacklistSize = blacklistSize + 1;
        }
    }

    function removeBlacklistUser(address[] memory _user) public onlyOwner() {
        uint256 x = 0;
        for (x = 0; x < _user.length; x++) {
            blacklisted[_user[x]] = false;
            blacklistSize = blacklistSize - 1;
        }
    }

    // Whitelist an address format: ["0x0000...",...]
    function whitelistUser(address[] memory _user) public onlyOwner() {
        uint256 x = 0;
        for (x = 0; x < _user.length; x++) {
            whitelisted[_user[x]] = true;
            whitelistSize = whitelistSize + 1;
        }
    }

    function removeWhitelistUser(address[] memory _user) public onlyOwner() {
        uint256 x = 0;
        for (x = 0; x < _user.length; x++) {
            whitelisted[_user[x]] = false;
            whitelistSize = whitelistSize - 1;
        }
    }

    // Add founder format: ["0x0000...",...]
    function addFounder (address[] memory _user) public onlyOwner() {
        uint256 x = 0;
        for (x = 0; x < _user.length; x++) {
            founder[_user[x]] = true;
            founderSize = founderSize + 1;
        }
    }

    function removeFounder(address[] memory _user) public onlyOwner() {
        uint256 x = 0;
        for (x = 0; x < _user.length; x++) {
            founder[_user[x]] = false;
            founderSize = founderSize - 1;
        }
    }
    
    function activateWhitelist(bool _state) public onlyOwner() {
        whitelistOnly = _state;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner() {
        baseURI = _newBaseURI;
    }
    
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner() {
        baseExtension = _newBaseExtension;
    }

    function setFarmContractAddr(address farmContractAddress) public onlyOwner() {
        sflFarmContract = SFLFarmContract(farmContractAddress);
    }

    function pause(bool _state) public onlyOwner() {
        paused = _state;
    }

    function getFarmContractAddr() public view returns(address) {
        return address(sflFarmContract);
    }

    function getFarmOwner(uint256 tokenId) public view returns(address) {
        Farm memory farms = sflFarmContract.getFarm(tokenId);

        return farms.ownerAddress;
    }

    function withdraw(uint256 _pid) public payable onlyOwner() {
        TokenInfo storage tokens = AllowedCrypto[_pid];
        IERC20 paytoken;
        paytoken = tokens.paytoken;
        paytoken.transfer(msg.sender, paytoken.balanceOf(address(this)));
    }
}