// SPDX-License-Identifier: MIT LICENSE
// Contract: Project Dignity's Halloween Seals
// Token ID: "ProjectDignityHalloweenSeals"
// Token Symbol: "PD-HS"
// Author: tiffanydys
// Coder: tiffanydys
// Artists: paluras & vadimas (VP)
// Initiator: Donatas (Dee)
// ---- CONTRACT BEGINS HERE ----

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

pragma solidity ^0.8.0;

contract HalloweenSeals is ERC721Enumerable, Ownable {
    
    using Strings for uint256;
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public sealSupply = 0;
    uint256 public maxSupply = 9;
    bool public paused = false;
    bool public whitelistOnly = false;

    constructor(
      string memory _name,
      string memory _symbol,
      string memory _initBaseURI
    ) ERC721(_name, _symbol) {
      setBaseURI(_initBaseURI);
    }

    // internal
    function _baseURI() internal view virtual override returns (string memory) {
      return baseURI;
    }

    function mint() public onlyOwner() {
        require(!paused, "Minting is paused.");

        _safeMint(msg.sender, sealSupply + 1);
        sealSupply = sealSupply + 1;
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

    function setBaseURI(string memory _newBaseURI) public onlyOwner() {
        baseURI = _newBaseURI;
    }
    
    function setBaseExtension(string memory _newBaseExtension) public onlyOwner() {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner() {
        paused = _state;
    }
}