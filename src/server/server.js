import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import FlightSuretyData from '../../build/contracts/FlightSuretyData.json';
import Config from './config.json';
import Web3 from 'web3';
import express from 'express';
import cors from 'cors';
import _ from 'lodash';

const ORACLES_COUNT = 30;
const GAS = 10000000;
const REGISTRATION_FEE = Web3.utils.toWei("1", "ether");


let config = Config['localhost'];
let web3 = new Web3(new Web3.providers.WebsocketProvider(config.url.replace('http', 'ws')));
let flightSuretyApp = new web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
let flightSuretyData = new web3.eth.Contract(FlightSuretyData.abi, config.dataAddress);
let oraclesRegistered = [];
let oracleRequest = {};
let airlines = [];
let flights = [];
let flightsStatusInfo = [];
let contractBalance = {};
const flightsStatusCodes = [0, 10, 20, 30, 40, 50];

const app = express();
app.use(cors());

// Oracle Initialization
flightSuretyApp.methods.getOraclesCount().call({}, function (error, oraclesCounter) {
  if (error) console.log(error);
  if (oraclesRegistered.length === 0 && Number(oraclesCounter) === 0) {
    web3.eth.getAccounts().then(accounts => {
      if (accounts.length > 0) {
        for (let a = accounts.length; a > accounts.length - ORACLES_COUNT; a--) {
          flightSuretyApp.methods.registerOracle().send({
            from: accounts[a - 1],
            value: REGISTRATION_FEE,
            gas: GAS,
          });
        }
      }
    });
  }
});

flightSuretyApp.events.OracleRegistered({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  oraclesRegistered.push(event.returnValues);
  if (oraclesRegistered.length === ORACLES_COUNT) {
    console.log(`Total Oracles Registered: ${oraclesRegistered.length}.`)
    oraclesRegistered = oraclesRegistered.map(o => ({
      oracleAddress: o.oracleAddress,
      indexes: o.indexes
    }))
  }
});

// Oracle Updates
flightSuretyApp.events.OracleRequest({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  oracleRequest = {
    index: event.returnValues.index,
    airline: event.returnValues.airline,
    flight: event.returnValues.flight,
    timestamp: event.returnValues.timestamp
  }
  console.log('--OracleRequest--');
  console.log(oracleRequest);
  console.log('--OracleRequest--');

  // Oracle Functionality
  oraclesRegistered.forEach(o =>
    o.indexes.forEach(i => {
      flightSuretyApp.methods.submitOracleResponse(
        i,
        oracleRequest.airline,
        oracleRequest.flight,
        oracleRequest.timestamp,
        flightsStatusCodes[Math.floor(Math.random() * flightsStatusCodes.length)]
      )
        .send({
          from: o.oracleAddress,
          gas: GAS
        })
        .catch(function (err) {
          console.log(err.message);
        });
    })
  );
});


app.get('/airlines', (req, res) => {
  res.send(
    airlines.length > 0 ?
      airlines.map(a => ({
        airlineAddress: a.airlineAddress,
        airlineName: a.airlineName,
        isFunded: a.isFunded,
        registeredBy: a.registeredBy,
        airlinesCounter: a.airlinesCounter
      })) : []
  )
})

app.get('/flights', (req, res) => {
  res.send(
    flights.length > 0 ?
      flights.map(f => ({
        airline: f.airline,
        flight: f.flight,
        timestamp: f.updatedTimestamp,
        isRegistered: f.isRegistered
      })) : []
  )
})

app.get('/flightsStatus', (req, res) => {
  res.send(
    flightsStatusInfo.length > 0 ?
      flightsStatusInfo.map(f => ({
        airline: f.airline,
        flight: f.flight,
        timestamp: f.timestamp,
        status: f.status
      })) : []
  )
})

app.get('/contractBalance', (req, res) => {
  flightSuretyApp.methods.getBalanceApp().call({}, function (error, result) {
    if (error) console.log(error);
    res.send(
      {
        amount: result
      }
    )
    console.log('--getBalanceApp--');
    console.log(result);
    console.log('--getBalanceApp--');
  })
})

flightSuretyData.events.AirlineRegisteredVote({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log('--AirlineRegisteredVote--');
  console.log(event.returnValues)
  console.log('--AirlineRegisteredVote--');
});

flightSuretyData.events.AirlineOnHoldRegistered({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log('--AirlineOnHoldRegistered--');
  console.log(event.returnValues)
  console.log('--AirlineOnHoldRegistered--');
});

flightSuretyData.events.AirlineParticipate({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log('--AirlineParticipate--');
  console.log(event.returnValues)
  console.log('--AirlineParticipate--');
});

flightSuretyData.events.InsuranceBuyed({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log('--InsuranceBuyed--');
  console.log(event.returnValues)
  console.log('--InsuranceBuyed--');
});

flightSuretyData.events.PassengerFlight({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log('--PassengerFlight--');
  console.log(event.returnValues)
  console.log('--PassengerFlight--');
});

flightSuretyData.events.ContractBalanceData({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log('--ContractBalanceData--');
  console.log(event.returnValues)
  console.log('--ContractBalanceData--');
});

flightSuretyApp.events.ContractBalanceApp({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  contractBalance = {
    amount: event.returnValues.amount
  }
  console.log('--ContractBalanceApp--');
  console.log(event.returnValues)
  console.log('--ContractBalanceApp--');
});

flightSuretyApp.events.StatusToInsurance({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log('--StatusToInsurance--');
  console.log(event.returnValues)
  console.log('--StatusToInsurance--');
});

flightSuretyData.events.CreditInsurees({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log('--CreditInsurees--');
  console.log(event.returnValues)
  console.log('--CreditInsurees--');
});

flightSuretyApp.events.WithdrawInsureesApp({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log('--WithdrawInsureesApp--');
  console.log(event.returnValues)
  console.log('--WithdrawInsureesApp--');
});

flightSuretyData.events.WithdrawInsureesData({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  console.log('--WithdrawInsureesData--');
  console.log(event.returnValues)
  console.log('--WithdrawInsureesData--');
});

flightSuretyApp.methods.getBalanceApp().call({}, function (error, result) {
  if (error) console.log(error);
  contractBalance = {
    amount: result
  }
  console.log('--getBalanceApp--');
  console.log(result);
  console.log('--getBalanceApp--');
});

flightSuretyData.events.AirlineRegistered({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  //if an event of a certain airline address is present in the array, the object get replaced by the last one, to avoid duplication of records
  let idx = _.findIndex(airlines, a => a.airlineAddress == event.returnValues.airlineAddress);
  if (idx === -1) {
    airlines.push(event.returnValues);
  } else {
    airlines[idx] = event.returnValues;
  }
  console.log('--AirlineRegistered--');
  console.log(event.returnValues);
  console.log('--AirlineRegistered--');
});

flightSuretyApp.events.FlightRegistered({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  flights.push(event.returnValues);
  console.log('--FlightRegistered--');
  console.log(event.returnValues)
  console.log('--FlightRegistered--');
});

flightSuretyApp.events.FlightStatusInfo({
  fromBlock: 0
}, function (error, event) {
  if (error) console.log(error)
  flightsStatusInfo.push(event.returnValues);
  console.log('--FlightStatusInfo--');
  console.log(event.returnValues);
  console.log('--FlightStatusInfo--');
});

export default app;


