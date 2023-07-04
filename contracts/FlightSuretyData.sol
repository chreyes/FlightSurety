pragma solidity ^0.4.25;

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

contract FlightSuretyData {
    using SafeMath for uint256;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    address private contractOwner;                                      // Account used to deploy contract
    bool private operational = true;                                    // Blocks all state changes throughout the contract if false
    mapping(address => uint256) private authorizedContracts;            // Mapping for storing authorized callers.

    struct Airline {
        address airlineAddress;
        string name;
        bool isFunded;
        address registeredBy;
    }

    struct Insurance {
        address airlineAddress;
        uint256 amountPaid;
        uint256 amountCredit;
        bool credit;
        bool paid;
    }

    mapping(bytes32 => address) private passengerFlights;

    mapping(address => Airline) public airlines;                        // Mapping for storing airlines
    mapping(address => Airline) internal airlinesOnHold;                  // Mapping for storing airlines awaiting approval prior to be registered
    mapping(string => bool) internal airlinesNames;                 // Mapping for storing airlines names, just for duplication detection purpose
    mapping(address => Insurance) internal passengersInsurance;       // Mapping for storing passengers that have buyed a insurance for certain flight
    uint airlinesCounter;
    address[] multiCalls = new address[](0);
    address[] airlinesOnHoldAddresses;

    event AirlineRegistered(
        address airlineAddress,
        string airlineName,
        bool isFunded,
        address registeredBy,
        uint airlinesCounter
    );
    event AirlineOnHoldRegistered(
        address airlineAddress,
        string airlineName,
        bool isFunded,
        address registeredBy
    );
    event AirlinesRegisteredVoting(
        bool allowNewAirline
    );
    event AirlineRegisteredVote(
        address airlineAddress,
        uint multicalls,
        uint airlinesCounter,
        uint airlinesCounterHalf
        );
    event AirlineParticipate(
        address airlineAddress,
        string airlineName,
        bool isFunded
        );
    event InsuranceBuyed(
        address passengerAddress,
        address airlineAddress,
        uint256 amountPaid,
        uint256 amountCredit,
        bool credit,
        bool paid
        );
    event ContractBalanceData(
        uint amount
        );
    event PassengerFlight(
        address passengerAddress,
        bytes32 flightKey
        );
    event CreditInsurees(
        bytes32 flightKey,
        address passengerAddress,
        uint256 amount
        );
    event WithdrawInsureesData(
        bytes32 flightKey,
        address passengerAddress,
        uint256 amount
        );

    /********************************************************************************************/
    /*                                       EVENT DEFINITIONS                                  */
    /********************************************************************************************/


    /**
    * @dev Constructor
    *      The deploying account becomes contractOwner
    */
    constructor
                                (
                                    address _firstAirline
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        registerAirlineOnDeploy(
                                _firstAirline
        );
    }

    /********************************************************************************************/
    /*                                       FUNCTION MODIFIERS                                 */
    /********************************************************************************************/

    // Modifiers help avoid duplication of code. They are typically used to validate something
    // before a function is allowed to be executed.

    /**
    * @dev Modifier that requires the "operational" boolean variable to be "true"
    *      This is used on all state changing functions to pause the contract in 
    *      the event there is an issue that needs to be fixed
    */
    modifier requireIsOperational() 
    {
        require(operational, "Contract is currently not operational");
        _;  // All modifiers require an "_" which indicates where the function body will be added
    }

    /**
    * @dev Modifier that requires the "ContractOwner" account to be the function caller
    */
    modifier requireContractOwner()
    {
        require(msg.sender == contractOwner, "Caller is not contract owner");
        _;
    }

    modifier requireIsCallerAuthorized()
    {
        require(authorizedContracts[msg.sender] == 1, "Caller is not authorized");
        _;
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    /**
    * @dev Get operating status of contract
    *
    * @return A bool that is the current operating status
    */      
    function isOperational()
                            view
                            external
                            returns(bool) 
    {
        return operational;
    }


    /**
    * @dev Sets contract operations on/off
    *
    * When operational mode is disabled, all write transactions except for this one will fail
    */    
    function setOperatingStatus
                            (
                                bool mode
                            ) 
                            external
                            requireContractOwner 
    {
        operational = mode;
    }

    function authorizeContract
                            (
                                address dataContract
                            )
                            external
                            requireContractOwner
    {
        authorizedContracts[dataContract] = 1;
    }

    function deauthorizeContract
                            (
                                address dataContract
                            )
                            external
                            requireContractOwner
    {
        delete authorizedContracts[dataContract];
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

    /**
    * @dev Add the first airline to the registration queue
    *      with default values.
    *
    */   
    function registerAirlineOnDeploy
                            (
                                address _airlineAddress
                            )
                            requireIsOperational
                            internal
    {
        Airline storage firstAirline = airlines[_airlineAddress];
        firstAirline.airlineAddress = _airlineAddress;
        firstAirline.name = 'Airline1';
        firstAirline.isFunded = false;
        firstAirline.registeredBy = msg.sender;
        airlinesNames['Airline1'] = true;
        airlinesCounter++;
        emit AirlineRegistered(
                                firstAirline.airlineAddress,
                                firstAirline.name,
                                firstAirline.isFunded,
                                firstAirline.registeredBy,
                                airlinesCounter
        );
    }
   
   /**
    * @dev Add an airline to the registration queue
    *      Can only be called from FlightSuretyApp contract
    *
    */   
    function registerAirline
                            (
                                address _airlineAddress,
                                string _airlineName,
                                address _registeredByAirlineAddress
                            )
                            requireIsOperational
                            external
    {
        require(airlines[_airlineAddress].airlineAddress != _airlineAddress, "Airline address already registered.");
        require(!airlinesNames[_airlineName], "Airline name already used");
        require(airlines[_registeredByAirlineAddress].airlineAddress == _registeredByAirlineAddress, "Only existing airline may register new ones.");
        if(getAirlinesCount(airlinesCounter))
            {
            Airline storage newAirline = airlines[_airlineAddress];
            newAirline.airlineAddress = _airlineAddress;
            newAirline.name = _airlineName;
            newAirline.isFunded = false;
            newAirline.registeredBy = _registeredByAirlineAddress;
            airlinesNames[_airlineName] = true;
            airlinesCounter++;
            emit AirlineRegistered(
                                    newAirline.airlineAddress,
                                    newAirline.name,
                                    newAirline.isFunded,
                                    newAirline.registeredBy,
                                    airlinesCounter
            );
            }
        else
            {                
                Airline storage newAirlineOnHold = airlinesOnHold[_airlineAddress];
                newAirlineOnHold.airlineAddress = _airlineAddress;
                newAirlineOnHold.name = _airlineName;
                newAirlineOnHold.registeredBy = _registeredByAirlineAddress;
                airlinesOnHoldAddresses.push(_airlineAddress);                
                emit AirlineOnHoldRegistered(
                                        newAirlineOnHold.airlineAddress,
                                        newAirlineOnHold.name,
                                        newAirlineOnHold.isFunded,
                                        newAirlineOnHold.registeredBy
                );
            }
    }

    /**
    * @dev Ask airlines registered for a vote, when a new airline wants to be registered.
    *   I know that this must be off the contract, by its deterministic nature, but i think is a simple way to accomplish the multy party requirement (ideally votes must be made from the dapp).
    */  
    function makeAirlineVote
                                (    
                                    address _airlineAddress
                                )
                                requireIsOperational                                
                                external
    {
        require(airlines[_airlineAddress].airlineAddress == _airlineAddress, "Airline must be registered to make a vote.");
        bool isDuplicate = false;
        for(uint c=0; c<multiCalls.length; c++) {
            if (multiCalls[c] == _airlineAddress) {
                isDuplicate = true;
                break;
            }
        }
        require(!isDuplicate, "Airline has already called this function/voted.");
        multiCalls.push(_airlineAddress);
        emit AirlineRegisteredVote(
                                _airlineAddress,
                                multiCalls.length,
                                airlinesCounter,
                                getHalfAirlinesRegistered(airlinesCounter)
            );
        if (multiCalls.length >= airlinesCounter.div(2)) {
            Airline storage airlineOnHold = airlinesOnHold[airlinesOnHoldAddresses[0]];
            Airline storage newAirline = airlines[airlineOnHold.airlineAddress];
            newAirline.airlineAddress = airlineOnHold.airlineAddress;
            newAirline.name = airlineOnHold.name;
            newAirline.isFunded = false;
            newAirline.registeredBy = airlineOnHold.registeredBy;
            airlinesCounter++;
            airlinesNames[airlineOnHold.name] = true;
            delete airlinesOnHold[airlinesOnHoldAddresses[0]];
            delete airlinesOnHoldAddresses;
            emit AirlineRegistered(
                                    newAirline.airlineAddress,
                                    newAirline.name,
                                    newAirline.isFunded,
                                    newAirline.registeredBy,
                                    airlinesCounter
            );   
            multiCalls = new address[](0);      
        }        
    }

    /**
    * @dev Returns if the number of airlines registered meet the criteria of the first requirement of the Multiparty Consensus rubric
    *   
    */  
    function getAirlinesCount
                                (
                                    uint _airlinesCounter
                                )
                                requireIsOperational
                                view
                                internal
                                returns (bool)
    {
        return _airlinesCounter < 4;
    }

    /**
    * @dev Returns 50% of the airlines registered
    *   
    */ 
    function getHalfAirlinesRegistered
                                (
                                    uint _airlinesCounter
                                )
                                requireIsOperational
                                view
                                internal
                                returns (uint)
    {
        
        return _airlinesCounter.div(2);
    }

     /**
    * @dev Passenger select flight
    *
    */ 
    function registerPassengerFlight
                                (
                                    address _passengerAddress,
                                    bytes32 _flightKey                                    
                                )
                                external                            
    {
        require(passengerFlights[_flightKey] != _passengerAddress, "Passenger already registered in flight.");
        passengerFlights[_flightKey] = _passengerAddress;
        emit PassengerFlight(
                               _passengerAddress,
                               _flightKey
        );

    }

   /**
    * @dev Buy insurance for a flight
    *
    */   
    function buy
                            (
                                address _passengerAddress,
                                address _airlineAddress,
                                uint256 _amount           
                            )
                            public
                            payable
    {
            Insurance storage newInsurance = passengersInsurance[_passengerAddress];
            newInsurance.airlineAddress = _airlineAddress;
            newInsurance.amountPaid = _amount;
            newInsurance.amountCredit = 0;
            newInsurance.credit = false;
            newInsurance.paid = false;
            emit InsuranceBuyed(
                                _passengerAddress,
                                _airlineAddress,
                                newInsurance.amountPaid,
                                newInsurance.amountCredit,
                                newInsurance.credit,
                                newInsurance.paid
            );
    }

    /**
     *  @dev Credits payouts to insurees
    */
    function creditInsurees
                                (
                                    bytes32 _flightKey                                    
                                )
                                external
    {
            address passengerAddress = passengerFlights[_flightKey];
            require(passengerFlights[_flightKey] == passengerAddress, "Passenger must be registered in flight in order to get credit.");
            uint256 amount = passengersInsurance[passengerAddress].amountPaid;
            amount = amount.mul(3).div(2);
            Insurance storage insuranceBuyed = passengersInsurance[passengerAddress];
            insuranceBuyed.amountCredit = amount;
            insuranceBuyed.credit = true;

            emit CreditInsurees(
                                _flightKey,
                                passengerAddress,
                                amount
            );
    }
    

    /**
     *  @dev Transfers eligible payout funds to insuree
     *
    */
    function pay
                            (
                                bytes32 _flightKey
                            )
                            external
                            payable
                            returns (uint256, address)                       
    {
                address passengerAddress = passengerFlights[_flightKey];
                require(passengerFlights[_flightKey] == passengerAddress, "Passenger must have buyed an Insurance.");
                require(passengersInsurance[passengerFlights[_flightKey]].credit == true, "Passenger must get credit.");
                require(passengersInsurance[passengerFlights[_flightKey]].amountCredit > 0, "Passenger must get credit amount.");
                require(passengersInsurance[passengerFlights[_flightKey]].paid == false, "Passenger insurance already paid.");
                uint256 amount = passengersInsurance[passengerAddress].amountCredit;
                Insurance storage insuranceBuyed = passengersInsurance[passengerAddress];
                insuranceBuyed.amountCredit = 0;
                insuranceBuyed.credit = false;
                insuranceBuyed.paid = true;
                emit WithdrawInsureesData(
                                _flightKey,
                                passengerAddress,
                                amount
                );
                return (amount, passengerAddress);
    }

   /**
    * @dev Initial funding for the insurance. Unless there are too many delayed flights
    *      resulting in insurance payouts, the contract should be self-sustaining
    *
    */   
    function fund
                            (   
                            )
                            public
                            payable
    {
    }

    function getFlightKey
                        (
                            address airline,
                            string memory flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    function fundAirline
                        (
                            address _airline
                        )
                        requireIsOperational
                        external
                        payable
    {
            require(airlines[_airline].airlineAddress == _airline, "Only registered airline may be funded.");
            require(airlines[_airline].isFunded == false, "Airline already funded.");
            Airline storage airline = airlines[_airline];
            airline.isFunded = true;
            emit AirlineRegistered(
                                    airline.airlineAddress,
                                    airline.name,
                                    airline.isFunded,
                                    airline.registeredBy,
                                    airlinesCounter
            );
    } 

    /**
    * @dev Fallback function for funding smart contract.
    *
    */
    function() 
                            external 
                            payable 
    {
        fund();
    }

}

