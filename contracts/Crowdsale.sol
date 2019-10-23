pragma solidity  0.4.24;
import "./SafeMath.sol";
import "./Owned.sol";
import "./Oraclize.sol";

contract PexoToken {
    function transfer (address, uint) public;
    function burnTokensForSale() external returns (bool);
    function saleTransfer(address,uint256,bool) external returns (bool);
    function finalize() external returns (bool);
}


contract Crowdsale is Owned, usingOraclize { 
  
  using SafeMath for uint256;
  uint256 public ethPrice; // 1 Ether price in USD cents.
  uint256 constant CUSTOM_GASLIMIT = 150000;
  uint256 public updateTime = 0;
  // end oraclize variables

  //Oraclize events
  event LogConstructorInitiated(string nextStep);
  event newOraclizeQuery(string description);
  event newPriceTicker(bytes32 myid, string price, bytes proof);
  // End oraclize events

  // The token being sold
  PexoToken public token;

  uint256 public hardCap = 7100000000;//71 million USD in cents 
  uint256 public softCap = 700000000; //7 million USD in cents. 

  uint256 public tokensForSale = 180000000 * 1 ether;//180 million tokens
  uint256 public tokensForPrivateSale = 80000000 * 1 ether;//80 million tokens
  uint256 public tokensForPublicSale = 100000000 * 1 ether;// 100 million tokens

  uint256 public privateSaletokenSold = 0;
  uint256 public publicSaleRoundOneTokenSold = 0; 
  uint256 public publicSaleRoundTwoTokenSold = 0;
  uint256 public publicSaleRoundThreeTokenSold = 0;
  uint256 public publicSaleRoundFourTokenSold = 0;
  uint256 public publicSaleRoundFiveTokenSold = 0;  
  

  // Address where funds are collected
  address public wallet;


  uint256 public discountPublicSaleRoundOne = 75;
  uint256 public discountPublicSaleRoundTwo = 40;
  uint256 public discountPublicSaleRoundThree = 20;
  uint256 public discountPublicSaleRoundFour = 10;
  uint256 public discountPublicSaleRoundFive = 0;
  
  bool public crowdSaleStarted = false;

  // Amount of wei raised
  uint256 public totalRaisedInCents;
  

  enum Stages {CrowdSaleNotStarted, Pause, PrivateSaleStart,PrivateSaleEnd,PublicSaleRoundOneStart,PublicSaleRoundOneEnd,PublicSaleRoundTwoStart,PublicSaleRoundTwoEnd, PublicSaleRoundThreeStart, PublicSaleRoundThreeEnd, PublicSaleRoundFourStart, PublicSaleRoundFourEnd, PublicSaleRoundFiveStart, PublicSaleRoundFiveEnd}
  Stages currentStage;
  Stages previousStage;
  bool public Paused;

   // adreess vs state mapping (1 for exists , zero default);
   mapping (address => bool) public whitelistedContributors;
   mapping (address => bool) public PrivateSaleInvestor;
  
   modifier CrowdsaleStarted(){
      require(crowdSaleStarted);
      _;
   }
 
    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
    *@dev initializes the crowdsale contract 
    * @param _newOwner Address who has special power to change the ether price in cents according to the market price
    * @param _wallet Address where collected funds will be forwarded to
    * @param _token Address of the token being sold
    *  @param _ethPriceInCents ether price in cents
    */
    constructor(address _newOwner, address _wallet, PexoToken _token,uint256 _ethPriceInCents) Owned(_newOwner) public {
        require(_wallet != address(0));
        require(_token != address(0));
        require(_ethPriceInCents > 0);
        wallet = _wallet;
        owner = _newOwner;
        token = _token;
        ethPrice = _ethPriceInCents; //ethPrice in cents
        currentStage = Stages.CrowdSaleNotStarted;
        // oraclize_setProof(proofType_TLSNotary | proofStorage_IPFS);
        // LogConstructorInitiated("Constructor was initiated. Call 'update()' to send the Oraclize Query.");
    }
    
    /**
    * @dev fallback function ***DO NOT OVERRIDE***
    */
    function () external payable {
    
     if(msg.sender != owner){
        buyTokens(msg.sender); 
     }
     else{
     revert();
     }
     
    }

    /**
    * @dev whitelist addresses of investors.
    * @param addrs ,array of addresses of investors to be whitelisted
    * Note:= Array length must be less than 200.
    */
    function authorizeKyc(address[] addrs) public onlyOwner returns (bool success) {
        uint arrayLength = addrs.length;
        for (uint x = 0; x < arrayLength; x++) 
        {
            whitelistedContributors[addrs[x]] = true;
        }
        return true;
    }
    
    // Begin : oraclize related functions 
    function __callback(bytes32 myid, string result, bytes proof) public {
        if (msg.sender != oraclize_cbAddress()) revert();
        ethPrice = parseInt(result, 2);
        emit newPriceTicker(myid, result, proof); //event
        if (updateTime > 0) updateAfter(updateTime);
    }

    function update() public onlyOwner {
        if (updateTime > 0) updateTime = 0;
        if (oraclize_getPrice("URL", CUSTOM_GASLIMIT) > this.balance) {
            emit newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee"); //event
        } else {
            emit newOraclizeQuery("Oraclize query was sent, standing by for the answer.."); //event
            oraclize_query("URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0", CUSTOM_GASLIMIT);
        }
    }

    function updatePeriodically(uint256 _updateTime) public onlyOwner {
        updateTime = _updateTime;
        if (oraclize_getPrice("URL", CUSTOM_GASLIMIT) > this.balance) {
            emit newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit newOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            oraclize_query("URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0", CUSTOM_GASLIMIT);
        }
    }

    function updateAfter(uint256 _updateTime) internal {
        if (oraclize_getPrice("URL", CUSTOM_GASLIMIT) > this.balance) {
            emit newOraclizeQuery("Oraclize query was NOT sent, please add some ETH to cover for the query fee");
        } else {
            emit newOraclizeQuery("Oraclize query was sent, standing by for the answer..");
            oraclize_query(_updateTime, "URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0", CUSTOM_GASLIMIT);
        }
    }

    // END : oraclize related functions 

    /**
    * @dev calling this function will pause the sale
    */
    
    function pause() public onlyOwner {
      require(Paused == false);
      require(crowdSaleStarted == true);
      previousStage=currentStage;
      currentStage=Stages.Pause;
      Paused = true;
    }
  
    function restartSale() public onlyOwner {
      require(currentStage == Stages.Pause);
      currentStage=previousStage;
      Paused = false;
    }

    function startPrivateSale() public onlyOwner {
      require(!crowdSaleStarted);
      crowdSaleStarted = true;
      currentStage = Stages.PrivateSaleStart;
    }

    function endPrivateSale() public onlyOwner {

      require(currentStage == Stages.PrivateSaleStart);
      currentStage = Stages.PrivateSaleEnd;

    }

    function startPublicSaleRoundOne() public onlyOwner {

    require(currentStage == Stages.PrivateSaleEnd);
    currentStage = Stages.PublicSaleRoundOneStart;
   
    }

    function endPublicSaleRoundOne() public onlyOwner {

    require(currentStage == Stages.PublicSaleRoundOneStart);
    currentStage = Stages.PublicSaleRoundOneEnd;
   
    }

    function startPublicSaleRoundTwo() public onlyOwner {
    require(currentStage == Stages.PublicSaleRoundOneEnd);
    currentStage = Stages.PublicSaleRoundTwoStart;
    }

    function endPublicSaleRoundTwo() public onlyOwner {
    require(currentStage == Stages.PublicSaleRoundTwoStart);
    currentStage = Stages.PublicSaleRoundTwoEnd;
    }

    function startPublicSaleRoundThree() public onlyOwner {
    require(currentStage == Stages.PublicSaleRoundTwoEnd);
    currentStage = Stages.PublicSaleRoundThreeStart;
    }

    function endPublicSaleRoundThree() public onlyOwner {
    require(currentStage == Stages.PublicSaleRoundThreeStart);
    currentStage = Stages.PublicSaleRoundThreeEnd;
    
    }
    
    function startPublicSaleRoundFour() public onlyOwner {
    require(currentStage == Stages.PublicSaleRoundThreeEnd);
    currentStage = Stages.PublicSaleRoundFourStart;
    }

    function endPublicSaleRoundFour() public onlyOwner {
    require(currentStage == Stages.PublicSaleRoundFourStart);
    currentStage = Stages.PublicSaleRoundFourEnd;
    
    }
    
    function startPublicSaleRoundFive() public onlyOwner {
    require(currentStage == Stages.PublicSaleRoundFourEnd);
    currentStage = Stages.PublicSaleRoundFiveStart;
    }

    function endPublicSaleRoundFive() public onlyOwner {
    require(currentStage == Stages.PublicSaleRoundFiveStart);
    currentStage = Stages.PublicSaleRoundFiveEnd;
    
    }


    function getStage() public view returns (string) {
    if (currentStage == Stages.PrivateSaleStart) return 'Private Sale Start';
    else if (currentStage == Stages.PrivateSaleEnd) return 'Private Sale End';
    else if (currentStage == Stages.PublicSaleRoundOneStart) return 'Public Sale Round One Start';
    else if (currentStage == Stages.PublicSaleRoundOneEnd) return 'Public Sale Round One End';
    else if (currentStage == Stages.PublicSaleRoundTwoStart) return 'Public Sale Round Two Start';
    else if (currentStage == Stages.PublicSaleRoundTwoEnd) return 'Public Sale Round Two End';
    else if (currentStage == Stages.PublicSaleRoundThreeStart) return 'Public Sale Round Three Start';
    else if (currentStage == Stages.PublicSaleRoundThreeEnd) return 'Public Sale Round Three End';
    else if (currentStage == Stages.PublicSaleRoundFourStart) return 'Public Sale Round Four Start';
    else if (currentStage == Stages.PublicSaleRoundFourEnd) return 'Public Sale Round Four End';
    else if (currentStage == Stages.PublicSaleRoundFiveStart) return 'Public Sale Round Five Start';    
    else if (currentStage == Stages.PublicSaleRoundFiveEnd) return 'Public Sale Round Five End';   
    else if (currentStage == Stages.Pause) return 'paused';
    else if (currentStage == Stages.CrowdSaleNotStarted) return 'CrowdSale Not Started';    
    }
    
    function sendPrivateSaleTokens(address _beneficiary,uint256 _usdCents,uint256 privateSaleTokensPerDollar)  CrowdsaleStarted onlyOwner public{
     
     require(_beneficiary != address(0) && privateSaleTokensPerDollar > 0);
     require(Paused != true);
     require(currentStage == Stages.PrivateSaleStart);
     totalRaisedInCents = totalRaisedInCents.add(_usdCents);
     require(totalRaisedInCents <= hardCap);
     uint256 tokens;
     tokens = _usdCents.div(100).mul(privateSaleTokensPerDollar * 1 ether);
     privateSaletokenSold = privateSaletokenSold.add(tokens);
     require (privateSaletokenSold <= tokensForPrivateSale);
     PrivateSaleInvestor[_beneficiary] = true;
     require(token.saleTransfer(_beneficiary, tokens, true)); 

   }
   
   /**
   * @dev sets the value of ether price in cents.Can be called only by the owner account.
   * @param _ethPriceInCents price in cents .
   */
   function setEthPriceInCents(uint _ethPriceInCents) onlyOwner public returns(bool) {
        ethPrice = _ethPriceInCents;
        return true;
    }

   /**
   * @param _beneficiary Address performing the token purchase
   */
   function buyTokens(address _beneficiary) CrowdsaleStarted public payable {
    require(whitelistedContributors[_beneficiary] == true );
    require(Paused != true);
    uint256 weiAmount = msg.value;
    require(weiAmount > 0);    
    uint256 usdCents = weiAmount.mul(ethPrice).div(1 ether); 
    _preValidatePurchase(usdCents);
    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(usdCents);
    _validateCapLimits(usdCents);
    _processPurchase(_beneficiary,tokens);
    wallet.transfer(msg.value);
    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
   }
  
   /**
   * @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
   * @param _usdCents Value in usdincents involved in the purchase
   */
   function _preValidatePurchase(uint256 _usdCents) internal pure { 

       require(_usdCents >= 10000);

    }
    
    /**
    * @dev Validation of the capped restrictions.
    * @param _cents cents amount
    */

    function _validateCapLimits(uint256 _cents) internal {
     
      totalRaisedInCents = totalRaisedInCents.add(_cents);
      require(totalRaisedInCents <= hardCap);
   }
   
   /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
   function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    
       PrivateSaleInvestor[_beneficiary] = false;
       require(token.saleTransfer(_beneficiary, _tokenAmount, false));    

   }

   /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
   function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
   }
  

    /**
    * @param _usdCents Value in usd cents to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _usdCents
    */
    function _getTokenAmount(uint256 _usdCents) CrowdsaleStarted internal returns (uint256) {
    uint256 tokens;
    uint256 publicSaleTokens;    
     
      if (currentStage == Stages.PublicSaleRoundOneStart) {
         
        publicSaleTokens = _usdCents.div(25).mul(1 ether);          
        tokens = publicSaleTokens;
        publicSaleRoundOneTokenSold = publicSaleRoundOneTokenSold.add(tokens);
        require(publicSaleRoundOneTokenSold <= tokensForPublicSale.div(5));
      }
      else if (currentStage == Stages.PublicSaleRoundTwoStart) {

         publicSaleTokens = _usdCents.div(60).mul(1 ether);          
         tokens = publicSaleTokens;
         publicSaleRoundTwoTokenSold = publicSaleRoundTwoTokenSold.add(tokens);         
         require(publicSaleRoundTwoTokenSold <= tokensForPublicSale.div(5));         
      }
      else if (currentStage == Stages.PublicSaleRoundThreeStart) {

         publicSaleTokens = _usdCents.div(80).mul(1 ether);          
         tokens = publicSaleTokens;
         publicSaleRoundThreeTokenSold = publicSaleRoundThreeTokenSold.add(tokens);         
         require(publicSaleRoundThreeTokenSold <= tokensForPublicSale.div(5));                  
      }
      else if (currentStage == Stages.PublicSaleRoundFourStart) {

         publicSaleTokens = _usdCents.div(90).mul(1 ether);          
         tokens = publicSaleTokens;
         publicSaleRoundFourTokenSold = publicSaleRoundFourTokenSold.add(tokens);         
         require(publicSaleRoundFourTokenSold <= tokensForPublicSale.div(5));         
      }
      else if (currentStage == Stages.PublicSaleRoundFiveStart) {

         publicSaleTokens = _usdCents.div(100).mul(1 ether);          
         tokens = publicSaleTokens;
         publicSaleRoundFiveTokenSold = publicSaleRoundFiveTokenSold.add(tokens);         
         require(publicSaleRoundFiveTokenSold <= tokensForPublicSale.div(5));         

      }
      
    
      return tokens;
    }
    
    function discountInCurrentSale() public view returns (uint256)
    {

    if (currentStage == Stages.PublicSaleRoundOneStart) 
    return discountPublicSaleRoundOne;
    
    else if (currentStage == Stages.PublicSaleRoundTwoStart) 
    return discountPublicSaleRoundTwo;
    
    else if (currentStage == Stages.PublicSaleRoundThreeStart)
    return discountPublicSaleRoundThree;
    
    else if (currentStage == Stages.PublicSaleRoundFourStart) 
    return discountPublicSaleRoundFour;
    
    else if (currentStage == Stages.PublicSaleRoundFiveStart) 
    return discountPublicSaleRoundFive;    
    
    }
    
    function tokenAmount(uint256 _usdCents) CrowdsaleStarted public view returns (uint256) {

    uint256 tokens;
    uint256 publicSaleTokens;    
      if (currentStage == Stages.PublicSaleRoundOneStart) {
 
        publicSaleTokens = _usdCents.div(25).mul(1 ether);          
        tokens = publicSaleTokens;
      }
      else if (currentStage == Stages.PublicSaleRoundTwoStart) {

        publicSaleTokens = _usdCents.div(60).mul(1 ether);          
        tokens = publicSaleTokens;
        
      }
      else if (currentStage == Stages.PublicSaleRoundThreeStart) {

        publicSaleTokens = _usdCents.div(80).mul(1 ether);          
        tokens = publicSaleTokens;

      }
      else if (currentStage == Stages.PublicSaleRoundFourStart) {

        publicSaleTokens = _usdCents.div(90).mul(1 ether);          
        tokens = publicSaleTokens;

      }
      else if (currentStage == Stages.PublicSaleRoundFiveStart) {

        publicSaleTokens = _usdCents.div(100).mul(1 ether);          
        tokens = publicSaleTokens;

      }
      
    
      return tokens;
    }

    /**
    * @dev burn the unsold tokens.
    */
    function burnTokens() public onlyOwner {
        require(currentStage == Stages.PublicSaleRoundFiveEnd);
        require(token.burnTokensForSale());
    }
        
    /**
    * @dev finalize the crowdsale.After finalizing ,tokens transfer can be done.
    */
    function finalizeSale() public  onlyOwner {
        require(currentStage == Stages.PublicSaleRoundFiveEnd);
        require(token.finalize());
        
    }

    function isSoftCapReached() public view returns(bool){
        if(totalRaisedInCents >= softCap){
            return true;
        }
        else {
            return false;
        }
    }
    //cents    
    function tokenPriceInCurrentSale() public view returns(uint256)
    {
    
    if (currentStage == Stages.PublicSaleRoundOneStart) 
    return 25;
    
    else if (currentStage == Stages.PublicSaleRoundTwoStart) 
    return 60;
    
    else if (currentStage == Stages.PublicSaleRoundThreeStart)
    return 80;
    
    else if (currentStage == Stages.PublicSaleRoundFourStart) 
    return 90;
    
    else if (currentStage == Stages.PublicSaleRoundFiveStart) 
    return 100;
   
    }
    //Usd
    function minimumInvestmentInCurrentSale() public view returns(uint256)
    {   
    if (currentStage == Stages.PublicSaleRoundOneStart) 
    return 10000;
    
    else if (currentStage == Stages.PublicSaleRoundTwoStart) 
    return 10000;
    
    else if (currentStage == Stages.PublicSaleRoundThreeStart)
    return 10000;
    
    else if (currentStage == Stages.PublicSaleRoundFourStart) 
    return 10000;
    
    else if (currentStage == Stages.PublicSaleRoundFiveStart) 
    return 10000;
    }

}