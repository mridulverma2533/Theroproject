const solc = require('solc');
const fs = require('fs');
const express = require("express");
const app =express();
const port = 3000;

const Web3 = require('web3');
const { Contract } = require('web3-eth-contract');

const web3 = new Web3(new Web3.providers.HttpProvider("https://data-seed-prebsc-1-s1.binance.org:8545/"))
let fileContent = fs.readFileSync("contracts/Pausable.sol").toString();
let file = fs.readFileSync("contracts/Context.sol").toString();
let icont = fs.readFileSync("contracts/IContract.sol").toString();
let safe = fs.readFileSync("contracts/SafeMath.sol").toString();
let router2 = fs.readFileSync("contracts/IUniswapV2Router02.sol").toString();
let factory = fs.readFileSync("contracts/IUniswapV2Factory.sol").toString();
let pair = fs.readFileSync("contracts/IUniswapV2Pair.sol").toString();
let thero = fs.readFileSync("contracts/THeroToken.sol").toString();
let Ibep = fs.readFileSync("contracts/IBEP20.sol").toString();
let auth = fs.readFileSync("contracts/Auth.sol").toString();
let router1 = fs.readFileSync("contracts/IUniswapV2Router01.sol").toString();
// console.log(fileContent);

const input = {
    language: 'Solidity',
    sources: {
        "Pausable.sol":{
            content:fileContent
         },
   
         "IContract.sol":{
            content:icont
         },
         "SafeMath.sol":{
            content:safe
         },
         "IUniswapV2Router02.sol":{
            content:router2
         },
         "IUniswapV2Factory.sol":{
            content:factory
         },
         "IUniswapV2Pair.sol":{
            content:pair
         },

         'THeroToken.sol': {
            content: thero,
         },
         'IBEP20.sol': {
            content: Ibep,
         },
         'Context.sol': {
            content: file,
         },
         'IUniswapV2Router02.sol': {
            content: router2,
         },
         "IUniswapV2Router01.sol":{
             content:router1
         },
         "Auth.sol":{
            content:auth
        }
         


    },
    settings: {
       outputSelection: {
          '*': {
             '*': ['*'],
          },
       },
    },
 };
 const output = JSON.parse(solc.compile(JSON.stringify(input)));
 ABI = output.contracts["THeroToken.sol"]["THeroToken"].abi
 
 const contract = new web3.eth.Contract(ABI,"0x42AB84652dC378B8a726e03385eBE72D553e9513")
//  let _marketingAddress="0xc2477DeF7D19937e27A7D010A7Ccc1e5E8333534"
// let _teamAddress="0x0D3e810e251F372E6368f072f1524D716e6d58FF"
module.exports={contract}