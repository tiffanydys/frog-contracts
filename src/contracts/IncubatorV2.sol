// SPDX-License-Identifier: MIT LICENSE
// Contract: Project Dignity - Tadpole Incubator V2
// Token ID: "ProjectDignityTadpoleIncubatorV2"
// Token Symbol: "PD-TI"
// Author: tiffanydys
// Coder: tiffanydys
// Artists: paluras & vadimas (VP)
// Initiator: Donatas (Dee)
// ---- CONTRACT BEGINS HERE ----
pragma solidity ^0.8.0;

import "./Frogs.sol";
import "./Tadpoles.sol";
import "./RewardToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

contract TadpoleIncubatorV2 is IERC721Receiver, Ownable {

    uint256 public totalStaked;
    uint256 public totalTadpoles;
    uint256[] public rewardsMultiplier = [100 ether, 70 ether, 50 ether, 25 ether, 10 ether];
    uint256[] public rarityMultiplier = [5, 50, 20, 8, 5, 2]; // frogless, common, legendary, epic, rare, uncommon

    // FROG RARITIES --- 1 - common, 2 - legendary, 3 - epic, 4 - rare, 5 - uncommon
    uint256[] public frogRarities = [0,2,5,5,5,5,4,5,4,3,5,5,5,3,4,3,4,3,5,5,4,5,5,5,3,5,4,4,3,3,5,4,4,3,4,3,3,3,3,4,5,5,5,3,4,4,2,5,5,3,5,4,5,5,5,5,3,4,2,5,
    4,2,2,2,5,5,5,4,5,5,5,2,3,4,5,5,5,3,5,3,4,5,1,5,5,4,4,3,2,4,3,5,5,3,3,5,5,4,5,5,5,4,2,5,4,4,5,5,3,4,5,2,3,2,3,4,5,5,4,5,5,3,3,5,2,5,4,5,5,5,5,4,4,4,4,5,5,
    5,3,4,4,5,3,4,2,5,3,5,3,5,4,5,4,5,4,4,5,5,5,1,4,5,2,3,5,4,5,4,3,5,4,5,5,5,5,2,5,3,3,5,5,5,3,5,5,5,3,3,4,3,4,4,2,3,5,2,4,4,3,3,4,4,3,4,2,4,3,5,5,3,2,5,2,3,
    5,5,3,5,5,4,5,5,5,5,3,3,2,3,3,4,3,5,5,5,5,3,5,5,5,4,4,5,5,5,3,4,3,4,5,3,5,5,4,5,5,5,3,3,5,2,5,5,4,4,5,3,4,4,5,5,2,5,5,5,2,3,5,5,3,4,5,5,4,5,4,4,2,2,5,5,5,
    5,3,3,5,5,5,3,4,5,2,4,4,3,5,5,4,4,4,5,5,4,5,4,5,5,4,5,5,3,3,4,5,5,3,5,5,5,5,5,3,5,3,5,4,4,5,5,3,4,5,3,5,4,2,4,3,2,3,5,4,5,4,3,5,3,3,4,5,2,4,5,2,4,3,4,5,2,
    2,5,3,3,4,3,5,4,5,5,3,4,2,3,2,5,5,2,3,4,2,2,3,4,5,4,5,5,2,4,3,4,5,5,3,4,5,5,3,5,5,5,5,2,4,5,2,3,4,5,3,5,2,5,4,4,5,5,2,2,2,3,3,3,5,3,4,2,5,4,2,2,4,2,2,2,2,
    3,2,4,4,3,4,5,4,3,4,5,4,3,5,5,4,3,3,3,4,4,5,5,5,5,3,3,4,5,4,5,3,5,2,4,5,4,3,3,4,5,5,4,4,4,4,5,5,5,4,3,4,3,5,4,4,5,3,5,4,5,5,5,4,3,5,5,5,5,5,2,3,4,2,5,3];

    // Incubate structure - frog and tadpole nfts, timestamp, and owner
    struct Incubate {
        uint24 frogTokenId;
        uint24 tadpoleTokenId;
        uint48 timestamp;
        address owner;
    }

    event Incubated(address owner, uint256 frogTokenId, uint256 tadpoleTokenId, uint256 value);
    event Removed(address owner, uint256 frogTokenId, uint256 tadpoleTokenId, uint256 value);
    event Claimed(address owner, uint256 amount);

    // Declare both ERC721 NFTs and Whitelist Reward Token
    Frogs private frogNft;
    Tadpoles private tadpoleNft;
    PDWhitelistRewardToken private token;

    // Map Incubate event to Vault
    mapping(uint256 => Incubate) public vault;

    constructor(
        Frogs _frogNft,
        Tadpoles _tadpoleNft,
        PDWhitelistRewardToken _token
    ) {
        frogNft = _frogNft;
        tadpoleNft = _tadpoleNft;
        token = _token;
        totalTadpoles = 200;
    }

    function incubate(uint256[] calldata frogTokenIds, uint256[] calldata tadpoleTokenIds) external {
        uint256 frogId;
        uint256 tadpoleId;
        totalStaked += tadpoleTokenIds.length;

        for (uint i = 0; i < tadpoleTokenIds.length; i++) {
            frogId = frogTokenIds[i];
            tadpoleId = tadpoleTokenIds[i];

            require(tadpoleNft.ownerOf(tadpoleId) == msg.sender, "You are not the owner of this tadpole NFT.");
            require(vault[tadpoleId].tadpoleTokenId == 0, "You have already incubated your tadpole.");

            if (frogId != 0) { // if there is a frog
                require(frogNft.ownerOf(frogId) == msg.sender, "You are not the owner of this frog NFT.");
                frogNft.transferFrom(msg.sender, address(this), frogId);
            }
            
            tadpoleNft.transferFrom(msg.sender, address(this), tadpoleId);
            emit Incubated(msg.sender, frogId, tadpoleId, block.timestamp);

            vault[tadpoleId] = Incubate({
                owner: msg.sender,
                frogTokenId: uint24(frogId),
                tadpoleTokenId: uint24(tadpoleId),
                timestamp: uint48(block.timestamp)
            });
        }
    }

    function _unstakeMany(address account, uint256[] calldata frogTokenIds, uint256[] calldata tadpoleTokenIds) internal {
        uint256 frogId;
        uint256 tadpoleId;
        totalStaked -= tadpoleTokenIds.length;

        for (uint i = 0; i < tadpoleTokenIds.length; i++) {
            frogId = frogTokenIds[i];
            tadpoleId = tadpoleTokenIds[i];
            Incubate memory incubated = vault[tadpoleId];
            require(incubated.frogTokenId == frogId, "Unstake not allowed.");
            require(incubated.tadpoleTokenId == tadpoleId, "Unstake not allowed.");
            require(incubated.owner == msg.sender, "You are not the owner of this incubator.");
            
            delete vault[tadpoleId];
            emit Removed(account, frogId, tadpoleId, block.timestamp);

            if (frogId != 0) { // if there is a frog
                frogNft.transferFrom(address(this), account, incubated.frogTokenId);
            }
            tadpoleNft.transferFrom(address(this), account, incubated.tadpoleTokenId);
        }
    }

    function claim(uint256[] calldata frogIds, uint256[] calldata tadpoleIds) external {
        _claim(msg.sender, frogIds, tadpoleIds, false);
    }

    function unstake(uint256[] calldata frogIds, uint256[] calldata tadpoleIds) external {
        _claim(msg.sender, frogIds, tadpoleIds, true);
    }

    function _claim(address account, uint256[] calldata frogIds, uint256[] calldata tadpoleIds, bool _unstake) internal {
        uint256 tadpoleId;
        uint256 frogId;
        uint256 earned = 0;
        uint256 rewardmath = 0;

        for (uint i = 0; i < tadpoleIds.length; i++) {
            tadpoleId = tadpoleIds[i];
            frogId = frogIds[i];
            Incubate memory incubated = vault[tadpoleId];
            require(incubated.frogTokenId == frogId, "Claim not allowed.");
            require(incubated.tadpoleTokenId == tadpoleId, "Claim not allowed.");
            require(incubated.owner == account, "You are not the owner of this incubator.");
            uint256 incubatedAt = incubated.timestamp;
            uint256 multiplier = getTadpoleMultiplier(tadpoleId);
            rewardmath = multiplier * (block.timestamp - incubatedAt) / 86400 ;
            earned = rewardmath / 100;

            // nerf computation 
            if (frogId == 0) {
                earned = earned / 2;
            } else {
                // buff computation
                uint256 frogMultiplier = getFrogMultiplier(frogId);
                earned += earned * frogMultiplier / 10;
            }
            
            vault[tadpoleId] = Incubate({
                frogTokenId: uint24(frogId),
                tadpoleTokenId: uint24(tadpoleId),
                timestamp: uint48(block.timestamp),
                owner: account
            });
        }
        if (earned > 0) {
            token.mint(account, earned);
        }
        if (_unstake) {
            _unstakeMany(account, frogIds, tadpoleIds);
        }
        emit Claimed(account, earned);
    }

    // --- DEFAULT VALUES ---
    // healthy - 1 token per day
    // chipped - 0.7 token per day
    // cracked - 0.5 token per day
    // damaged - 0.25 token per day
    // dying - 0.1 token per day

    function getTadpoleMultiplier(uint256 tokenId) public view returns(uint256 _multiplier) {
        uint256 tadpoleMultiplier;
        uint256 tadpoleStage = tadpoleNft.tadpoleStage(tokenId);

        tadpoleMultiplier = rewardsMultiplier[tadpoleStage];

        return tadpoleMultiplier;
    }

    function getFrogMultiplier(uint256 tokenId) public view returns(uint256 _multiplier) {
        uint256 frogMultiplier;
        frogMultiplier = rarityMultiplier[frogRarities[tokenId]];

        return frogMultiplier;
    }

    function earningInfo(uint256[] calldata vaultIds) external view returns (uint256[1] memory info) {
        uint256 vaultId;
        uint256 earned = 0;
        uint256 rewardmath = 0;

        for (uint i = 0; i < vaultIds.length; i++) {
            vaultId = vaultIds[i];
            Incubate memory incubated = vault[vaultId];
            require(incubated.owner == msg.sender, "You are not the owner of this incubator.");
            uint256 incubatedAt = incubated.timestamp;
            uint256 multiplier = getTadpoleMultiplier(vaultId);
            rewardmath = multiplier * (block.timestamp - incubatedAt) / 86400;
            earned = rewardmath / 100;

            // nerf computation 
            if (incubated.frogTokenId == 0) {
                earned = earned / 2;
            } else {
                // buff computation
                uint256 frogMultiplier = getFrogMultiplier(incubated.frogTokenId);
                earned += earned * frogMultiplier / 10;
            }
        }
        if (earned > 0) {
            return [earned];
        }
    }

    // should never be used inside of transaction because of gas fee
    function balanceOf(address account) public view returns (uint256) {
        uint256 balance = 0;
        uint256 supply = totalTadpoles;
        for(uint i = 1; i <= supply; i++) {
            if (vault[i].owner == account) {
                balance += 1;
            }
        }
        return balance;
    }

    // should never be used inside of transaction because of gas fee
    function tokensOfOwner(address account) public view returns (uint256[] memory ownerTokens) {

        uint256 supply = totalTadpoles;
        uint256[] memory tmp = new uint256[](supply);

        uint256 index = 0;
        for(uint tokenId = 1; tokenId <= supply; tokenId++) {
            if (vault[tokenId].owner == account) {
                tmp[index] = vault[tokenId].tadpoleTokenId;
                index +=1;
            }
        }

        uint256[] memory tokens = new uint256[](index);
        for(uint i = 0; i < index; i++) {
            tokens[i] = tmp[i];
        }

        return tokens;
    }

    function getTadpolesOfOwner(address _owner) 
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = tadpoleNft.balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        uint256 currentSize;

        for(uint256 i=1; i <= totalTadpoles; i++) {
            if (tadpoleNft.ownerOf(i) == _owner){
                tokenIds[currentSize] = i;
                currentSize++;
            } else {
                continue;
            }
        }
        return tokenIds;
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send nfts to Vault directly");
        return IERC721Receiver.onERC721Received.selector;
    }

    // --------------- ONLY OWNER FUNCTIONS ---------------

    function setFrogContract (Frogs _newFrogContract) public onlyOwner() {
        frogNft = _newFrogContract;
    }

    function setTadpoleContract (Tadpoles _newTadpoleContract) public onlyOwner() {
        tadpoleNft = _newTadpoleContract;
    }

    function setTokenContract (PDWhitelistRewardToken _newTokenContract) public onlyOwner() {
        token = _newTokenContract;
    }

    function setTotalTadpoles (uint256 _totalTadpoles) public onlyOwner() {
        totalTadpoles = _totalTadpoles;
    }

    function setRewardsMultiplier(uint256[] memory _newRewardsMultiplier) public onlyOwner() {
        rewardsMultiplier = _newRewardsMultiplier;
    }

    function setRarityMultiplier(uint256[] memory _newRarityMultiplier) public onlyOwner() {
        rarityMultiplier = _newRarityMultiplier;
    }

    function setFrogRarities(uint256[] memory _newFrogRarities) public onlyOwner() {
        frogRarities = _newFrogRarities;
    }
}


