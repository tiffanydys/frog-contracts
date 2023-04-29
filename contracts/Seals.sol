// SPDX-License-Identifier: MIT LICENSE
// Contract: Project Dignity - Seals
// Token ID: "ProjectDignitySeals"
// Token Symbol: "PD-S"
// Author: tiffanydys
// Coder: tiffanydys
// Artists: paluras & vadimas (VP)
// Initiator: Donatas (Dee)
// ---- CONTRACT BEGINS HERE ----

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "https://github.com/tiffanydys/frogs-contracts/blob/main/src/contracts/Frogs.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

pragma solidity ^0.8.0;

contract Seals is ERC721Enumerable, Ownable {
    struct TokenInfo {
        IERC20 paytoken1;
        IERC20 paytoken2;
        uint256 costvalue1;
        uint256 costvalue2;
        uint256 costvalue3;
    }

    TokenInfo[] public AllowedCryptoSeals;
    
    Frogs frogNft;
    address public fundAddress;
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public sealSupply = 0;
    uint256 public allowedMintSupply = 3000;
    uint256 public mintWave;
    uint256 public activePID;
    bool public paused = true;
    uint256 blacklistSize;
    uint256 blacklistFrogSize;
    mapping(address => bool) public blacklisted;
    mapping(uint256 => bool) public blacklistedFrog;
    mapping(uint256 => string) public rarity;

    constructor(
      string memory _name,
      string memory _symbol,
      string memory _initBaseURI,
      address _fundAddress,
      Frogs _frogNft
    ) ERC721(_name, _symbol) {
      setBaseURISeals(_initBaseURI);
      setFundAddress(_fundAddress);
      frogNft = _frogNft;
      setMintWave(0, 3000, 0);
    }

    function addCurrencySeals(
        IERC20 _paytoken1,
        IERC20 _paytoken2,
        uint256 _costvalue1,
        uint256 _costvalue2,
        uint256 _costvalue3
    ) public onlyOwner {
        AllowedCryptoSeals.push(
            TokenInfo({
                paytoken1: _paytoken1,
                paytoken2: _paytoken2,
                costvalue1: _costvalue1,
                costvalue2: _costvalue2,
                costvalue3: _costvalue3
            })
        );
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
    }

    function mint(uint256 _frogId) public payable {
        require(!paused, "Minting is paused.");
        require(sealSupply + 1 <= allowedMintSupply, "Max supply reached!");

        TokenInfo storage tokens = AllowedCryptoSeals[activePID];
        IERC20 paytokenSFL;
        IERC20 paytokenPDWL;

        paytokenSFL = tokens.paytoken1;
        paytokenPDWL = tokens.paytoken2;

        uint256 costSFL = tokens.costvalue1;
        uint256 costPDWL = tokens.costvalue2;
        uint256 costMATIC = tokens.costvalue3;

        if (msg.sender == owner()) {
            costSFL = 0;
            costMATIC = 0;
            costPDWL = 0;
        }

        // whitelist minting
        if (mintWave == 0) {
            // mint using frog
            if (_frogId >= 1) {
                require(msg.sender == checkFrogOwner(_frogId), "You are not the owner of this frog.");
                require(blacklistedFrog[_frogId] != true, "This frog has already minted a Seal.");
                // do not burn any PD-WL tokens if they used frog for whitelist mint
                costPDWL = 0;
            }
        }

        // do not burn SFL/PD-WL tokens on public mint
        if (mintWave > 0) {
            costSFL = 0;
            costPDWL = 0;
        }


        require(msg.value >= costMATIC, "You do not have enough MATIC for this mint.");

        // blacklist frog after successful whitelist mint
        if (mintWave == 0 && _frogId >= 1) {
            blacklistedFrog[_frogId] = true;
            blacklistFrogSize = blacklistFrogSize + 1;
        }

        if (costSFL > 0) {
            paytokenSFL.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, costSFL);
        }

        if (costPDWL > 0) {
            paytokenPDWL.transferFrom(msg.sender, 0x000000000000000000000000000000000000dEaD, costPDWL);
        }
        
        _safeMint(msg.sender, sealSupply + 1);
        sealSupply = sealSupply + 1;
    }

    function walletOfOwnerSeals(address _owner)
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

    // Check if frog is blacklisted
    function isFrogBlacklisted(uint256 _frogId) public view returns (bool) {
        return blacklistedFrog[_frogId] == true;
    }

    // Check if address is blacklisted
    function isAddressBlacklisted(address _address) public view returns (bool) {
        return blacklisted[_address] == true;
    }

    // Check Seal Rarity
    function checkSealRarity(uint256 _sealId) public view returns (string memory) {
        return rarity[_sealId];
    }

    function retrieveMapSize(uint256 mapId) public view returns (uint256) {
        if (mapId == 1) {
            return blacklistSize;
        } else if (mapId == 2) {
            return blacklistFrogSize;
        }
        return 0;
    } 

    function checkFrogOwner(uint256 frogId) public view returns (address) {
        return frogNft.ownerOf(frogId);
    }

    // --------------- OWNLY OWNER FUNCTIONS ---------------
    // update seal rarity manually on reveal
    function updateSealRarity(uint256[] memory _sealId, string[] memory _rarity) public onlyOwner() {
        uint256 x = 0;
        for (x = 0; x < _rarity.length; x++) {
            rarity[_sealId[x]] = _rarity[x];
        }
    }

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

    // Blacklist a frog format: [312,...]
    function blacklistFrog(uint256[] memory _frogId) public onlyOwner() {
        uint256 x = 0;
        for (x = 0; x < _frogId.length; x++) {
            blacklistedFrog[_frogId[x]] = true;
            blacklistFrogSize = blacklistFrogSize + 1;
        }
    }

    function removeBlacklistFrog(uint256[] memory _frogId) public onlyOwner() {
        uint256 x = 0;
        for (x = 0; x < _frogId.length; x++) {
            blacklistedFrog[_frogId[x]] = false;
            blacklistFrogSize = blacklistFrogSize - 1;
        }
    }

    function setMintWave(uint256 _waveNumber, uint256 _waveSupply, uint256 _pid) public onlyOwner() {
        mintWave = _waveNumber;
        allowedMintSupply = _waveSupply;
        activePID = _pid;
    }

    function setFundAddress(address _fundAddress) public onlyOwner() {
        fundAddress = _fundAddress;
    }

    function setBaseURISeals(string memory _newBaseURI) public onlyOwner() {
        baseURI = _newBaseURI;
    }
    
    function setBaseExtensionSeals(string memory _newBaseExtension) public onlyOwner() {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner() {
        paused = _state;
    }

    function withdraw() public onlyOwner() {
        // get the balance of the contract
        uint256 balance = address(this).balance;
        payable(fundAddress).transfer(balance);
    }
}