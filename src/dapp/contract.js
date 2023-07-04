import FlightSuretyApp from '../../build/contracts/FlightSuretyApp.json';
import Config from './config.json';
import Web3 from 'web3';


export default class Contract {
    constructor(network, callback) {

        let config = Config[network];
        this.web3 = new Web3(new Web3.providers.HttpProvider(config.url));
        this.airlineFund = this.web3.utils.toWei("10", "ether");
        this.insuranceAmount = this.web3.utils.toWei("5", "ether");
        this.flightSuretyApp = new this.web3.eth.Contract(FlightSuretyApp.abi, config.appAddress);
        this.dataAddress = config.dataAddress;
        this.appAddress = config.appAddress;
        this.initialize(callback);
        this.owner = null;
        this.actualAccountSelected = null;
        this.airlines = [];
        this.passengers = [];
    }


    initialize(callback) {
        this.web3.eth.getAccounts((error, accts) => {

            this.owner = accts[0];

            let counter = 1;

            while (this.airlines.length < 5) {
                this.airlines.push(accts[counter++]);
            }

            while (this.passengers.length < 5) {
                this.passengers.push(accts[counter++]);
            }

            callback();
        });
    }

    isOperational(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .isOperational()
            .call({ from: self.owner }, callback);
    }

    getBalance(callback) {
        let self = this;
        self.flightSuretyApp.methods
            .getBalance()
            .call({ from: self.owner }, callback);
    }

    //If i dont't declare a certain amount of gas the transaction is not made, found this minor issue when adding fields to structs

    registerAirline = async (airline, name, existingAirline, callback) => {
        let self = this;
        let payload = {
            airline: airline,
            name: name,
            existingAirline: existingAirline,
        }
        return await self.flightSuretyApp.methods
            .registerAirline(payload.airline, payload.name, payload.existingAirline)
            .send({ from: self.owner, gas: 1000000 })
            .on('error', function (error, receipt) {
                callback(error, receipt);
            })
            .on('receipt', function (error, receipt) {
                callback(error, receipt);
            });
    }

    makeAirlineVote = async (airline, callback) => {
        let self = this;
        let payload = {
            airline: airline
        }
        return await self.flightSuretyApp.methods
            .makeAirlineVote(payload.airline)
            .send({ from: self.owner, gas: 1000000 })
            .on('error', function (error, receipt) {
                callback(error, receipt);
            })
            .on('receipt', function (error, receipt) {
                callback(error, receipt);
            });
    }

    fundAirline = async (airlineAddress, callback) => {
        let self = this;
        let payload = {
            airlineAddress: airlineAddress,
            value: self.airlineFund
        }
        return await self.flightSuretyApp.methods
            .fundAirline(payload.airlineAddress)
            .send({ from: payload.airlineAddress, gas: 100000000, value: payload.value })
            .on('error', function (error, receipt) {
                callback(error, receipt);
            })
            .on('receipt', function (error, receipt) {
                callback(error, receipt);
            });
    }

    registerFlight = async (airline, flight, timestamp, callback) => {
        let self = this;
        let payload = {
            airline: airline,
            flight: flight,
            timestamp: timestamp
        }
        return await self.flightSuretyApp.methods
            .registerFlight(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner, gas: 1000000 })
            .on('error', function (error, receipt) {
                callback(error, receipt);
            })
            .on('receipt', function (error, receipt) {
                callback(error, receipt);
            });
    }

    registerPassengerFlight = async (passengerAddress, airlineAddress, flight, timestamp, callback) => {
        let self = this;
        let payload = {
            airlineAddress: airlineAddress,
            flight: flight,
            timestamp: timestamp,
            passengerAddress: passengerAddress,
        }
        return await self.flightSuretyApp.methods
            .registerPassengerFlight(payload.passengerAddress, payload.airlineAddress, payload.flight, payload.timestamp)
            .send({ from: payload.passengerAddress, gas: 100000000 })
            .on('error', function (error, receipt) {
                callback(error, receipt);
            })
            .on('receipt', function (error, receipt) {
                callback(error, receipt);
            });
    }

    buy = async (passengerAddress, airlineAddress, insuranceValue, callback) => {
        let self = this;
        let payload = {
            airlineAddress: airlineAddress,
            passengerAddress: passengerAddress,
            value: insuranceValue
        }
        return await self.flightSuretyApp.methods
            .buy(payload.passengerAddress, payload.airlineAddress, payload.value)
            .send({ from: payload.passengerAddress, gas: 100000000, value: payload.value })
            .on('error', function (error, receipt) {
                callback(error, receipt);
            })
            .on('receipt', function (error, receipt) {
                callback(error, receipt);
            });
    }

    fetchFlightStatus = async (flight, airline, timestamp, callback) => {
        let self = this;
        let payload = {
            airline: airline,
            flight: flight,
            timestamp: timestamp
        }
        return await self.flightSuretyApp.methods
            .fetchFlightStatus(payload.airline, payload.flight, payload.timestamp)
            .send({ from: self.owner })
            .on('error', function (error, receipt) {
                callback(error, receipt);
            })
            .on('receipt', function (error, receipt) {
                callback(error, receipt);
            });
    }

    pay = async (airlineAddress, flight, timestamp, callback) => {
        let self = this;
        let payload = {
            airlineAddress: airlineAddress,
            flight: flight,
            timestamp: timestamp
        }
        return await self.flightSuretyApp.methods
            .pay(payload.airlineAddress, payload.flight, payload.timestamp)
            .send({ from: self.owner, gas: 100000000 })
            .on('error', function (error, receipt) {
                callback(error, receipt);
            })
            .on('receipt', function (error, receipt) {
                callback(error, receipt);
            })
            ;
    }
}