pragma solidity 0.4.24;

import "./Pausable.sol";
import "./Owned.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
import "./StandardToken.sol";

 /**
 * @title Pexo
 */
contract PexoToken is StandardToken, Owned, Pausable {
    
    using SafeMath for uint256;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalReleased;
    uint256 public tokensForSale = 180000000 * 1 ether;//180 million tokens   
    uint256 public vestingTokens = 200000000 * 1 ether;//200 million (advisors,team,rewards...)
    uint256 public bountyTokens =  20000000 * 1 ether;//20 million tokens

    mapping (address => bool) public privateInvestor;
    mapping (address => bool) public teamVesting;

    uint256 public icoStartTime;
    uint256 public icoFinalizedTime;
    address public saleContract;
    address public vestingContract;
    bool public fundraising = true;

 
    mapping (address => bool) public frozenAccounts;
    event FrozenFund(address target, bool frozen);
    event PriceLog(string text);

    modifier onlyPayloadSize(uint numWords) {
        assert(msg.data.length >= numWords * 32 + 4);
        _;
    }

    modifier manageTransfer() {
        if (msg.sender == owner) {
            _;
        } else {
            require(fundraising == false);
            _;
        }
    }
    
    /**
    * @dev constructor of a token contract
    * @param _tokenOwner address of the owner of contract.
    */
constructor(address _tokenOwner ) public Owned(_tokenOwner) {
        symbol ="PEXO";
        name = "PEXO";
        decimals = 18;
        totalSupply = 400000000 * 1 ether;
    }


    /**
    * @dev  Investor can Transfer token from this method
    * @param _to address of the reciever
    * @param _value amount of tokens to transfer
    */
    function transfer(address _to, uint256 _value) public manageTransfer whenNotPaused onlyPayloadSize(2) returns (bool success) {
        
        require(_value>0);
        require(_to != address(0));
        require(!frozenAccounts[msg.sender]);
        if(teamVesting[msg.sender]==true || privateInvestor[msg.sender] == true)
        {
            require(now >= icoFinalizedTime.add(15552000)); //15552000
            super.transfer(_to,_value);
            return true;

        }
        else {
            super.transfer(_to,_value);
            return true;
        }
    }
    
    /**
    * @dev  Transfer from allow to trasfer token 
    * @param _from address of sender 
    * @param _to address of the reciever
    * @param _value amount of tokens to transfer
    */
    function transferFrom(address _from, address _to, uint256 _value) public manageTransfer whenNotPaused onlyPayloadSize(3) returns (bool) {
        require(_value>0);
        require(_to != address(0));
        require(_from != address(0));
        require(!frozenAccounts[_from]);
        if(teamVesting[_from]==true || privateInvestor[_from] == true)
        {
            require(now >= icoFinalizedTime.add(15552000));//15552000
            super.transferFrom(_from,_to,_value);
            return true;

        }
        else {
            
           super.transferFrom(_from,_to,_value);
           return true;
        }
    }

    /**
    * activates the sale contract (i.e. transfers saleable contracts)
    * @param _saleContract ,address of crowdsale contract
    */
    function activateSaleContract(address _saleContract) public whenNotPaused onlyOwner {
        require(_saleContract != address(0));
        require(saleContract == address(0));
        saleContract = _saleContract;
        balances[saleContract] = balances[saleContract].add(tokensForSale);
        totalReleased = totalReleased.add(tokensForSale);
        tokensForSale = 0;  
        icoStartTime = now;
        assert(totalReleased <= totalSupply);
        emit Transfer(address(this), saleContract, 180000000 * 1 ether);
    }
     
    /**
    * activates the sale contract (i.e. transfers saleable contracts)
    * @param _vestingContract ,address of crowdsale contract
    */
    function activateVestingContract(address _vestingContract) public whenNotPaused onlyOwner {
        
        require(_vestingContract != address(0));
        require(vestingContract == address(0));
        vestingContract = _vestingContract;
        uint256 vestableTokens = vestingTokens;
        balances[vestingContract] = balances[vestingContract].add(vestableTokens);
        totalReleased = totalReleased.add(vestableTokens);
        assert(totalReleased <= totalSupply);
        emit Transfer(address(this), vestingContract, 200000000 * 1 ether);
    }

    /**
    * @dev function to check whether passed address is a contract address
    */
    function isContract(address _address) private view returns (bool is_contract) {
        uint256 length;
        assembly {
        //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_address)
        }
        return (length > 0);
    }
    
    function burn(uint256 _value) public whenNotPaused returns (bool success) {
        require(_value > 0);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalReleased = totalReleased.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
  
    /**
    * @dev this function can only be called by crowdsale contract to transfer tokens to investor
    * @param _to address The address of the investor.
    * @param _value uint256 The amount of tokens to be send
    */
    function saleTransfer(address _to, uint256 _value,bool status) external whenNotPaused returns (bool) {
        require(saleContract != address(0));
        require(msg.sender == saleContract);
        require(!frozenAccounts[_to]);
        if(status == true)
        {
            privateInvestor[_to] = true;
            return super.transfer(_to, _value);
            
        }
        else
        {
            require(privateInvestor[_to] != true);
            return super.transfer(_to, _value);

        }
            
        }

    /**
    * @dev this function can only be called by  contract to transfer tokens to vesting beneficiary
    * @param _to address The address of the beneficiary.
    * @param _value uint256 The amount of tokens to be send
    */
    function vestingTransfer(address _to, uint256 _value) external whenNotPaused returns (bool) {
        require(icoFinalizedTime == 0);
        require(vestingContract != address(0));
        teamVesting[_to] = true;
        require(msg.sender == vestingContract);
        return super.transfer(_to, _value);
    }
    
    /**
    * @dev this function will burn the unsold tokens after crowdsale is over and this can be called
    *  from crowdsale contract only when crowdsale is over
    */
    function burnTokensForSale() external whenNotPaused returns (bool) {
        require(saleContract != address(0));
        require(msg.sender == saleContract);
        uint256 tokens = balances[saleContract];
        require(tokens > 0);
        require(tokens <= totalSupply);
        balances[saleContract] = 0;
        totalSupply = totalSupply.sub(tokens);
        totalReleased = totalReleased.sub(tokens);
        emit Burn(saleContract, tokens);
        return true;
    }

    /**
    * @dev this function will closes the sale ,after this anyone can transfer their tokens to others.
    */
    function finalize() external whenNotPaused returns(bool){
        require(fundraising != false);
        require(msg.sender == saleContract);
        fundraising = false;
        icoFinalizedTime = now;
        return true;
    }

   /**
   * @dev this function will freeze the any account so that the frozen account will not able to participate in crowdsale.
   * @param target ,address of the target account 
   * @param freeze ,boolean value to freeze or unfreeze the account ,true to freeze and false to unfreeze
   */
   function freezeAccount (address target, bool freeze) public onlyOwner {
        require(target != 0x0);
        frozenAccounts[target] = freeze;
        emit FrozenFund(target, freeze); // solhint-disable-line
    }

    /**
    * @dev this function will send the bounty tokens to given address
    * @param _to ,address of the bounty receiver.
    * @param _value , number of tokens to be sent.
    */
    function sendBounty(address _to, uint256 _value) public whenNotPaused onlyOwner returns (bool) {
        require(_to != address(0));
        require(_value > 0 );        
        uint256 value = _value.mul(1 ether);
        require(bountyTokens >= value);
        totalReleased = totalReleased.add(value);
        require(totalReleased <= totalSupply);
        balances[_to] = balances[_to].add(value);
        bountyTokens = bountyTokens.sub(value);
        emit Transfer(address(this), _to, value);
        return true;
   }
   

    /**
    * @dev Function to transfer any ERC20 token  to owner address which gets accidentally transferred to this contract
    * @param tokenAddress The address of the ERC20 contract
    * @param tokens The amount of tokens to transfer.
    * @return A boolean that indicates if the operation was successful.
    */
    function transferAnyERC20Token(address tokenAddress, uint tokens) public whenNotPaused onlyOwner returns (bool success) {
        require(tokenAddress != address(0));
        require(isContract(tokenAddress));
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
    
    function () external payable {
        revert();
    }
    
}