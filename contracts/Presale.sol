/**
 *Submitted for verification at BscScan.com on 2022-08-06
 */

pragma solidity ^0.8.4;

// SPDX-License-Identifier: Unlicensed

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IProviderPair {
    function getReserves()
        external
        view
        returns (
            uint112,
            uint112,
            uint32
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

contract KarbunPresale is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IERC20 public _token;
    IERC20 public _BUSD;
    IERC20 public _ETH;
    IERC20 public _MATIC;
    IERC20 public _BTC;
    IERC20 public _ADA;
    IERC20 public _DOGE;
    IERC20 public _CHAINLINK;
    IERC20 public _USDC;
    IERC20 public _USDT;
    IERC20 public _UNI;

    IProviderPair public TokenBnb;
    IProviderPair public BusdBnb;
    IProviderPair public BusdEth;
    IProviderPair public BusdMatic;
    IProviderPair public BusdBtc;
    IProviderPair public BusdAda;
    IProviderPair public BusdDoge;
    IProviderPair public BusdChain;
    IProviderPair public BusdUni;
    uint256 private _tokenDecimals;

    address payable public _wallet;
    uint256 public _bonusamt;
    uint256 public _bonuspercent;

    event TokensPurchased(
        address purchaser,
        address beneficiary,
        uint256 value,
        uint256 amount
    );

    constructor(
        address payable wallet,
        IERC20 token,
        uint256 tokenDecimals
    ) {
        require(wallet != address(0), "Pre-Sale: wallet is the zero address");
        require(
            address(token) != address(0),
            "Pre-Sale: token is the zero address"
        );
        _wallet = wallet;
        _token = token;
        _tokenDecimals = 18 - tokenDecimals;
    }

    receive() external payable {
        // React to receiving ether
    }

    function AddProvider(
        IProviderPair _TokenBnb,
        IProviderPair _BusdBnb,
        IProviderPair _BusdEth,
        IProviderPair _BusdBtc,
        IProviderPair _BusdMatic,
        IProviderPair _BusdAda,
        IProviderPair _BusdDoge,
        IProviderPair _BusdChain,
        IProviderPair _BusdUni
    ) external onlyOwner {
        TokenBnb = _TokenBnb;
        BusdBnb = _BusdBnb;
        BusdEth = _BusdEth;
        BusdBtc = _BusdBtc;
        BusdMatic = _BusdMatic;
        BusdAda = _BusdAda;
        BusdDoge = _BusdDoge;
        BusdChain = _BusdChain;
        BusdUni = _BusdUni;
    }

    //Pre-Sale
    function buyTokensBNB(address _beneficiary)
        public
        payable
        nonReentrant
    {
        uint256 bnbAmount = msg.value;
        _wallet.transfer(bnbAmount);
        uint256 tokens = _getTokenAmount(bnbAmount);
        _token.transferFrom(_wallet, _beneficiary, tokens);
        emit TokensPurchased(_msgSender(), _beneficiary, bnbAmount, tokens);
    }

    function buyTokensBUSD(address _beneficiary, uint256 _BUSDAmount)
        public
        nonReentrant
    {
        _BUSD.transferFrom(msg.sender, _wallet, _BUSDAmount);
        uint256 tokens = _getTokenAmountBUSD(_BUSDAmount);
        _token.transferFrom(_wallet, _beneficiary, tokens);
        emit TokensPurchased(_msgSender(), _beneficiary, _BUSDAmount, tokens);
    }

    function buyTokensUSDC(address _beneficiary, uint256 _USDCAmount)
        public
        nonReentrant
    {
        _USDC.transferFrom(msg.sender, _wallet, _USDCAmount);
        uint256 tokens = _getTokenAmountUSDC(_USDCAmount);
        _token.transferFrom(_wallet, _beneficiary, tokens);
        emit TokensPurchased(_msgSender(), _beneficiary, _USDCAmount, tokens);
    }

    function buyTokensUSDT(address _beneficiary, uint256 _USDTAmount)
        public
        nonReentrant
    {
        _USDT.transferFrom(msg.sender, _wallet, _USDTAmount);
        uint256 tokens = _getTokenAmountUSDT(_USDTAmount);
        _token.transferFrom(_wallet, _beneficiary, tokens);
        emit TokensPurchased(_msgSender(), _beneficiary, _USDTAmount, tokens);
    }

    function buyTokensETH(address _beneficiary, uint256 _ETHAmount)
        public
        nonReentrant
    {
        _ETH.transferFrom(msg.sender, _wallet, _ETHAmount);
        uint256 tokens = _getTokenAmountETH(_ETHAmount);
        _token.transferFrom(_wallet, _beneficiary, tokens);
        emit TokensPurchased(_msgSender(), _beneficiary, _ETHAmount, tokens);
    }

    function buyTokensBTC(address _beneficiary, uint256 _BTCAmount)
        public
        nonReentrant
    {
        _BTC.transferFrom(msg.sender, _wallet, _BTCAmount);
        uint256 tokens = _getTokenAmountBTC(_BTCAmount);
        _token.transferFrom(_wallet, _beneficiary, tokens);
        emit TokensPurchased(_msgSender(), _beneficiary, _BTCAmount, tokens);
    }

    function buyTokensMATIC(address _beneficiary, uint256 _MATICAmount)
        public
        nonReentrant
    {
        _MATIC.transferFrom(msg.sender, _wallet, _MATICAmount);
        uint256 tokens = _getTokenAmountMATIC(_MATICAmount);
        _token.transferFrom(_wallet, _beneficiary, tokens);
        emit TokensPurchased(_msgSender(), _beneficiary, _MATICAmount, tokens);
    }

    function buyTokensADA(address _beneficiary, uint256 _ADAAmount)
        public
        nonReentrant
    {
        _ADA.transferFrom(msg.sender, _wallet, _ADAAmount);
        uint256 tokens = _getTokenAmountADA(_ADAAmount);
        _token.transferFrom(_wallet, _beneficiary, tokens);
        emit TokensPurchased(_msgSender(), _beneficiary, _ADAAmount, tokens);
    }

    function buyTokensDOGE(address _beneficiary, uint256 _DOGEAmount)
        public
        nonReentrant
    {
        _DOGE.transferFrom(msg.sender, _wallet, _DOGEAmount);
        uint256 tokens = _getTokenAmountDOGE(_DOGEAmount);
        _token.transferFrom(_wallet, _beneficiary, tokens);
        emit TokensPurchased(_msgSender(), _beneficiary, _DOGEAmount, tokens);
    }

    function buyTokensCHAIN(address _beneficiary, uint256 _CHAINAmount)
        public
        nonReentrant
    {
        _CHAINLINK.transferFrom(msg.sender, _wallet, _CHAINAmount);
        uint256 tokens = _getTokenAmountCHAIN(_CHAINAmount);
        _token.transferFrom(_wallet, _beneficiary, tokens);
        emit TokensPurchased(_msgSender(), _beneficiary, _CHAINAmount, tokens);
    }

    function buyTokensUNI(address _beneficiary, uint256 _UNIAmount)
        public
        nonReentrant
    {
        _UNI.transferFrom(msg.sender, _wallet, _UNIAmount);
        uint256 tokens = _getTokenAmountUNI(_UNIAmount);
        _token.transferFrom(_wallet, _beneficiary, tokens);
        emit TokensPurchased(_msgSender(), _beneficiary, _UNIAmount, tokens);
    }

    function withdrawBNB() external onlyOwner {
        _wallet.transfer(address(this).balance);
    }

    function setAddress(
        IERC20 token,
        IERC20 busd,
        IERC20 eth,
        IERC20 btc,
        IERC20 matic,
        IERC20 ada,
        IERC20 doge,
        IERC20 chainLink,
        IERC20 uni,
        IERC20 usdc,
        IERC20 usdt
    ) external onlyOwner {
        _BUSD = busd;
        _ETH = eth;
        _BTC = btc;
        _MATIC = matic;
        _ADA = ada;
        _DOGE = doge;
        _CHAINLINK = chainLink;
        _UNI = uni;
        _USDC = usdc;
        _USDT = usdt;
        _token = token;
    }

    function setToken(IERC20 token) external onlyOwner {
        _token = token;
    }

    function setWalletReceiver(address payable _newWallet) external onlyOwner {
        _wallet = _newWallet;
    }

    function takeTokens(IERC20 _TokenAddress) public onlyOwner {
        IERC20 tokenBEP = _TokenAddress;
        uint256 tokenAmt = tokenBEP.balanceOf(address(this));
        require(tokenAmt > 0, "BEP-20 balance is 0");
        tokenBEP.transfer(_wallet, tokenAmt);
    }

    function _getTokenAmount(uint256 _bnbAmount)
        internal
        view
        returns (uint256)
    {
        return _bnbAmount.mul(bnbRate()).div(10**9);
    }

    function _getTokenAmountBUSD(uint256 _busdAmount)
        internal
        view
        returns (uint256)
    {
        return _busdAmount.mul(getTabooPrice()).div(10**9);
    }

    function _getTokenAmountETH(uint256 _ethAmount)
        internal
        view
        returns (uint256)
    {
        return _ethAmount.mul(ethRate()).div(10**9);
    }

    function _getTokenAmountBTC(uint256 _btcAmount)
        internal
        view
        returns (uint256)
    {
        return _btcAmount.mul(btcRate()).div(10**9);
    }

    function _getTokenAmountMATIC(uint256 _maticAmount)
        internal
        view
        returns (uint256)
    {
        return _maticAmount.mul(maticRate()).div(10**9);
    }

    function _getTokenAmountDOGE(uint256 _dogeAmount)
        internal
        view
        returns (uint256)
    {
        return _dogeAmount.mul(dogeRate()).div(10**9);
    }

    function _getTokenAmountADA(uint256 _adaAmount)
        internal
        view
        returns (uint256)
    {
        return _adaAmount.mul(adaRate()).div(10**9);
    }

    function _getTokenAmountCHAIN(uint256 _chainAmount)
        internal
        view
        returns (uint256)
    {
        return _chainAmount.mul(chainRate()).div(10**9);
    }

        function _getTokenAmountUNI(uint256 _uniAmount)
        internal
        view
        returns (uint256)
    {
        return _uniAmount.mul(uniRate()).div(10**9);
    }

    function _getTokenAmountUSDC(uint256 _usdcAmount)
        internal
        view
        returns (uint256)
    {
        return _usdcAmount.mul(getTabooPrice()).div(10**9);
    }

    function _getTokenAmountUSDT(uint256 _usdtAmount)
        internal
        view
        returns (uint256)
    {
        return _usdtAmount.mul(getTabooPrice()).div(10**9);
    }

    function getPriceData(IProviderPair _pairAddress)
        public
        view
        returns (uint256)
    {
        uint112 reserve0;
        uint112 reserve1;
        uint32 timestamp;
        uint256 exchangeRate;
        (reserve0, reserve1, timestamp) = IProviderPair(_pairAddress)
            .getReserves();
        address token0 = IProviderPair(_pairAddress).token0();
        if (token0 == address(_BUSD)) {
            exchangeRate = (uint256((reserve0 * (10**9)) / reserve1));
        } else {
            exchangeRate = (uint256((reserve1 * (10**9)) / reserve0));
        }
        return (exchangeRate);
    }

    function getTabooPrice()
        public
        view
        returns (uint256)
    {
        uint112 reserve0;
        uint112 reserve1;
        uint32 timestamp;
        uint256 exchangeRate;
        (reserve0, reserve1, timestamp) = IProviderPair(TokenBnb)
            .getReserves();
        address token0 = IProviderPair(TokenBnb).token0();
        if (token0 == address(_token)) {
            exchangeRate = (uint256((reserve0 * (10**18)) / reserve1));
        } else {
            exchangeRate = (uint256((reserve1 * (10**18)) / reserve0));
        }
        uint256 bnbPrice = getPriceData(BusdBnb); 
        exchangeRate = (exchangeRate*1e9)/bnbPrice;
        return (exchangeRate);
    }

    function bnbRate() public view returns (uint256) {
        uint256 bnbrate = (getPriceData(BusdBnb).mul(getTabooPrice())).div(10**9);
        return (bnbrate);
    }

    function ethRate() public view returns (uint256) {
        uint256 ethrate = (getPriceData(BusdEth).mul(getTabooPrice())).div(10**9);
        return (ethrate);
    }

    function btcRate() public view returns (uint256) {
        uint256 btcrate = (getPriceData(BusdBtc).mul(getTabooPrice())).div(10**9);
        return (btcrate);
    }

    function maticRate() public view returns (uint256) {
        uint256 maticrate = (getPriceData(BusdMatic).mul(getTabooPrice())).div(10**9);
        return (maticrate);
    }

    function adaRate() public view returns (uint256) {
        uint256 adarate = (getPriceData(BusdAda).mul(getTabooPrice())).div(10**9);
        return (adarate);
    }

    function dogeRate() public view returns (uint256) {
        uint256 dogerate = (getPriceData(BusdDoge).mul(getTabooPrice())).div(10**9);
        return (dogerate);
    }

    function chainRate() public view returns (uint256) {
        uint256 chainlinkrate = (getPriceData(BusdChain).mul(getTabooPrice())).div(10**9);
        return (chainlinkrate);
    }

    function uniRate() public view returns (uint256) {
        uint256 unirate = (getPriceData(BusdUni).mul(getTabooPrice())).div(10**9);
        return (unirate);
    }
}
