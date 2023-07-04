# FlightSurety

FlightSurety is a sample application project for Udacity's Blockchain course.

Project updated by the rubric requirements, in order to get Blockchain Nanodegree.

## Install

This repository contains Smart Contract code in Solidity (using Truffle), tests (in Dapp), dApp scaffolding (using HTML, CSS and JS) and server app scaffolding.

To install, download or clone the repo, then:

`npm install`
`truffle compile`

versions of node with nvm in separate terminals: 

* truffle console (node -> v19.2.0)
* migrate contracts (node -> v19.2.0)
* server (node -> v14.16.1)
* dapp (node -> v8.17.0)

I run this in 4 separate iterm panels

## Truffle

Parameters of ganache:

`ganache-cli -m "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat" --gasLimit 300000000 --gasPrice 20000000000 -a 50`

## Metamask

Register the desired accounts before interact with the dapp

## Develop Server

`npm run server`

## Develop Client

Tests run in Dapp

To use the dapp:

`truffle migrate`
`npm run dapp`

To view dapp:

`http://localhost:8000`



## Resources

* [How does Ethereum work anyway?](https://medium.com/@preethikasireddy/how-does-ethereum-work-anyway-22d1df506369)
* [BIP39 Mnemonic Generator](https://iancoleman.io/bip39/)
* [Truffle Framework](http://truffleframework.com/)
* [Ganache Local Blockchain](http://truffleframework.com/ganache/)
* [Remix Solidity IDE](https://remix.ethereum.org/)
* [Solidity Language Reference](http://solidity.readthedocs.io/en/v0.4.24/)
* [Ethereum Blockchain Explorer](https://etherscan.io/)
* [Web3Js Reference](https://github.com/ethereum/wiki/wiki/JavaScript-API)
