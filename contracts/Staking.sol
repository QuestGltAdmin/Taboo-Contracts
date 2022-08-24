// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TabooStaking is ReentrancyGuard, ERC20("XTaboo Token", "xTABOO"), Ownable {
    IERC20 public taboo;
    uint256 APY;
    uint256 zerosPadding= 15;
    uint256 immutable oneYear= 365 * 86400;
    struct Stake {
        uint256 deposit;
        uint256 timestamp;
        uint256 minLockPeriod;
        uint256 earned;
        bool active;
    }

    mapping(address => Stake[]) public stakeData;

    constructor(IERC20 _taboo)  {
        taboo = _taboo;
    }

    // length of TimeLock[]
    function checkLength(address _account) internal view returns (uint256) {
        return stakeData[_account].length;
    }

    function stake(uint256 _amount, uint256 _lockingPeriod) nonReentrant public {
        require(_lockingPeriod >= 60, "Less than min lock duration");
        require(_amount >= 0, "Less than min stake amt");

        // Get the tokens in the contract
        IERC20(taboo).transferFrom(msg.sender, address(this), _amount);
        _mint(msg.sender, _amount); // minting ratio is 1:1

        // Create new entry of deposit
        Stake memory _stake;
        _stake.deposit= _amount;
        _stake.timestamp= block.timestamp;
        _stake.minLockPeriod= _lockingPeriod;
        stakeData[msg.sender].push(_stake);
    }

    function getAPY() public view returns(uint256){
        return APY;
    }

    function setAPY(uint256 _APY) public onlyOwner {
        APY= _APY * 1e15;
    }

    function withdraw(uint256 _index) public {
        Stake memory s= stakeData[msg.sender][_index];
        require( (s.timestamp + s.minLockPeriod) < block.timestamp, "Lock not expired");
        uint256 tokensEarned= getUserYield(msg.sender, _index);
        uint256 totalWithdrawable= s.deposit + tokensEarned;
        IERC20(taboo).transfer(msg.sender, totalWithdrawable);
    }

    function getUserYield(address _user, uint256 _index) public view returns(uint256) {
        Stake memory s= stakeData[_user][_index];
        uint256 APYinSeconds= APY/oneYear;
        uint256 durationStaked= block.timestamp - s.timestamp;
        uint tokensEarned= (APYinSeconds * s.deposit * durationStaked)/10000;
        return tokensEarned/ (10 ** zerosPadding);
    }
}
