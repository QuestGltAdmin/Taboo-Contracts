// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RoyaltyStorage is Ownable{
    address platformLazyNFT;
    address marketplace;

    struct Royalty {
        address royaltyOwner;
        uint256 royaltyPercentage;
        bool activated;
    }

    mapping(address => mapping(uint256 => Royalty)) public nftRoyalty;

    constructor(address _platformLazyNFT){
        platformLazyNFT = _platformLazyNFT;
    }

    function setRoyaltyData(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _royaltyPercentage,
        address _royaltyOwner
    ) external {
        require(msg.sender == platformLazyNFT || msg.sender == marketplace, "Only run on redeem");

        Royalty storage _royalty;
        if(msg.sender == platformLazyNFT) {
             _royalty = nftRoyalty[platformLazyNFT][_tokenId];
        }
        else{
            _royalty = nftRoyalty[_nftContractAddress][_tokenId];
        }
        
        _royalty.royaltyOwner = _royaltyOwner;
        _royalty.royaltyPercentage = _royaltyPercentage;
        _royalty.activated = false;
    }

    function setMarketplace(address _marketplace) external onlyOwner{
        marketplace = _marketplace;
    }

    function activateRoyalty(address _nftContractAddress, uint _tokenId) external {
        require(msg.sender == platformLazyNFT || msg.sender == marketplace, "Only run on redeem");
        nftRoyalty[_nftContractAddress][_tokenId].activated= true;
    }

    function setRoyaltyPercentage(address _nftContractAddress, uint _tokenId, uint256 _newPercentage) external{
        require(msg.sender == platformLazyNFT || msg.sender == marketplace, "Only run on redeem");
        nftRoyalty[_nftContractAddress][_tokenId].royaltyPercentage= _newPercentage;
    }

    function getRoyaltyPercentage(address _nftContractAddress, uint _tokenId) external view returns (uint){
        return nftRoyalty[_nftContractAddress][_tokenId].royaltyPercentage;
    }

    function getRoyaltyOwner(address _nftContractAddress, uint _tokenId) external view returns (address){
        return nftRoyalty[_nftContractAddress][_tokenId].royaltyOwner;
    }

    function isActivated(address _nftContractAddress, uint _tokenId) external view returns (bool){
        return nftRoyalty[_nftContractAddress][_tokenId].activated;
    }

}