const AliceCoin = artifacts.require('AliceCoin');
const BobCoin = artifacts.require('BobCoin');
const AtomicSwap = artifacts.require('AtomicSwap');
const Hash = artifacts.require('Hash.sol');

module.exports = async function (deployer, network, addresses) {
  const [bob, alice] = addresses;      

  if(network === 'kovan') {
    await deployer.deploy(AliceCoin , {from:  alice});
    const tokenA = await AliceCoin.deployed();
    await deployer.deploy(BobCoin, {from: bob});
    const tokenB = await BobCoin.deployed();
    
    await deployer.deploy(AtomicSwap, tokenA.address, tokenB.address, {from: alice});
    const swap = await AtomicSwap.deployed();
    
    
    await tokenA.approve(tokenA.address, 250000, {from: alice});
    await tokenA.approve(swap.address, 250000, {from: alice});
    await tokenB.approve(tokenB.address, 250000, {from: bob});
    await tokenB.approve(swap.address, 250000, {from: bob});


    await swap.fund({from: alice});
  }
  if(network === 'binanceTestnet') {
    await deployer.deploy(Token, 'BobCoin', 'BOB', {from: alice});
    const tokenB = await Token.deployed();
    await deployer.deploy(AtomicSwap, bob, tokenB.address, 1, {from: alice});
    const swap = await AtomicSwap.deployed();
    await tokenB.approve(swap.address, 1, {from: alice});
    await swap.fund({from: alice});
  }
};