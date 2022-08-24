// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IProviderPair{
    function getReserves() external view returns (uint112,uint112,uint32);
    function token0() external view returns(address);
    function token1() external view returns(address);
}

interface IPancakeFactory {
    function getPair(address _token1, address _token2) external returns (address);
}

contract PurchaseTaboo is Ownable, ReentrancyGuard{

    // 0xc8e69e21d081ac01Ba60717A54E9c6Ac4C4a4ABE = Taboo-BNB LP
    // 0xf855e52ecc8b3b795ac289f85f6fd7a99883492b = BNB-USDT LP
    // 0xb27f628c12573594437b180a1ea1542d15e0cb78 = BNB-ETH LP
    // 0xae13d989dac2f0debff460ac112a837c89baa7cd = BNB
    // 0xe7a9b31d284d524e87bf002d85acfcf5d1c9ea67 = taboo
    // 0x7ef95a0fee0dd31b22626fa2e10ee6a223f8a684 = USDT
    // 0x8babbb98678facc7342735486c851abd7a0d17ca = ETH
    // 0xcc42724c6683b7e57334c4e856f4c9965ed682bd = Matic BSC Mainnet
    IPancakeFactory public factory;
    IProviderPair public tabooBnbPair;
    IProviderPair public ethBNBPair;
    IProviderPair public maticBNBPair;
    IProviderPair public usdtBNBPair;
    address BNB;
    address public taboo;
    address payable wallet;

    constructor(
        address _taboo, 
        address _wallet, 
        IProviderPair _tabooBnbPair,
        IProviderPair _ethBNBPair,
        IProviderPair _maticBNBPair,
        IProviderPair _usdtBNBPair,
        IPancakeFactory _factory
    ){
        taboo           =   _taboo;
        wallet          =   payable(_wallet);
        tabooBnbPair    =   _tabooBnbPair;
        ethBNBPair      =   _ethBNBPair;
        maticBNBPair    =   _maticBNBPair;
        usdtBNBPair     =   _usdtBNBPair;
        factory         =   _factory;
    }

    function getTabooPriceWithEth(uint256 _amountOfTokens) public view returns (uint256){
        uint256 totalInBNB= tokenToBNB(_amountOfTokens);
        uint256 totalPayable= convertToEth(totalInBNB);
        return totalPayable;
    }

    function getTabooPriceWithMatic(uint256 _amountOfTokens) public view returns (uint256){
        uint256 totalInBNB= tokenToBNB(_amountOfTokens);
        uint256 totalPayable= convertToMatic(totalInBNB);
        return totalPayable;
    }

    function getTabooPriceWithUSDT(uint256 _amountOfTokens) public view returns (uint256){
        uint256 totalInBNB= tokenToBNB(_amountOfTokens);
        uint256 totalPayable= convertToUSDT(totalInBNB);
        return totalPayable;
    }

    function convertToEth(uint256 _amount) public view returns (uint256){
        uint112 reserve0;
        uint112 reserve1;
        uint256 exchange;

        (reserve0, reserve1,) = ethBNBPair.getReserves();
        uint256 reserve0_= uint256(reserve0);
        uint256 reserve1_= uint256(reserve1);
        address token0= tabooBnbPair.token0();

        if(token0 != address(BNB)){
            exchange = (reserve0_*(10**18))/reserve1_;    
        }else{
            exchange = (reserve1_*(10**18))/reserve0_;
        }

        uint total = (_amount * exchange)/1e18;
        return total;
    }

    function convertToMatic(uint256 _amount) public view returns (uint256){
        uint112 reserve0;
        uint112 reserve1;
        uint256 exchange;

        (reserve0, reserve1,) = maticBNBPair.getReserves();
        uint256 reserve0_= uint256(reserve0);
        uint256 reserve1_= uint256(reserve1);

        address token0= maticBNBPair.token0();

        if(token0 != address(BNB)){
            exchange = (reserve0_*(10**18))/reserve1_;    
        }else{
            exchange = (reserve1_*(10**18))/reserve0_;
        }

        uint total = (_amount * exchange)/1e18;

        return total;
    }

    function convertToUSDT(uint256 _amount) public view returns (uint256){
        uint112 reserve0;
        uint112 reserve1;
        uint256 exchange;

        (reserve0, reserve1,) = usdtBNBPair.getReserves();
        uint256 reserve0_= uint256(reserve0);
        uint256 reserve1_= uint256(reserve1);
        address token0= IProviderPair(usdtBNBPair).token0();

        if(token0 != address(BNB)){
            exchange = (reserve0_*(10**6))/reserve1_;    
        }else{
            exchange = (reserve1_*(10**6))/reserve0_;
        } 
        uint total = (_amount * exchange)/1e18;

        return total;
    }

    function getTabooPriceWithBNB() public  view returns(uint256){
        require(address(tabooBnbPair) != address(0), "Pair Addr not set");
        uint112 reserve0;
        uint112 reserve1;
        uint256 exchange;

        (reserve0, reserve1,) = tabooBnbPair.getReserves();
        uint256 reserve0_= uint256(reserve0);
        uint256 reserve1_= uint256(reserve1);

        address token0= tabooBnbPair.token0();

        if(token0 == address(taboo)){
            exchange = (reserve0_*(10**18))/reserve1_;    
        }else{
            exchange = (reserve1_*(10**18))/reserve0_;
        }
        return (exchange);
    }

    function getTabooPriceWithX(address _pairAddress) public  view returns(uint256){
        require(address(_pairAddress) != address(0), "INVALID_ADDRESS");
        uint112 reserve0;
        uint112 reserve1;
        uint256 exchange;

        (reserve0, reserve1,) = IProviderPair(_pairAddress).getReserves();
        uint256 reserve0_= uint256(reserve0);
        uint256 reserve1_= uint256(reserve1);

        address token0= IProviderPair(_pairAddress).token0();
        address token1= IProviderPair(_pairAddress).token1();
        uint8 decimal0 = ERC20(token0).decimals();
        uint8 decimal1= ERC20(token1).decimals();
        uint8 diff= (decimal1 > decimal0) ? (decimal1 - decimal0) : (decimal0 - decimal1);

        // equalize the decimals
        if(decimal0 > decimal1) {
            reserve1_= reserve1_ * 10** uint(diff);
        }
        else {
            reserve0_ = reserve0_ * 10** uint(diff);
        }

        // Find price in terms of other token
        if(token0 == taboo){
            exchange= (reserve0_ * 1e9)/ reserve1_;
        }else{
            exchange= (reserve1_ * 1e9)/ reserve0_;
        }

        return exchange;
    }

    // token per BNB
    function tokenToBNB(uint256 _amountOfTokens) public view returns(uint256){
        uint256 amountInOneBNB = getTabooPriceWithBNB();
        uint256 tokenPrice= (_amountOfTokens* 1e18 )/ amountInOneBNB; 
        return tokenPrice;
    }

    function tokenToX(address _pairAddress, uint256 _amountOfTokens) public view returns (uint256) {
        require(address(_pairAddress) != address(0), "INVALID_ADDRESS");
        uint256 amountInOneX = getTabooPriceWithX(_pairAddress); 
        
        // Decimal adjustment
        address token0= IProviderPair(_pairAddress).token0();
        address token1= IProviderPair(_pairAddress).token1();
        uint8 decimal;
        if(token0 == taboo){
            decimal= ERC20(token1).decimals();
        }else{
            decimal= ERC20(token0).decimals();
        }
        // final payable price
        uint256 tokenPrice= (_amountOfTokens* 10**decimal ) / amountInOneX; 
        return tokenPrice;
    }

    function buyWithBNB(uint256 _amount) public nonReentrant payable {
        require(IERC20(taboo).balanceOf(address(this)) > _amount, "Taboo Not Available");
        uint256 totalPayable= tokenToBNB(_amount);
        require(msg.value == totalPayable, "Not enough to purchase");

        (bool success, )= wallet.call{value: msg.value}("");
        require(success);
        ERC20(taboo).transfer(msg.sender, _amount);
    }

    function buyWithTokenX(uint256 _amount, address _token) public nonReentrant {
        require(IERC20(taboo).balanceOf(address(this)) > _amount, "Taboo Not Available");
        address pairAddress= factory.getPair(_token, taboo);
        require(pairAddress!= address(0), "No pair exists");

        uint256 totalPayable= tokenToX(pairAddress, _amount);

        require(IERC20(_token).balanceOf(msg.sender) == totalPayable, "Not enough to purchase");
        IERC20(_token).transferFrom(msg.sender, wallet, totalPayable);
        ERC20(taboo).transfer(msg.sender, _amount);
    }
    
    function buyWithMatic(uint256 _amount) public nonReentrant {
        require(IERC20(taboo).balanceOf(address(this)) > _amount, "Taboo Not Available");
        address token0= IProviderPair(maticBNBPair).token0();
        address token1= IProviderPair(maticBNBPair).token1();
        require(token0== taboo || token1== taboo, "Wrong pair address");
        uint256 totalPayable= getTabooPriceWithMatic(_amount);
        address payToken= (token0==taboo)? token1 : token0;
        require(IERC20(payToken).balanceOf(msg.sender) == totalPayable, "Not enough to purchase");

        IERC20(payToken).transferFrom(msg.sender, wallet, totalPayable);
        ERC20(taboo).transfer(msg.sender, _amount);
    }

    function buyWithUSDT(uint256 _amount) public nonReentrant {
        require(IERC20(taboo).balanceOf(address(this)) > _amount, "Taboo Not Available");
        address token0= IProviderPair(usdtBNBPair).token0();
        address token1= IProviderPair(usdtBNBPair).token1();
        require(token0== taboo || token1== taboo, "Wrong pair address");
        uint256 totalPayable= getTabooPriceWithUSDT(_amount);
        address payToken= (token0==taboo)? token1 : token0;
        require(IERC20(payToken).balanceOf(msg.sender) == totalPayable, "Not enough to purchase");

        IERC20(payToken).transferFrom(msg.sender, wallet, totalPayable);
        ERC20(taboo).transfer(msg.sender, _amount);
    }

    function buyWithEth(uint256 _amount) public nonReentrant {
        require(IERC20(taboo).balanceOf(address(this)) > _amount, "Taboo Not Available");
        address token0= IProviderPair(ethBNBPair).token0();
        address token1= IProviderPair(ethBNBPair).token1();
        require(token0== taboo || token1== taboo, "Wrong pair address");
        uint256 totalPayable= getTabooPriceWithEth(_amount);
        address payToken= (token0==taboo)? token1 : token0;
        require(IERC20(payToken).balanceOf(msg.sender) == totalPayable, "Not enough to purchase");
        IERC20(payToken).transferFrom(msg.sender, wallet, totalPayable);
        ERC20(taboo).transfer(msg.sender, _amount);
    }

    function emergencyShutDown() public onlyOwner {
        IERC20(taboo).transfer(wallet, IERC20(taboo).balanceOf(address(this)));
    }

    function setTaboo(address _taboo) public onlyOwner{
        taboo = _taboo;
    }

    function setTabooBNBPair(IProviderPair _tabooBnbPair) public onlyOwner{
        tabooBnbPair = _tabooBnbPair;
    }

    function setBNBUSDTPair(IProviderPair _usdtBNBPair) public onlyOwner{
        usdtBNBPair = _usdtBNBPair;
    }
    function setMaticBNBPair(IProviderPair _maticBnbPair) public onlyOwner{
        maticBNBPair = _maticBnbPair;
    }
    function setEthBNBPair(IProviderPair _ethBnbPair) public onlyOwner{
        ethBNBPair = _ethBnbPair;
    }
        function getBalance(address _token, address _user) public view returns(uint){
        return IERC20(_token).balanceOf(_user);
    }
}