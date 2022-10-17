// SPDX-License-Identifier: MIT LICENSE
// Contract: SFL x Project Dignity - Tadpoles
// Token ID: "ProjectDignityTadpoles"
// Token Symbol: "PD-T"
// Author: tiffanydys
// Coder: tiffanydys
// Artists: paluras & vadimas (VP)
// Initiator: Donatas (Dee)
// ---- CONTRACT BEGINS HERE ----

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

pragma solidity ^0.8.0;

contract Tadpoles is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    using Strings for uint256;
    address public incubatorAddress;
    address public minterAddress;
    uint256 public maxSupply = 200;
    bool public paused = false;

    string[] tadpoleUri = [
      "https://raw.githubusercontent.com/tiffanydys/frogs/main/tadpoles/data/healthy.json",
      "https://raw.githubusercontent.com/tiffanydys/frogs/main/tadpoles/data/chipped.json",
      "https://raw.githubusercontent.com/tiffanydys/frogs/main/tadpoles/data/cracked.json",
      "https://raw.githubusercontent.com/tiffanydys/frogs/main/tadpoles/data/damaged.json",
      "https://raw.githubusercontent.com/tiffanydys/frogs/main/tadpoles/data/dying.json"
    ];

    constructor(
      string memory _name,
      string memory _symbol,
      address _initIncubatorAddress
    ) ERC721(_name, _symbol) {
      setIncubatorAddress(_initIncubatorAddress);
      setMinterAddress(msg.sender);
    }

    function mint(address[] memory _to, uint256[] memory _mintAmount) public onlyOwner() {
      require(!paused, "Minting is paused.");
      require(_tokenIdCounter.current() + 1 <= maxSupply, "Max supply reached!");

      for (uint256 i = 0; i < _to.length; i++) {
        for (uint256 x = 0; x < _mintAmount[i]; x++) {
          _tokenIdCounter.increment();
          uint256 tokenId = _tokenIdCounter.current();
          _safeMint(_to[i], tokenId);
          _setTokenURI(tokenId, tadpoleUri[0]);
        }
      }
    }

    function tadpoleStage(uint256 _tokenId) public view returns (uint256 tadpoleUriIndex){
      string memory _uri = tokenURI(_tokenId);

      for (uint256 i = 0; i <= 4; i++) {
        if (keccak256(abi.encodePacked(_uri)) == keccak256(abi.encodePacked(tadpoleUri[i]))) {
          return i;
        }
      }
    }

    function breakTadpole(uint256 _tokenId) private {
      if(tadpoleStage(_tokenId) == 4) {return;}

      uint256 newVal = tadpoleStage(_tokenId) + 1;
      string memory newUri = tadpoleUri[newVal];

      _setTokenURI(_tokenId, newUri);
    }

    function _beforeTokenTransfer(
      address from,
      address to,
      uint256 tokenId
    ) internal override {
      // break tadpole if it wasn't transfered from/to minter/incubator addresses
      if ((from != incubatorAddress && to !=incubatorAddress) && (from != minterAddress && to != minterAddress)) {
        breakTadpole(tokenId);
      }
    }

    function _incubatorAddress() internal view virtual returns (address) {
      return incubatorAddress;
    }

    function _minterAddress() internal view virtual returns (address) {
      return minterAddress;
    }

    function setIncubatorAddress(address _newIncubatorAddress) public onlyOwner() {
        incubatorAddress = _newIncubatorAddress;
    }

    function setMinterAddress(address _newMinterAddress) public onlyOwner() {
        minterAddress = _newMinterAddress;
    }

    function pause(bool _state) public onlyOwner {
      paused = _state;
    }

}