// SPDX-License-Identifier: MIT LICENSE
// Contract: Project Dignity - Whitelist Token
// Token ID: "PDWhitelistRewardToken"
// Token Symbol: "PD-WL"
// Author: tiffanydys
// Coder: tiffanydys
// Artists: paluras & vadimas (VP)
// Initiator: Donatas (Dee)
// ---- CONTRACT BEGINS HERE ----
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract PDWhitelistRewardToken is ERC20, ERC20Burnable, Ownable {

    mapping(address => bool) controllers;
    bool public paused = false;
    bool public isTokenTransferrable = false;

    constructor() ERC20("PDWhitelistRewardToken", "PD-WL") {
        canTransfer(false);
    }

    function mint(address to, uint256 amount) external {
        require(!paused, "Minting is paused.");
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }

    function burnFrom(address account, uint256 amount) public override {
        if (controllers[msg.sender]) {
            _burn(account, amount);
        }
        else {
            super.burnFrom(account, amount);
        }
    }

    function addController(address controller) external onlyOwner() {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner() {
        controllers[controller] = false;
    }

    function pause(bool _state) public onlyOwner() {
        paused = _state;
    }

    function canTransfer(bool _state) public onlyOwner() {
        isTokenTransferrable = _state;
    }

    function _beforeTokenTransfer(address, address, uint256) internal view override {
        // if the token is not from this contract, AND token is non transferrable - token transfer will be blocked
        require(!isTokenTransferrable, "Transferring token is blocked.");
    }
}