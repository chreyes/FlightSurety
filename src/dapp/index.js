
import DOM from './dom';
import Contract from './contract';
import './flightsurety.css';
import Web3 from 'web3';

import truncateEthAddress from 'truncate-eth-address'

(async () => {

    let contract = new Contract('localhost', () => {
        if (window.ethereum) {
            window.web3 = new Web3(window.ethereum);
            window.ethereum.enable();
        }

        contract.isOperational((error, result) => {
            displayOperational('Operational Status', [{ label: 'Operational Status', error: error, value: result }]);
        });

        contract.getBalance((error, result) => {
            displayContractBalance([{ error: error, value: result }]);
        });

        const fetchEvents = async (endpoint) => await fetch('http://localhost:3000/' + endpoint).then(response => response.json());

        const fetchAirlines = () => {
            fetchEvents('airlines').then(response => {
                let displayDivTable = DOM.elid("airlines-registered");
                let displayDivSelect1 = DOM.elid("airlines-select");
                let displayDivSelect2 = DOM.elid("airlines-select2");

                while (displayDivTable.hasChildNodes()) {
                    displayDivTable.removeChild(displayDivTable.firstChild);
                }

                while (displayDivSelect1.hasChildNodes()) {
                    displayDivSelect1.removeChild(displayDivSelect1.firstChild);
                }

                while (displayDivSelect2.hasChildNodes()) {
                    displayDivSelect2.removeChild(displayDivSelect2.firstChild);
                }

                response.map((a) => {
                    let tr = displayDivTable.appendChild(DOM.tr());
                    tr.appendChild(DOM.td({}, String(a.airlineName)));
                    tr.appendChild(DOM.td({}, String(a.airlineAddress)));
                    tr.appendChild(DOM.td({}, String(a.isFunded)));
                    if (a.isFunded) {
                        displayDivSelect1.appendChild(DOM.option({ value: String(a.airlineAddress) }, 'Airline: ' + String(a.airlineName) + ' Address: ' + String(a.airlineAddress).substring(0, 7) + '...'));
                        displayDivSelect2.appendChild(DOM.option({ value: String(a.airlineAddress) }, 'Airline: ' + String(a.airlineName) + ' Address: ' + String(a.airlineAddress).substring(0, 7) + '...'));
                    }
                });
            });
        }

        const fetchFlights = () => {
            fetchEvents('flights').then(response => {
                let displayDivTable = DOM.elid("flights-registered");
                let displayDivSelect1 = DOM.elid("flights-select");
                let displayDivSelect2 = DOM.elid("flights-select2");

                while (displayDivTable.hasChildNodes()) {
                    displayDivTable.removeChild(displayDivTable.firstChild);
                }

                while (displayDivSelect1.hasChildNodes()) {
                    displayDivSelect1.removeChild(displayDivSelect1.firstChild);
                }

                while (displayDivSelect2.hasChildNodes()) {
                    displayDivSelect2.removeChild(displayDivSelect2.firstChild);
                }

                response.map((f) => {
                    let tr = displayDivTable.appendChild(DOM.tr());
                    tr.appendChild(DOM.td({}, String(truncateEthAddress(f.airline))));
                    tr.appendChild(DOM.td({}, String(f.flight)));
                    tr.appendChild(DOM.td({}, String(f.timestamp)));
                    displayDivSelect1.appendChild(DOM.option({ value: `{"flight": "` + f.flight + `", "airline": "` + f.airline + `", "timestamp": "` + f.timestamp + `"}` }, 'Flight: ' + String(f.flight) + ' Departure: ' + String(f.timestamp)));
                    displayDivSelect2.appendChild(DOM.option({ value: `{"flight": "` + f.flight + `", "airline": "` + f.airline + `", "timestamp": "` + f.timestamp + `"}` }, 'Flight: ' + String(f.flight) + ' Departure: ' + String(f.timestamp)));
                });
            });
        }

        const fetchFlightsStatus = () => {
            fetchEvents('flightsStatus').then(response => {
                let displayDivTable = DOM.elid("flights-status");

                while (displayDivTable.hasChildNodes()) {
                    displayDivTable.removeChild(displayDivTable.firstChild);
                }

                response.map((f) => {
                    let tr = displayDivTable.appendChild(DOM.tr({ className: f.status === '20' ? 'table-danger' : '' }));
                    tr.appendChild(DOM.td({}, String(truncateEthAddress(f.airline))));
                    tr.appendChild(DOM.td({}, String(f.flight)));
                    tr.appendChild(DOM.td({}, String(f.timestamp)));
                    tr.appendChild(DOM.td({}, String(f.status)));
                });
            });
        }

        //Load events from express api on window load
        fetchAirlines();
        fetchFlights();
        fetchFlightsStatus();

        // User-submitted transaction register airline
        DOM.elid('submit-airline').addEventListener('click', () => {
            let airline = DOM.elid('airline-address').value;
            let existingAirline = DOM.elid('existing-airline-address').value;
            let name = DOM.elid('airline-name').value;
            contract.registerAirline(airline, name, existingAirline, (error, result) => {
                DOM.elid('airline-address').value = '';
                DOM.elid('airline-name').value = '';
                DOM.elid('existing-airline-address').value = '';
            })
                .then(receipt => {
                    //Still figuring out why after registering the second airline the dapp doesn't update, the update is done only after the third one
                    //so i made this smelly code to force a reload to get new data from the api
                    if (receipt) {
                        location.reload();
                    }
                });
        })

        // User-submitted transaction airline vote new airline to be registered
        DOM.elid('submit-vote').addEventListener('click', () => {
            let airline = DOM.elid('airline-address-voting').value;
            contract.makeAirlineVote(airline, (error, result) => {
                DOM.elid('airline-address-voting').value = '';
            }).then(receipt => {
                if (receipt) {
                    location.reload();
                }
            });
        })

        // / User-submitted transaction fund airline with 10 eth
        DOM.elid('submit-fund-airline').addEventListener('click', () => {
            let airline = DOM.elid('airline-address-funding').value;
            contract.fundAirline(airline, (error, result) => {
                DOM.elid('airline-address-funding').value = '';
            }).then(receipt => {
                if (receipt) {
                    location.reload();
                }
            });
        })

        // User-submitted transaction register flight
        DOM.elid('submit-flight').addEventListener('click', () => {
            let airline = $('#airlines-select option:selected').val();
            let flight = DOM.elid('flight-name').value;
            let flightTime = DOM.elid('flight-time').value;
            contract.registerFlight(airline, flight, flightTime, (error, result) => {
            }).then(receipt => {
                if (receipt) {
                    location.reload();
                }
            });
        })

        // User-submitted transaction register payment
        DOM.elid('passenger-flight').addEventListener('click', () => {
            let flightSelected = $('#flights-select option:selected').val();
            let flightSelectedObj = JSON.parse(flightSelected);
            let passengerAddress = DOM.elid('passenger-address').value;
            let airlineAddress = flightSelectedObj.airline;
            let flight = flightSelectedObj.flight;
            let timestamp = flightSelectedObj.timestamp;
            contract.registerPassengerFlight(passengerAddress, airlineAddress, flight, timestamp, (error, receipt) => {
            }).then(receipt => {
                if (receipt) {
                    location.reload();
                }
            });
        })

        // User-submitted transaction register payment
        DOM.elid('passenger-buy-insurance').addEventListener('click', () => {
            let passengerAddress = DOM.elid('passenger-address2').value;
            let airlineAddress = $('#airlines-select2 option:selected').val();
            let insuranceAmount = DOM.elid('passenger-insurance-amount').value;
            let insuranceValue = contract.web3.utils.toWei(insuranceAmount, "ether");
            contract.buy(passengerAddress, airlineAddress, insuranceValue, (error, receipt) => {
            }).then(receipt => {
                if (receipt) {
                    location.reload();
                }
            });
        })

        // User-submitted transaction
        DOM.elid('submit-oracle').addEventListener('click', () => {
            let flightSelected = $('#flights-select2 option:selected').val();
            let flightSelectedObj = JSON.parse(flightSelected);
            let airlineAddress = flightSelectedObj.airline;
            let flight = flightSelectedObj.flight;
            let timestamp = flightSelectedObj.timestamp;
            contract.fetchFlightStatus(flight, airlineAddress, timestamp, (error, result) => {
            }).then(receipt => {
                if (receipt) {
                    location.reload();
                }
            });
        })

        // User-submitted transaction withdraw funds
        DOM.elid('passenger-withdraw').addEventListener('click', () => {
            let flightSelected = $('#flights-select2 option:selected').val();
            let flightSelectedObj = JSON.parse(flightSelected);
            let airlineAddress = flightSelectedObj.airline;
            let flight = flightSelectedObj.flight;
            let timestamp = flightSelectedObj.timestamp;
            contract.pay(airlineAddress, flight, timestamp, (error, receipt) => {
            }).then(receipt => {
                if (receipt) {
                    location.reload();
                }
            });
        })

        // Update Flight Timestamp
        DOM.elid('flight-time-update').addEventListener('click', () => {
            let timeNow = new Date();
            timeNow.setDate(timeNow.getDate() + 1);
            DOM.elid('flight-time').value = timeNow.getTime().toString();
        })
    });


})();

// To show the operational status of the contract, not a reusable purpose
function displayOperational(title, results) {
    let displayNav = DOM.elid("navbar");
    results.map((result) => {
        let buttonSuccess = 'btn disabled btn-success';
        let buttonDanger = 'btn disabled btn-danger';
        displayNav.appendChild(DOM.btn({ className: result.value ? buttonSuccess : buttonDanger }, result.value ? String('Operational Status: Enabled') : String('Operational Status: Disabled')));
    })
}

// To show the current balance
function displayContractBalance(results) {
    let displayNav = DOM.elid("navbar");
    results.map((result) => {
        displayNav.appendChild(DOM.btn({ className: 'btn disabled btn-warning' }, 'Contract Balance: ' + String(result.value)));
    })
}