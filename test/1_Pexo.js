const PEXO = artifacts.require('PexoToken.sol');
const Crowdsale = artifacts.require('Crowdsale.sol');
const TokenVesting = artifacts.require('TokenVesting.sol');

var Web3 = require("web3");
var web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

//account 0 Owner
//account 1 Wallet
//account 2 Private Investor 
//account 3 public investor
//account 4 public investor
//account 5 Bounty tokens 
//account 6 
//account 7 
//account 8 
//account 9 

contract('PexoToken Contract', async (accounts) => {

  it('Should correctly initialize constructor values of Pexo Token Contract', async () => {
    
    this.tokenhold = await PEXO.new(accounts[0], { gas: 60000000 });
    let totalSupply = await this.tokenhold.totalSupply.call();
    let name = await this.tokenhold.name.call();
    let symbol = await this.tokenhold.symbol.call();
    let owner = await this.tokenhold.owner.call();
    let decimal = await this.tokenhold.decimals.call();
    assert.equal(totalSupply.toNumber(),400000000000000000000000000);
    assert.equal(name,'PEXO');
    assert.equal(symbol,'PEXO');
    assert.equal(decimal.toNumber(),18);
    assert.equal(owner, accounts[0]);
  
  });

  it("Should Deploy Crowdsale only", async () => {

    this.crowdhold = await Crowdsale.new(accounts[0], accounts[1], this.tokenhold.address, 10000, { gas: 60000000 });
    let owner = await this.crowdhold.owner.call();
    let wallet = await this.crowdhold.wallet.call();
    let stage = await this.crowdhold.getStage();
    let etherprice = await this.crowdhold.ethPrice.call();
    assert.equal(owner,accounts[0]);
    assert.equal(wallet,accounts[1]);
    assert.equal(stage,'CrowdSale Not Started');
    assert.equal(etherprice.toNumber(),10000);
  });

  it("Should Deploy Vesting Contract only", async () => {

    this.vesthold = await TokenVesting.new(this.tokenhold.address, accounts[0], { gas: 6000000 });
    let owner = await this.vesthold.owner.call();
    let PexoTokenAddess = await this.vesthold._token.call();
    assert.equal(owner,accounts[0]);
    assert.equal(PexoTokenAddess,this.tokenhold.address);

  });

  it("Should set Vesting Contract Address to Pexo token Contract", async () => {

    await this.tokenhold.activateVestingContract(this.vesthold.address, { gas: 600000000, from: accounts[0]});

  });

  it("Should Activate Sale contract", async () => {

    var Activate = await this.tokenhold.activateSaleContract(this.crowdhold.address, { gas: 500000000 });
  });

  it("Should be able to pause Token contract", async () => {

    var pauseStatusBefore = await this.tokenhold.paused.call();
    assert.equal(pauseStatusBefore,false);
    var pause = await this.tokenhold.pause({from : accounts[0]});
    var pauseStatusAfter = await this.tokenhold.paused.call();
    assert.equal(pauseStatusAfter,true);
  });

  it("Should be able unPause Token contract", async () => {
    var pauseStatusBefore = await this.tokenhold.paused.call();
    assert.equal(pauseStatusBefore,true);
    var pause = await this.tokenhold.unpause({from : accounts[0]});
    var pauseStatusAfter = await this.tokenhold.paused.call();
    assert.equal(pauseStatusAfter,false);
  });

  it("Should check balance of Crowdsale after, crowdsale activate from token contract", async () => {
    let balancOfCrowdsale = 180000000;
    var balance = await this.tokenhold.balanceOf.call(this.crowdhold.address);
    assert.equal(balance.toNumber()/10**18,balancOfCrowdsale);
  });

  it("Should check balance of Vesting Contract, after Vesting activate from token contract", async () => {
    let balancOfVesting = 200000000;
    var balance = await this.tokenhold.balanceOf.call(this.vesthold.address);
    assert.equal(balance.toNumber()/10**18,balancOfVesting);
  });

  it("Should be able to check total tokens  ", async () => {

    let tokens = await this.tokenhold.totalSupply.call();
    assert.equal(tokens.toNumber()/10**18,400000000);//400 million token
  });

  it("Should be able to check tokens for sale ", async () => {

    let tokens = await this.tokenhold.tokensForSale.call();
    assert.equal(tokens.toNumber(),0);//0 after send to crowdsale contract
  });
 
  it("Should be able to check tokens for Vesting contract ", async () => {

    let tokens = await this.tokenhold.vestingTokens.call();
    assert.equal(tokens.toNumber()/10**18,200000000);//200 million token
  });

  it("Should be able to check tokens for Bounty ", async () => {

    let tokens = await this.tokenhold.bountyTokens.call();
    assert.equal(tokens.toNumber()/10**18,20000000);//20 million token
  });

  it("Should be able to check tokens for sale in crowdsale Contract ", async () => {

    let tokens = await this.crowdhold.tokensForSale.call();
    assert.equal(tokens.toNumber()/10**18,180000000);//180 million token
  });

  it("Should be able to check tokens for Private Sale ", async () => {

    let tokens = await this.crowdhold.tokensForPrivateSale.call();
    assert.equal(tokens.toNumber()/10**18,80000000);//80 million token
  });

  it("Should be able to check tokens for Public Sale ", async () => {

    let tokens = await this.crowdhold.tokensForPublicSale.call();
    assert.equal(tokens.toNumber()/10**18,100000000);//100 million token
  });

  it("Should be able to check tokens for Vesting in Vesting contract", async () => {

    let tokens = await this.vesthold.tokensAvailableForVesting.call();
    assert.equal(tokens.toNumber()/10**18,200000000);//200 million token
  });

  it("Should Authorize KYC for accounts [2], [3], [4]", async () => {

    var authorizeKYC = await this.crowdhold.authorizeKyc([accounts[2],accounts[3],accounts[4]], { from: accounts[0] });
    var whiteListAddressNow = await this.crowdhold.whitelistedContributors.call(accounts[2]);
    assert.equal(whiteListAddressNow, true, ' now white listed');
    var whiteListAddressNow1 = await this.crowdhold.whitelistedContributors.call(accounts[3]);
    assert.equal(whiteListAddressNow1, true, ' now white listed');

  });

  it("Should Start CrowdSale ", async () => {

    var getTheStagebefore = await this.crowdhold.getStage.call();
    var stageBefore = 'CrowdSale Not Started';
    assert.equal(getTheStagebefore, stageBefore);
    var crowdsaleStart = await this.crowdhold.startPrivateSale({ from: accounts[0], gas: 500000000 });
    var getTheStage = await this.crowdhold.getStage.call();
    var _presale = 'Private Sale Start';
    assert.equal(getTheStage, _presale);

  });

  it("Should Send tokens to Private Investors ", async () => {

    var balancePrivate = await this.tokenhold.balanceOf.call(accounts[2]);
    assert.equal(balancePrivate.toNumber()/10**18,0);
    await this.crowdhold.sendPrivateSaleTokens(accounts[2],20000,5,{from : accounts[0]});
    var balancePrivate1 = await this.tokenhold.balanceOf.call(accounts[2]);
    assert.equal(balancePrivate1.toNumber()/10**18,1000);
    var totalRaisedInCents = await this.crowdhold.totalRaisedInCents.call();
    assert.equal(totalRaisedInCents.toNumber(),20000);   
  });

  it("Should be able to pause Crowdsale contract", async () => {

    var getTheStagebefore1 = await this.crowdhold.getStage.call();
    var stageBefore1 = 'Private Sale Start';
    assert.equal(getTheStagebefore1, stageBefore1);
    var pauseStautsBefore = await this.crowdhold.Paused.call();
    assert.equal(pauseStautsBefore, false, 'Unpaused');
    var pause = await this.crowdhold.pause({from : accounts[0]});
    var pauseStautsAfter = await this.crowdhold.Paused.call();
    assert.equal(pauseStautsAfter, true, 'Unpaused');
  });

  it("Should be able unPause Crowdsale contract", async () => {

    var pauseStatusAfter1 = await this.crowdhold.Paused.call();
    assert.equal(pauseStatusAfter1, true);
    var restartSale = await this.crowdhold.restartSale();
    var pauseStatusAfter12 = await this.crowdhold.Paused.call();
    assert.equal(pauseStatusAfter12, false);
  });

  it("Should be able to freeze account", async () => {

    let freezedaccount1 = await this.tokenhold.frozenAccounts.call(accounts[8]);
    assert.equal(freezedaccount1,false);
    let freezeaccount = await this.tokenhold.freezeAccount(accounts[8],true,{from : accounts[0]});
    let freezedaccount = await this.tokenhold.frozenAccounts.call(accounts[8]);
    assert.equal(freezedaccount,true);

  });

  it("Should be able to Unfreeze account", async () => {

    let freezedaccount1 = await this.tokenhold.frozenAccounts.call(accounts[8]);
    assert.equal(freezedaccount1,true);
    let freezeaccount = await this.tokenhold.freezeAccount(accounts[8],false,{from : accounts[0]});
    let freezedaccount = await this.tokenhold.frozenAccounts.call(accounts[8]);
    assert.equal(freezedaccount,false);

  });

  it("Should End private sale ", async () => {

    var getTheStagebefore = await this.crowdhold.getStage.call();
    var stageBefore = 'Private Sale Start';
    assert.equal(getTheStagebefore, stageBefore);
    var crowdsaleStart = await this.crowdhold.endPrivateSale({ from: accounts[0]});
    var getTheStage = await this.crowdhold.getStage.call();
    var _presale = 'Private Sale End';
    assert.equal(getTheStage, _presale);

  });

  it("Should be able to vest tokens from vesting Contract", async () => {

    var balanceVest = await this.tokenhold.balanceOf.call(accounts[7]);
    assert.equal(balanceVest.toNumber()/10**18,0);
    var vest = await this.vesthold.vestTokens(accounts[7], 10);
    var balanceVest1 = await this.tokenhold.balanceOf.call(accounts[7]);
    assert.equal(balanceVest1.toNumber()/10**18,10);
    var isVested = await this.tokenhold.teamVesting.call(accounts[7]);
    assert.equal(isVested,true);
  });

  it("Should Start Public sale round one ", async () => {

    var getTheStagebefore = await this.crowdhold.getStage.call();
    var stageBefore = 'Private Sale End';
    assert.equal(getTheStagebefore, stageBefore);
    var crowdsaleStart = await this.crowdhold.startPublicSaleRoundOne({ from: accounts[0]});
    var getTheStage = await this.crowdhold.getStage.call();
    var _presale = 'Public Sale Round One Start';
    assert.equal(getTheStage, _presale);

  });

  it("Should be able to check Discount in Public sale round one ", async () => {

    var discount = await this.crowdhold.discountInCurrentSale();
    assert.equal(discount.toNumber(),75);

  });

  it("Should be able to check Token price in Public sale round one ", async () => {

    var check = await this.crowdhold.tokenPriceInCurrentSale();
    assert.equal(check.toNumber(),25);
  });

  it("Should be able to get correct token amount during public sale round one", async () => {

    let tokens = await this.crowdhold.tokenAmount(100);
    assert.equal(tokens.toNumber()/10**18,4);

  });


  it("Should be able to buy Tokens  according to Public sale Round One", async () => {

    var balancePublic1 = await this.tokenhold.balanceOf.call(accounts[3]);
    assert.equal(balancePublic1.toNumber()/10**18,0);
    let etherprice1 = await this.crowdhold.ethPrice.call();
    assert.equal(etherprice1.toNumber(),10000);    
    var buy_PrivateSaleTokens = await this.crowdhold.buyTokens(accounts[3], { from: accounts[3], value: web3.toWei("1", "ether") });
    var tokens = 400;
    var balance_after = await this.tokenhold.balanceOf.call(accounts[3]);
    assert.equal(balance_after.toNumber()/10**18,tokens);
    let fundWalletAfter = await web3.eth.getBalance(accounts[1]);
    let AccountBalance_oneAfter = await web3.eth.getBalance(accounts[3]);
    //console.log(fundWalletAfter.toNumber(),'fund wallet After buy');
    //console.log(AccountBalance_oneAfter.toNumber(),'account one After buy');
    //console.log(balance_after.toNumber()/10**18,'balance tokens');
  
  });

  it("Should End Public sale round one and Start public Sale Round Two ", async () => {

    var getTheStagebefore = await this.crowdhold.getStage.call();
    var stageBefore = 'Public Sale Round One Start';
    assert.equal(getTheStagebefore, stageBefore);
    var endSale = await this.crowdhold.endPublicSaleRoundOne({ from: accounts[0]});
    var getTheStage = await this.crowdhold.getStage.call();
    var _presale = 'Public Sale Round One End';
    assert.equal(getTheStage, _presale);
    var startSale = await this.crowdhold.startPublicSaleRoundTwo({ from: accounts[0]});
    var getTheStage1 = await this.crowdhold.getStage.call();
    var _presale1 = 'Public Sale Round Two Start';
    assert.equal(getTheStage1, _presale1);
  });

  it("Should be able to check Discount in Public sale round Two ", async () => {

    var discount = await this.crowdhold.discountInCurrentSale();
    assert.equal(discount.toNumber(),40);

  });

  it("Should be able to check Token price in Public sale round Two ", async () => {

    var check = await this.crowdhold.tokenPriceInCurrentSale();
    assert.equal(check.toNumber(),60);
  });

  it("Should be able to get correct token amount during public sale round Two", async () => {

    let tokens = await this.crowdhold.tokenAmount(120);
    assert.equal(tokens.toNumber()/10**18,2);

  });

  it("Should be able to buy Tokens according to Public sale Round Two", async () => {

    var balancePublic1 = await this.tokenhold.balanceOf.call(accounts[4]);
    assert.equal(balancePublic1.toNumber()/10**18,0);
    let etherprice1 = await this.crowdhold.ethPrice.call();
    assert.equal(etherprice1.toNumber(),10000);    
    var buy_PrivateSaleTokens = await this.crowdhold.buyTokens(accounts[4], { from: accounts[4], value: web3.toWei("1", "ether") });
    var balance_after = await this.tokenhold.balanceOf.call(accounts[4]);
    assert.equal(balance_after.toNumber()/10**18,166);
    let fundWalletAfter = await web3.eth.getBalance(accounts[1]);
    let AccountBalance_oneAfter = await web3.eth.getBalance(accounts[4]);
    //console.log(fundWalletAfter.toNumber(),'fund wallet After buy');
    //console.log(AccountBalance_oneAfter.toNumber(),'account one After buy');
    //console.log(balance_after.toNumber()/10**18,'balance tokens');
  
  });
  

  it("Should End Public sale round two and Start public Sale Round Three ", async () => {

    var getTheStagebefore = await this.crowdhold.getStage.call();
    var stageBefore = 'Public Sale Round Two Start';
    assert.equal(getTheStagebefore, stageBefore);
    var endSale = await this.crowdhold.endPublicSaleRoundTwo({ from: accounts[0]});
    var getTheStage = await this.crowdhold.getStage.call();
    var _presale = 'Public Sale Round Two End';
    assert.equal(getTheStage, _presale);
    var startSale = await this.crowdhold.startPublicSaleRoundThree({ from: accounts[0]});
    var getTheStage1 = await this.crowdhold.getStage.call();
    var _presale1 = 'Public Sale Round Three Start';
    assert.equal(getTheStage1, _presale1);
  });

  it("Should be able to check Discount in Public sale round Three ", async () => {

    var discount = await this.crowdhold.discountInCurrentSale();
    assert.equal(discount.toNumber(),20);

  });

  it("Should be able to get correct token amount during public sale round Three", async () => {

    let tokens = await this.crowdhold.tokenAmount(160);
    assert.equal(tokens.toNumber()/10**18,2);

  });

  it("Should be able to check Token price in Public sale round Three ", async () => {

    var check = await this.crowdhold.tokenPriceInCurrentSale();
    assert.equal(check.toNumber(),80);
  });

  it("Should be able to buy Tokens according to Public sale Round Three", async () => {

    var balancePublic1 = await this.tokenhold.balanceOf.call(accounts[4]);
    //assert.equal(balancePublic1.toNumber()/10**18,140);
    let etherprice1 = await this.crowdhold.ethPrice.call();
    assert.equal(etherprice1.toNumber(),10000);    
    var buy_PrivateSaleTokens = await this.crowdhold.buyTokens(accounts[4], { from: accounts[4], value: web3.toWei("1", "ether") });
    var balance_after = await this.tokenhold.balanceOf.call(accounts[4]);
    assert.equal(balance_after.toNumber()/10**18,291);
    let fundWalletAfter = await web3.eth.getBalance(accounts[1]);
    let AccountBalance_oneAfter = await web3.eth.getBalance(accounts[4]);
  
  });

  it("Should End Public sale round Three and Start public Sale Round Four ", async () => {

    var getTheStagebefore = await this.crowdhold.getStage.call();
    var stageBefore = 'Public Sale Round Three Start';
    assert.equal(getTheStagebefore, stageBefore);
    var endSale = await this.crowdhold.endPublicSaleRoundThree({ from: accounts[0]});
    var getTheStage = await this.crowdhold.getStage.call();
    var _presale = 'Public Sale Round Three End';
    assert.equal(getTheStage, _presale);
    var startSale = await this.crowdhold.startPublicSaleRoundFour({ from: accounts[0]});
    var getTheStage1 = await this.crowdhold.getStage.call();
    var _presale1 = 'Public Sale Round Four Start';
    assert.equal(getTheStage1, _presale1);
  });

  it("Should be able to check Discount in Public sale round four ", async () => {

    var discount = await this.crowdhold.discountInCurrentSale();
    assert.equal(discount.toNumber(),10);

  });

  it("Should be able to get correct token amount during public sale round Four", async () => {

    let tokens = await this.crowdhold.tokenAmount(180);
    assert.equal(tokens.toNumber()/10**18,2);

  });

  it("Should be able to check Token price in Public sale round Four ", async () => {

    var check = await this.crowdhold.tokenPriceInCurrentSale();
    assert.equal(check.toNumber(),90);
  });

  it("Should be able to buy Tokens according to Public sale Round Four", async () => {

    var balancePublic1 = await this.tokenhold.balanceOf.call(accounts[4]);
    //assert.equal(balancePublic1.toNumber()/10**18,260);
    let etherprice1 = await this.crowdhold.ethPrice.call();
    assert.equal(etherprice1.toNumber(),10000);    
    var buy_PrivateSaleTokens = await this.crowdhold.buyTokens(accounts[4], { from: accounts[4], value: web3.toWei("1", "ether") });
    var balance_after = await this.tokenhold.balanceOf.call(accounts[4]);
    assert.equal(balance_after.toNumber()/10**18,402); 
    let fundWalletAfter = await web3.eth.getBalance(accounts[1]);
    let AccountBalance_oneAfter = await web3.eth.getBalance(accounts[4]);
    //console.log(fundWalletAfter.toNumber(),'fund wallet After buy');
    //console.log(AccountBalance_oneAfter.toNumber(),'account one After buy');
    //console.log(balance_after.toNumber()/10**18,'balance tokens');
  
  });

  it("Should End Public sale round four and Start public Sale Round five ", async () => {

    var getTheStagebefore = await this.crowdhold.getStage.call();
    var stageBefore = 'Public Sale Round Four Start';
    assert.equal(getTheStagebefore, stageBefore);
    var endSale = await this.crowdhold.endPublicSaleRoundFour({ from: accounts[0]});
    var getTheStage = await this.crowdhold.getStage.call();
    var _presale = 'Public Sale Round Four End';
    assert.equal(getTheStage, _presale);
    var startSale = await this.crowdhold.startPublicSaleRoundFive({ from: accounts[0]});
    var getTheStage1 = await this.crowdhold.getStage.call();
    var _presale1 = 'Public Sale Round Five Start';
    assert.equal(getTheStage1, _presale1);
  });

  it("Should be able to check Discount in Public sale round five ", async () => {

    var discount = await this.crowdhold.discountInCurrentSale();
    assert.equal(discount.toNumber(),0);

  });

  it("Should be able to get correct token amount during public sale round Five", async () => {

    let tokens = await this.crowdhold.tokenAmount(100);
    assert.equal(tokens.toNumber()/10**18,1);

  });

  it("Should be able to check Token price in Public sale round Five ", async () => {

    var check = await this.crowdhold.tokenPriceInCurrentSale();
    assert.equal(check.toNumber(),100);
  });

  it("Should be able to buy Tokens according to Public sale Round Five", async () => {

    var balancePublic1 = await this.tokenhold.balanceOf.call(accounts[4]);
    //assert.equal(balancePublic1.toNumber()/10**18,370);
    let etherprice1 = await this.crowdhold.ethPrice.call();
    assert.equal(etherprice1.toNumber(),10000);    
    var buy_PrivateSaleTokens = await this.crowdhold.buyTokens(accounts[4], { from: accounts[4], value: web3.toWei("1", "ether") });
    var balance_after = await this.tokenhold.balanceOf.call(accounts[4]);
    //console.log(balance_after.toNumber()/10**18);
    assert.equal(balance_after.toNumber()/10**18,502);
    let fundWalletAfter = await web3.eth.getBalance(accounts[1]);
    let AccountBalance_oneAfter = await web3.eth.getBalance(accounts[4]);
    //console.log(fundWalletAfter.toNumber(),'fund wallet After buy');
    //console.log(AccountBalance_oneAfter.toNumber(),'account one After buy');
    //console.log(balance_after.toNumber()/10**18,'balance tokens');
  
  });

  it("Should End Public sale round five", async () => {

    var getTheStagebefore = await this.crowdhold.getStage.call();
    var stageBefore = 'Public Sale Round Five Start';
    assert.equal(getTheStagebefore, stageBefore);
    var endSale = await this.crowdhold.endPublicSaleRoundFive({ from: accounts[0]});
    var getTheStage = await this.crowdhold.getStage.call();
    var _presale = 'Public Sale Round Five End';
    assert.equal(getTheStage, _presale);
  });

  it("Should be able to set ether price ", async () => {

    var currentEthprice = 10000;
    var toBeEthprice = 50000;
    var ethpricebefore = await this.crowdhold.ethPrice.call();
    assert.equal(ethpricebefore.toNumber(), currentEthprice, 'ether price before');
    var setEthPrice = await this.crowdhold.setEthPriceInCents(50000, { from: accounts[0] });
    var ethpricenow = await this.crowdhold.ethPrice.call();
    assert.equal(ethpricenow.toNumber(), toBeEthprice, 'ether price After');

  });

  it("Should be able to check if softCap reached", async () => {

    var softCap = await this.crowdhold.isSoftCapReached();
    assert.equal(softCap,false);

  });

  it("Should send Bounty Tokens  ", async () => {
    var sendbountyTokens = await this.tokenhold.sendBounty(accounts[5], 5, { gas: 5000000 });
    var BountySendValue = 5;
    var balanceOfbounty = await this.tokenhold.balanceOf.call(accounts[5]);
    let bountyLeft = await this.tokenhold.bountyTokens.call();
    assert.equal(balanceOfbounty.toNumber() / 10 ** 18, BountySendValue, 'Wrong bounty sent');

  });

  it("Should not be able to send Negative Bounty Tokens  ", async () => {

   try {
    await this.tokenhold.sendBounty(accounts[5], -5, { gas: 5000000 });
   }catch(error){
    var error_ = 'VM Exception while processing transaction: revert';
    assert.equal(error.message, error_, 'Reverted ');

   }

  });

  it("Should be able to Burn Tokens", async () => {
    var accountTokens = 5;
    var balanceOfAccount = await this.tokenhold.balanceOf.call(accounts[5]);
    assert.equal(balanceOfAccount.toNumber() / 10 ** 18, accountTokens);
    let totalSupply = await this.tokenhold.totalSupply.call();
    assert.equal(totalSupply.toNumber()/10**18,400000000,'total supply before burn');
    let totalreleased = await this.tokenhold.totalReleased.call();
    //console.log(totalreleased.toNumber()/10**18);
    var burn = await this.tokenhold.burn(4000000000000000000, { gas: 5000000,from : accounts[5] });
    var balanceOfAccount1 = await this.tokenhold.balanceOf.call(accounts[5]);
    assert.equal(balanceOfAccount1.toNumber() / 10 ** 18,1);
    let totalSupply1 = await this.tokenhold.totalSupply.call();
    //console.log(totalSupply1.toNumber()/10**18);
    assert.equal(totalSupply1.toNumber()/10**18,399999996,'total supply After burn');
    let totalreleased1 = await this.tokenhold.totalReleased.call();
    //console.log(totalreleased1.toNumber()/10**18);

  });

  it("Should be able to Burn Crowdsale Contract Tokens After Sale is Over", async () => {

    let stage = await this.crowdhold.getStage();
    assert.equal(stage, "Public Sale Round Five End", "Stage is wrong");
    await this.crowdhold.burnTokens();
    var contract_after = await this.tokenhold.balanceOf.call(this.crowdhold.address);
    assert.equal(contract_after.toNumber(), 0, "not able to correctly burn tokens");

  });

  it("Should be able to finalize Sale after sale is Over", async () => {

    let stage = await this.crowdhold.getStage();
    assert.equal(stage, "Public Sale Round Five End", "Stage is wrong");
    let fundRaisingbefore = await this.tokenhold.fundraising.call();
    assert.equal(fundRaisingbefore, true, "FundRaising is true");
    await this.crowdhold.finalizeSale();
    let fundRaising = await this.tokenhold.fundraising.call();
    assert.equal(fundRaising, false, "FundRaising is false");

  });

  it("Should be able to transfer Tokens got in public sale only", async () => {

    let balanceRecieverBefore = await this.tokenhold.balanceOf.call(accounts[6]);
    assert.equal(balanceRecieverBefore, 0, 'balance of beneficery(reciever)');
    await this.tokenhold.transfer(accounts[6], 1000000000000000000, { from: accounts[4], gas: 5000000 });
    let balanceRecieverAfter = await this.tokenhold.balanceOf.call(accounts[6]);
    assert.equal(balanceRecieverAfter.toNumber(), 1000000000000000000, 'balance of beneficery(reciever)');    
  });

  it("Should Not be able to transfer Tokens got in private sale", async () => {
try{
    var balancePrivate1 = await this.tokenhold.balanceOf.call(accounts[2]);
    assert.equal(balancePrivate1.toNumber()/10**18,1000);
    var privatesaleInvestor = await this.tokenhold.privateInvestor.call(accounts[2]);
    assert.equal(privatesaleInvestor,true);
    await this.tokenhold.transfer(accounts[6], 1000000000000000000, { from: accounts[2], gas: 5000000 });
}catch(error){
  var error_ = 'VM Exception while processing transaction: revert';
  assert.equal(error.message, error_, 'Reverted ');
}
  });

  it("should Approve address to spend specific token ", async () => {

    this.tokenhold.approve(accounts[9], 1000000000000000000, { from: accounts[4] });
    let allowance = await this.tokenhold.allowance.call(accounts[4], accounts[9]);
    assert.equal(allowance, 1000000000000000000, "allowance is wrong when approve");

  });

  it("should increase Approval ", async () => {

    let allowance1 = await this.tokenhold.allowance.call(accounts[4], accounts[9]);
    assert.equal(allowance1, 1000000000000000000, "allowance is wrong when increase approval");
    this.tokenhold.changeApproval(accounts[9], 1000000000000000000, 2000000000000000000, { from: accounts[4] });
    let allowanceNew = await this.tokenhold.allowance.call(accounts[4], accounts[9]);
    assert.equal(allowanceNew, 2000000000000000000, "allowance is wrong when increase approval done");

  });

  it("Should be able to transfer Tokens on the behalf of accounts[4]", async () => {

    let allowanceNew = await this.tokenhold.allowance.call(accounts[4], accounts[9]);
    assert.equal(allowanceNew.toNumber(), 2000000000000000000, "allowance is wrong before");
    await this.tokenhold.transferFrom(accounts[4],accounts[9],1000000000000000000,{from : accounts[9]});
    let allowanceNew1 = await this.tokenhold.allowance.call(accounts[4], accounts[9]);
    assert.equal(allowanceNew1.toNumber(), 1000000000000000000, "allowance is wrong After");
    var balance1 = await this.tokenhold.balanceOf.call(accounts[9]);
    assert.equal(balance1.toNumber()/10**18,1);  
  });

  it("Should be able to transfer ownership of Crowdsale Contract ", async () => {

    let newowner = await this.tokenhold.transferOwnership(accounts[9], { from: accounts[0] });
    let ownerNew = await this.tokenhold.newOwner.call();
    assert.equal(ownerNew, accounts[9], 'Transfered ownership');
  });

  it("Should be able to Accept ownership of Crowdsale Contract ", async () => {

    let accept = await this.tokenhold.acceptOwnership.call({from : accounts[9]});
  });


  it("should not increase Approval for Negative Tokens", async () => {

    try{  this.tokenhold.changeApproval(accounts[9], 2000000000000000000, -1000000000000000000, { from: accounts[4] });

  }catch(error){
    var error_ = 'VM Exception while processing transaction: revert';
    assert.equal(error.message, error_, 'Reverted ');
  
  }
  });

  })

