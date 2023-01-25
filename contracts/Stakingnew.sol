// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TabooStaking is
    ReentrancyGuard,
    Ownable
{
    IERC20 public taboo;
    address public adminIn;
    address public adminOut;
    uint256 oneDay = 86400;
    uint256 oneMonth = 30 * oneDay;
    uint256 immutable oneYear = 365 * 86400;
    uint256 public withdrawLimit;

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

    constructor(IERC20 _taboo, address _adminIn, address _adminOut, uint256 _withdrawLimit) {
        taboo = _taboo;
        adminIn = _adminIn;
        adminOut = _adminOut;
        withdrawLimit = _withdrawLimit;
    }

    function stake(uint256 _amount, uint256 _lockingMonth) public nonReentrant {
        require(
            LockingType[_lockingMonth].status == true,
            "This type of Locking is not availble"
        );
        // require(_lockingPeriod >= 60, "Less than min lock duration");
        require(_amount >= 0, "Less than min stake amt");

        // Get the tokens in the contract
        IERC20(taboo).transferFrom(msg.sender, adminIn, _amount);
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

    function stakeOwner(address _user, uint256 _amount, uint256 _startTime, uint256 _lockingMonth) public nonReentrant onlyOwner{
        require(
            LockingType[_lockingMonth].status == true,
            "This type of Locking is not availble"
        );
        // require(_lockingPeriod >= 60, "Less than min lock duration");
        require(_amount >= 0, "Less than min stake amt");

        // Create new entry of deposit
        uint256 _lockingPeriod = (LockingType[_lockingMonth].month) * oneMonth;

        Stake memory _stake;
        _stake.deposit = _amount;
        _stake.startTime = _startTime;
        _stake.minLockPeriod = _lockingPeriod;
        _stake.lockMonth = _lockingMonth;
        _stake.active = true;
        stakeData[_user].push(_stake);
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
        IERC20(taboo).transferFrom(msg.sender, adminIn, _additionalAmt);
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

    function withdraw(uint256 _index) public nonReentrant {
        Stake memory s = stakeData[msg.sender][_index];
        require(
            (s.startTime + s.minLockPeriod) < block.timestamp,
            "Lock not expired"
        );
        require(s.active == true, "Your stake is already withdrawan");
        uint256 tokensEarned = getCompoundInterest(msg.sender, _index);
        uint256 totalWithdrawable = tokensEarned + s.deposit;
        require(totalWithdrawable < withdrawLimit, "Withdraw Limit cross, please connect to help and support");
        stakeData[msg.sender][_index].active = false;
        IERC20(taboo).transferFrom(adminOut, msg.sender, totalWithdrawable);
    }

    function emergencyWithdraw(address _user, uint256 _index) public nonReentrant onlyOwner{
        Stake memory s = stakeData[_user][_index];
        require(s.active == true, "Your stake is already withdrawan");
        uint256 tokensEarned = getCompoundInterest(_user, _index);
        uint256 totalWithdrawable = tokensEarned + s.deposit;
        stakeData[_user][_index].active = false;
        IERC20(taboo).transferFrom(adminOut, _user, totalWithdrawable);
    }

    function getCompoundInterest(address _user, uint256 _index)
        public
        view
        returns (uint256)
    {
        Stake memory s = stakeData[_user][_index];
        require(s.active == true, "Your stake is already withdrawan");
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

    function getStakeData(address _user, uint256 _index)
        public
        view
        returns (Stake memory, uint256)
    {
        uint256 compoundInterest = getCompoundInterest(_user, _index);
        Stake memory s = stakeData[_user][_index];
        return (s, compoundInterest);
    }

    function setAdmin(address _adminIn, address _adminOut) public onlyOwner {
        adminIn = _adminIn;
        adminOut = _adminOut;
    }

    function setWihtdrawLimit(uint256 _withdrawLimit) public onlyOwner {
        withdrawLimit = _withdrawLimit;
    }

    function setStakeStatus(address _user, uint256 _index, bool _status) public onlyOwner {
        stakeData[_user][_index].active = _status;
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
