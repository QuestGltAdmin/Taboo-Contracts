// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TabooStaking is
    ReentrancyGuard,
    ERC20("XTaboo Token", "xTABOO"),
    Ownable
{
    IERC20 public taboo;
    address public admin;
    uint256 oneDay = 10;
    uint256 oneMonth = 30 * oneDay;
    uint256 immutable oneYear = 365 * 10;
    
    struct Stake {
        uint256 deposit;
        uint256 startTime;
        uint256 minLockPeriod;
        uint256 lockMonth;
        bool active;
    }

    struct lockingType {
        uint256 month;
        uint256 interestRate;
        bool status;
    }

    mapping(address => Stake[]) public stakeData;
    mapping(uint256 => lockingType) public LockingType;

    constructor(IERC20 _taboo) {
        taboo = _taboo;
    }

    function stake(uint256 _amount, uint256 _lockingMonth) public nonReentrant {
        require(
            LockingType[_lockingMonth].status == true,
            "This type of Locking is not availble"
        );
        // require(_lockingPeriod >= 60, "Less than min lock duration");
        require(_amount >= 0, "Less than min stake amt");

        // Get the tokens in the contract
        IERC20(taboo).transferFrom(msg.sender, admin, _amount);
        _mint(msg.sender, _amount); // minting ratio is 1:1
        // Create new entry of deposit
        uint256 _lockingPeriod = (LockingType[_lockingMonth].month) * oneMonth;

        Stake memory _stake;
        _stake.deposit = _amount;
        _stake.startTime = block.timestamp;
        _stake.minLockPeriod = _lockingPeriod;
        _stake.lockMonth = _lockingMonth;
        _stake.active = true;
        stakeData[msg.sender].push(_stake);
    }

    function reStake(uint256 _index, uint256 _additionalAmt, uint256 _lockingMonth) public nonReentrant {
        Stake memory s = stakeData[msg.sender][_index];
        require(
            (s.startTime + s.minLockPeriod) < block.timestamp,
            "Lock not expired"
        );
        require(s.active == true, "Your stake is already withdrawan");
        uint256 tokensEarned = getCompoundInterest(msg.sender, _index);
        uint256 totalWithdrawable = tokensEarned + s.deposit;
        stakeData[msg.sender][_index].active = false;
        require(
            LockingType[_lockingMonth].status == true,
            "This type of Locking is not availble"
        );
        // Get the tokens in the contract
        IERC20(taboo).transferFrom(msg.sender, admin, _additionalAmt);
        uint256 extraXtaboo = tokensEarned + _additionalAmt;
        _mint(msg.sender, extraXtaboo); // minting ratio is 1:1

        // Create new entry of deposit
        uint256 _lockingPeriod = (LockingType[_lockingMonth].month) * oneMonth;
        uint256 _amount = totalWithdrawable + _additionalAmt;

        Stake memory _stake;
        _stake.deposit = _amount;
        _stake.startTime = block.timestamp;
        _stake.minLockPeriod = _lockingPeriod;
        _stake.lockMonth = _lockingMonth;
        _stake.active = true;
        stakeData[msg.sender].push(_stake);
    }

    function withdraw(uint256 _index) public {
        Stake memory s = stakeData[msg.sender][_index];
        require(
            (s.startTime + s.minLockPeriod) < block.timestamp,
            "Lock not expired"
        );
        require(s.active == true, "Your stake is already withdrawan");
        uint256 tokensEarned = getCompoundInterest(msg.sender, _index);
        uint256 totalWithdrawable = tokensEarned + s.deposit;
        stakeData[msg.sender][_index].active = false;
        _burn(msg.sender, s.deposit);
        // IERC20(taboo).transfer(msg.sender, totalWithdrawable);
        IERC20(taboo).transferFrom(admin, msg.sender, totalWithdrawable);
    }

    function getCompoundInterest(address _user, uint256 _index)
        public
        view
        returns (uint256)
    {
        Stake memory s = stakeData[_user][_index];
        uint256 _deposit = s.deposit; 
        uint256 _lockMonth = s.lockMonth;
        // duration in sec
        uint256 durationStaked = block.timestamp - s.startTime;
        //duration in day
        durationStaked = durationStaked / oneDay;

        uint256 _interestRate = LockingType[_lockMonth].interestRate;

        uint256 withdrawAmount = _deposit;

        for (uint256 i = 1; i <= durationStaked; i++) {
            //oneYear
            uint256 _interestForYear = (withdrawAmount * _interestRate) / 100;
            //oneDay
            uint256 _interestForDay = _interestForYear / 365;
            withdrawAmount = withdrawAmount + _interestForDay;
        }
        uint256 compoundInterest = withdrawAmount - _deposit;
        return compoundInterest;
    }

    function setAdmin(address _admin) public onlyOwner {
        admin = _admin;
    }

    function addLockType(
        uint256 _month,
        uint256 _interestRate,
        bool _status
    ) public onlyOwner {
        LockingType[_month].month = _month;
        LockingType[_month].interestRate = _interestRate;
        LockingType[_month].status = _status;
    }
}
