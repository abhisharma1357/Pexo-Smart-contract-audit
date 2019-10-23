pragma solidity 0.4.24;

import "./Owned.sol";
import "./SafeMath.sol";

contract PexoToken {
    function vestingTransfer(address, uint256) external returns (bool);
}

/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Owned {
    using SafeMath for uint256;

    PexoToken public _token;
    uint256 public teamTokensSent;
    uint256 public tokensAvailableForVesting = 200000000 * 1 ether;//200 million tokens(team & founders,advisors,rewards,retained...)

    
    struct beneficiary {
        address beneficiaryAddress;
        uint256 tokens;
    }
    mapping(address => beneficiary) public beneficiaryDetails;
    
    constructor(PexoToken token,address _owner) Owned(_owner) public {
      _token = token;
    }
    
    /**
    * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
    * _beneficiary, gradually in a linear fashion until _start  By then all
    * of the balance will have vested.
    * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
    */
    function vestTokens(address _beneficiary, uint256 _tokens) public onlyOwner {    

      require(_beneficiary != address(0));
      require(beneficiaryDetails[_beneficiary].beneficiaryAddress == (0x0));
      uint256 tokens = _tokens * 1 ether;
      beneficiaryDetails[_beneficiary].beneficiaryAddress  = _beneficiary;
      beneficiaryDetails[_beneficiary].tokens = _tokens * 1 ether;
      teamTokensSent = teamTokensSent.add(tokens);
      require(teamTokensSent <= tokensAvailableForVesting);
      _token.vestingTransfer(_beneficiary, tokens);
    
}
}