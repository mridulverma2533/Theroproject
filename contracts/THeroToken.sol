// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./IBEP20.sol";
import "./Auth.sol";
import "./IContract.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./Pausable.sol";

contract THeroToken is IBEP20, Auth, Pausable {
   using SafeMath for uint256;

    address ZERO = 0x0000000000000000000000000000000000000000;

    // pancakeswap testnet router for bsc testnet
    address ROUTER = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    string constant _name = "THero_v4";
    string constant _symbol = "THR_v4";
    uint8 constant _decimals = 18;

    // 100 million
    uint256 _totalSupply = 10**8 * (10 ** _decimals);
    uint256 public _maxTxAmount = (_totalSupply * 1) / 1000;
    uint256 public _maxWalletSize = (_totalSupply * 1) / 1000;  

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    // mapping (address => bool) public isBoughtAnyNFT;
    mapping(address => bool) public isController;

    // @Dev Sell tax..
    uint16 private _sellTeamFee = 2000;
    uint16 private _sellLiquidityFee = 3000;
    
    // @Dev Buy tax..
    uint16 private _buyTeamFee = 1000;
    uint16 private _buyLiquidityFee = 2000;

    uint256 public _teamFeeTotal;
    uint256 public _liquidityFeeTotal;
    uint256 public _marketingFeeTotal;

    uint256 private teamFeeTotal;
    uint256 private liquidityFeeTotal;
    uint256 private marketingFeeTotal;

    uint256 private first_5_Block_Buy_Sell_Fee = 28;

    address private marketingAddress;
    address private teamAddress;

    uint256 public releaseDuration = 1 days;
    uint256 public releaseTimeStamp = 0;

    uint256 public liquidityAddedAt = 0;

    event SwapedTokenForEth(uint256 TokenAmount);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 bnbReceived, uint256 tokensIntoLiquidity);

    IUniswapV2Router02 public router;
    address public pair;

    bool public swapEnabled = true;

    constructor(address _teamAddress, address _marketingAddress) Auth(msg.sender) {
        router = IUniswapV2Router02(ROUTER);
        pair = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        liquidityAddedAt = block.timestamp;
        _allowances[address(this)][address(router)] = type(uint256).max;

        teamAddress = _teamAddress;
        marketingAddress = _marketingAddress;
        address _owner = owner;
        isFeeExempt[_owner] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[address(this)] = true;
        _balances[_owner] = _totalSupply * 15 / 100;
        _balances[address(this)] = _totalSupply * 85 / 100;
        isTxLimitExempt[ROUTER] = true;
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function setPair(address acc) public{
        liquidityAddedAt = block.timestamp;
        pair = acc;
    }

    function sendToken2Account(address account, uint256 amount) external returns(bool) {
        require(isController[msg.sender], "Only Controller can call this function!");
        this.transfer(account, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override whenNotPaused returns (bool)  {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override whenNotPaused returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        checkTxLimit(sender, amount);
        
        if (recipient != pair) {

            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= _maxWalletSize 
                    , "Transfer amount exceeds the bag size.");
        }
        uint256 amountReceived = amount;

        if (!isTxLimitExempt[recipient] && !isTxLimitExempt[sender]) {
            if (recipient == pair || sender == pair) {
                require (swapEnabled, "THeroToken: Trading is disabled now.");
                require (amount <= getLiquiditySupply(), "Swap Amount Exceeds Liquidity Threshold.");

                if (block.timestamp > liquidityAddedAt.add(30)) {
                    if (sender == pair && shouldTakeFee(recipient)) {
                        amountReceived = takeFeeOnBuy(sender, amount);
                    }
                } else {
                    amountReceived = shouldTakeFee(sender) ? collectFee(sender, amount) : amount;
                }
            }
        }
        

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }
    
    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }
    
    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFeeOnBuy(address account, uint256 amount) internal returns (uint256) {

        uint256 transferAmount = amount;
        
        //@dev Take team fee
        if(_buyTeamFee != 0) {
            uint256 teamFee = amount.mul(_buyTeamFee).div(100000);
            transferAmount = transferAmount.sub(teamFee);
            _balances[address(this)] = _balances[address(this)].add(teamFee);
            _teamFeeTotal = _teamFeeTotal.add(teamFee);
            teamFeeTotal = teamFeeTotal.add(teamFee);
            emit Transfer(account, address(this), teamFee);
        }
        
        //@dev Take liquidity fee
        if(_buyLiquidityFee != 0) {
            uint256 liquidityFee = amount.mul(_buyLiquidityFee).div(100000);
            transferAmount = transferAmount.sub(liquidityFee);
            _balances[address(this)] = _balances[address(this)].add(liquidityFee);
            _liquidityFeeTotal = _liquidityFeeTotal.add(liquidityFee);
            liquidityFeeTotal = liquidityFeeTotal.add(liquidityFee);
            emit Transfer(account, address(this), liquidityFee);
        }
        
        return transferAmount;
    }

    function collectFeeOnSell(address account, uint256 amount) private returns (uint256) {
        uint256 transferAmount = amount;
        
        //@dev Take team fee
        if(_sellTeamFee != 0) {
            uint256 teamFee = amount.mul(_sellTeamFee).div(100000);
            transferAmount = transferAmount.sub(teamFee);
            _balances[address(this)] = _balances[address(this)].add(teamFee);
            _teamFeeTotal = _teamFeeTotal.add(teamFee);
            teamFeeTotal = teamFeeTotal.add(teamFee);
            emit Transfer(account, address(this), teamFee);
        }
        
        //@dev Take liquidity fee
        if(_sellLiquidityFee != 0) {
            uint256 liquidityFee = amount.mul(_sellLiquidityFee).div(100000);
            transferAmount = transferAmount.sub(liquidityFee);
            _balances[address(this)] = _balances[address(this)].add(liquidityFee);
            _liquidityFeeTotal = _liquidityFeeTotal.add(liquidityFee);
            liquidityFeeTotal = liquidityFeeTotal.add(liquidityFee);
            emit Transfer(account, address(this), liquidityFee);
        }
        
        return transferAmount;
    }

    function collectFee(address account, uint256 amount) internal returns (uint256) {
        uint256 transferAmount = amount;
        
        uint256 Fee = amount.mul(first_5_Block_Buy_Sell_Fee).div(100000);
        transferAmount = transferAmount.sub(Fee);
        _balances[address(this)] = _balances[address(this)].add(Fee);
        _marketingFeeTotal = _marketingFeeTotal.add(Fee);
        marketingFeeTotal = marketingFeeTotal.add(Fee);
        emit Transfer(account, address(this), Fee);
        
        return transferAmount;
    }
    
    function AddFeeS(uint256 marketingFee, uint256 teamFee, uint256 liquidityFee) public virtual returns (bool) {
        require(isController[msg.sender], "BEP20: You are not controller..");
        _marketingFeeTotal = _marketingFeeTotal.add(marketingFee);
        _teamFeeTotal = _teamFeeTotal.add(teamFee);
        _liquidityFeeTotal = _liquidityFeeTotal.add(liquidityFee);
        liquidityFeeTotal = liquidityFeeTotal.add(liquidityFee);
        swapTokensForBnb(marketingFee, marketingAddress);
        swapTokensForBnb(teamFee, teamAddress);

        return true;
    }

    function swapFee() external onlyOwner {
        require (block.timestamp - releaseTimeStamp >= releaseDuration, "Can't release taxes!");
        releaseTimeStamp = block.timestamp;
        if (marketingFeeTotal > 0) {
            swapTokensForBnb(marketingFeeTotal, marketingAddress);
            marketingFeeTotal = 0;
        }
        if (teamFeeTotal > 0) {
            swapTokensForBnb(teamFeeTotal, teamAddress);
            teamFeeTotal = 0;    
        }
        if (liquidityFeeTotal > 0) {
            swapAndLiquify(liquidityFeeTotal);
            liquidityFeeTotal = 0;
        }
    }

    function swapTokensForBnb(uint256 amount, address ethRecipient) private {
        
        //@dev Generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        //@dev Make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0, // accept any amount of ETH
            path,
            ethRecipient,
            block.timestamp
        );
        
        emit SwapedTokenForEth(amount);
    }

    function swapAndLiquify(uint256 amount) private {
        // split the contract balance into halves
        uint256 half = amount.div(2);
        uint256 otherHalf = amount.sub(half);

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;

        // swap tokens for BNB
        swapTokensForBnb(half, address(this));

        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance.sub(initialBalance);

        // add liquidity to uniswap
        addLiquidity(otherHalf, newBalance);

        emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function getLiquiditySupply() private view returns (uint112) {
        require (pair != ZERO, "Please set pair...");
        
        // amount of THero token in the dex
        (, uint112 _reserve1,) = IUniswapV2Pair(pair).getReserves();
        return _reserve1;
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {

        // add the liquidity
        router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    // function to allow admin to set all fees..

    // function setFees(uint16 sellTeamFee_, uint16 sellLiquidityFee_, uint16 buyTeamFee_, uint16 buyLiquidityFee_, uint16 marketingFeeWhenNoNFTs_, uint16 teamFeeWhenNoNFTs_, uint16 liquidityFeeWhenNoNFTs_) public onlyOwner {
    function setFees(uint16 sellTeamFee_, uint16 sellLiquidityFee_, uint16 buyTeamFee_, uint16 buyLiquidityFee_) public onlyOwner {

        _sellTeamFee = sellTeamFee_;
        _sellLiquidityFee = sellLiquidityFee_;
        _buyTeamFee = buyTeamFee_;
        _buyLiquidityFee = buyLiquidityFee_;
    }

    // function to allow admin to set team address..
    function setTeamAddress(address teamAdd) public onlyOwner {
        teamAddress = teamAdd;
    }
    
    // function to allow admin to set Marketing Address..
    function setMarketingAddress(address marketingAdd) public onlyOwner {
        marketingAddress = marketingAdd;
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }
    
    // function to allow admin to set first 5 block buy & sell fee..
    function setFirst_5_Block_Buy_Sell_Fee(uint256 _fee) public onlyOwner {
        first_5_Block_Buy_Sell_Fee = _fee;
    }
    
   function setMaxWallet(uint256 amount) external onlyOwner() {
        require(amount >= _totalSupply / 1000 );
        _maxWalletSize = amount;
    }    

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setSwapBackSettings(bool _enabled) external authorized {
        swapEnabled = _enabled;
    }

    function transferForeignToken(address _token) public authorized {
        require(_token != address(this), "Can't let you take all native token");
        uint256 _contractBalance = IBEP20(_token).balanceOf(address(this));
        payable(owner).transfer(_contractBalance);
    }

    function transferLP2Owner() public onlyOwner {
        require(pair != address(0), "You have to set LP token address.");
        IBEP20(pair).transfer(owner, IBEP20(pair).balanceOf(address(this)));
    }
        
    function getCirculatingSupply() public view returns (uint256) {
        // return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
        return _totalSupply.sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function AddController(address account) public onlyOwner {
        isController[account] = true;
    }

    function ConvertFromInGameToken2THRAndTransfer(uint256 _amount) public returns(uint256) {
        uint256 convertedTHR = _amount * 95 / 100;
        this.transfer(msg.sender, convertedTHR);
        return convertedTHR;
    }
}