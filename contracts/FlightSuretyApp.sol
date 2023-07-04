pragma solidity ^0.4.25;

// It's important to avoid vulnerabilities due to numeric overflow bugs
// OpenZeppelin's SafeMath library, when used correctly, protects agains such bugs
// More info: https://www.nccgroup.trust/us/about-us/newsroom-and-events/blog/2018/november/smart-contract-insecurity-bad-arithmetic/

import "../node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol";

/************************************************** */
/* FlightSurety Smart Contract                      */
/************************************************** */
contract FlightSuretyApp {
    using SafeMath for uint256; // Allow SafeMath functions to be called for all uint256 types (similar to "prototype" in Javascript)
    FlightSuretyDataInterface flightSuretyDataInterface;

    /********************************************************************************************/
    /*                                       DATA VARIABLES                                     */
    /********************************************************************************************/

    // Flight status codees
    uint8 private constant STATUS_CODE_UNKNOWN = 0;
    uint8 private constant STATUS_CODE_ON_TIME = 10;
    uint8 private constant STATUS_CODE_LATE_AIRLINE = 20;
    uint8 private constant STATUS_CODE_LATE_WEATHER = 30;
    uint8 private constant STATUS_CODE_LATE_TECHNICAL = 40;
    uint8 private constant STATUS_CODE_LATE_OTHER = 50;

    address private contractOwner;          // Account used to deploy contract

    struct Flight {
        bool isRegistered;
        // string flight;
        uint8 statusCode;
        uint256 updatedTimestamp;        
        address airline;
    }

    mapping(bytes32 => Flight) private flights;

    event FlightRegistered(
        bool isRegistered,
        string flight,
        uint256 updatedTimestamp,        
        address airline
    );

    event ContractBalanceApp(
        uint amount
    );

    event StatusToInsurance(
        uint8 statusCode
    );

    uint256 private constant MIN_RESPONSES_ORACLES_20 = 3;

    uint countStatusCode20;
    uint256 amount;
    address passengerAddress;

     event WithdrawInsureesApp(
        bytes32 flightKey,
        address passengerAddress,
        uint256 amount
    );
    

 
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
         // Modify to call data contract's status
        require(true, "Contract is currently not operational");  
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

    /********************************************************************************************/
    /*                                       CONSTRUCTOR                                        */
    /********************************************************************************************/

    /**
    * @dev Contract constructor
    *
    */
    constructor
                                (
                                    address _dataContract
                                ) 
                                public 
    {
        contractOwner = msg.sender;
        flightSuretyDataInterface = FlightSuretyDataInterface(_dataContract);
    }

    /********************************************************************************************/
    /*                                       UTILITY FUNCTIONS                                  */
    /********************************************************************************************/

    function isOperational() 
                            external
                            returns(bool) 
    {
        return flightSuretyDataInterface.isOperational();
        // return true;  // Modify to call data contract's status
    }

    function getBalance() 
                            external
                            view
                            returns(uint) 
    {
        return getBalanceApp();
    }

    function getOraclesCount() 
                            external
                            view
                            returns(uint) 
    {
        return oraclesCounter;
    }

    /********************************************************************************************/
    /*                                     SMART CONTRACT FUNCTIONS                             */
    /********************************************************************************************/

  
   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function registerAirline
                            (  
                                address _airlineAddress,
                                string _airlineName,
                                address _registeredByAirlineAddress 
                            )
                            external                            
                            // returns(bool success, uint256 votes)
                            returns(bool)
    {
        flightSuretyDataInterface.registerAirline(
                                                _airlineAddress,
                                                _airlineName,
                                                _registeredByAirlineAddress
            );
    }
    
   /**
    * @dev Add an airline to the registration queue
    *
    */   
    function makeAirlineVote
                            (  
                                address _airlineAddress
                            )
                            external                            
    {
        flightSuretyDataInterface.makeAirlineVote(
                                                _airlineAddress
            );
    }

    /**
    * @dev Fund an airline
    *
    */   
    function fundAirline
                            (
                                address _airlineAddress                                              
                            )
                            external
                            payable
    {
        require(msg.value == 10 ether, "Fund airline must be 10 eth");
        flightSuretyDataInterface.fundAirline(
                                                _airlineAddress
                                    );
        emit ContractBalanceApp(
                                getBalanceApp()
        );
    }
    

   /**
    * @dev Register a future flight for insuring.
    *
    */  
    function registerFlight
                                (
                                    address airline,
                                    string flight,
                                    uint256 timestamp
                                )
                                external
                                
    {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        Flight storage flightToRegister = flights[flightKey];
        flightToRegister.isRegistered = true;
        flightToRegister.statusCode = 0;
        flightToRegister.updatedTimestamp = timestamp;
        flightToRegister.airline = airline;
        emit FlightRegistered(
                                flights[flightKey].isRegistered,
                                flight,
                                flights[flightKey].updatedTimestamp,
                                flights[flightKey].airline
        );
    }
    
   /**
    * @dev Called after oracle has updated flight status
    *
    */  
    function processFlightStatus
                                (
                                    address airline,
                                    string flight,
                                    uint256 timestamp,
                                    uint8 statusCode
                                )
                                internal
    {
        bytes32 flightKey = getFlightKey(airline, flight, timestamp);
        if (statusCode == 20) {
            countStatusCode20++;
            if(countStatusCode20 >= MIN_RESPONSES_ORACLES_20){
                emit StatusToInsurance(
                                        statusCode
                                    );
                flightSuretyDataInterface.creditInsurees(flightKey);
            }
        }
    }

    /**
    * @dev Generate a request for oracles to fetch flight information
    *
    */ 
    function fetchFlightStatus
                        (
                            address airline,
                            string flight,
                            uint256 timestamp                            
                        )
                        external
    {
        uint8 index = getRandomIndex(msg.sender);
        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp));
        oracleResponses[key] = ResponseInfo({
                                                requester: msg.sender,
                                                isOpen: true
                                            });
        emit OracleRequest(index, airline, flight, timestamp);
    }

    /**
    * @dev Get contract current balance in eth
    *
    */ 
    function getBalanceApp() view public returns (uint) {
        return address(this).balance / 1 ether;
    }

    /**
    * @dev Allow a passenger to buy an insurance from airline
    *
    */ 
    function buy
                            (
                                address _passengerAddress,
                                address _airlineAddress,
                                uint256 _amount               
                            )
                            external
                            payable
    {
        require(msg.value <= 1 ether, "Insurance payment up to 1 eth");
        flightSuretyDataInterface.buy(
                                                _passengerAddress,
                                                _airlineAddress,
                                                _amount
                                    );
        emit ContractBalanceApp(
                                getBalanceApp()
        );
    }

    /**
    * @dev Allow a passenger to withdraw any funds credited
    *
    */ 
    function pay
                            (
                                address _airlineAddress,
                                string _flight,
                                uint256 _timestamp
                            )
                            external
                            payable
    {
        bytes32 flightKey = getFlightKey(_airlineAddress, _flight, _timestamp);
        (amount, passengerAddress) = flightSuretyDataInterface.pay(                                                
                                        flightKey
                                    );
        require(amount > getBalanceApp(), "Not enough funds to credit to");        
        address(passengerAddress).transfer(amount);
        emit WithdrawInsureesApp(
                                    flightKey,
                                    passengerAddress,
                                    amount
        );
        emit ContractBalanceApp(
                                getBalanceApp()
        );
    }

    /**
    * @dev Register a passenger in a certain flight
    *
    */ 
    function registerPassengerFlight
                                (
                                    address _passengerAddress,
                                    address _airlineAddress,
                                    string _flight,
                                    uint256 _timestamp                                   
                                )
                                external                            
    {
        bytes32 flightKey = getFlightKey(_airlineAddress, _flight, _timestamp);
        flightSuretyDataInterface.registerPassengerFlight(_passengerAddress, flightKey);
    }


// region ORACLE MANAGEMENT

    // Incremented to add pseudo-randomness at various points
    uint8 private nonce = 0;    

    // Fee to be paid when registering oracle
    uint256 public constant REGISTRATION_FEE = 1 ether;

    // Number of oracles that must respond for valid status
    uint256 private constant MIN_RESPONSES = 3;

    //Count oracles registered
    uint oraclesCounter;

    struct Oracle {
        bool isRegistered;
        uint8[3] indexes;        
    }

    // Track all registered oracles
    mapping(address => Oracle) private oracles;

    // Model for responses from oracles
    struct ResponseInfo {
        address requester;                              // Account that requested status
        bool isOpen;                                    // If open, oracle responses are accepted
        mapping(uint8 => address[]) responses;          // Mapping key is the status code reported
                                                        // This lets us group responses and identify
                                                        // the response that majority of the oracles
    }

    // Track all oracle responses
    // Key = hash(index, flight, timestamp)
    mapping(bytes32 => ResponseInfo) private oracleResponses;

    // Event fired each time an oracle submits a response
    event FlightStatusInfo(address airline, string flight, uint256 timestamp, uint8 status);

    event OracleReport(address airline, string flight, uint256 timestamp, uint8 status);

    // Event fired when flight status request is submitted
    // Oracles track this and if they have a matching index
    // they fetch data and submit a response
    event OracleRequest(uint8 index, address airline, string flight, uint256 timestamp);

    event OracleRegistered(address oracleAddress, uint8[3] indexes);


    // Register an oracle with the contract
    function registerOracle
                            (
                            )
                            external
                            payable
    {
        // Require registration fee
        require(msg.value >= REGISTRATION_FEE, "Registration fee is required");

        uint8[3] memory indexes = generateIndexes(msg.sender);

        oracles[msg.sender] = Oracle({
                                        isRegistered: true,
                                        indexes: indexes
                                    });
        oraclesCounter++;
        emit OracleRegistered(msg.sender, indexes);
        
    }

    function getMyIndexes
                            (
                            )
                            view
                            external
                            returns(uint8[3])
    {
        require(oracles[msg.sender].isRegistered, "Not registered as an oracle");

        return oracles[msg.sender].indexes;
    }




    // Called by oracle when a response is available to an outstanding request
    // For the response to be accepted, there must be a pending request that is open
    // and matches one of the three Indexes randomly assigned to the oracle at the
    // time of registration (i.e. uninvited oracles are not welcome)
    function submitOracleResponse
                        (
                            uint8 index,
                            address airline,
                            string flight,
                            uint256 timestamp,
                            uint8 statusCode
                        )
                        external
    {
        require((oracles[msg.sender].indexes[0] == index) || (oracles[msg.sender].indexes[1] == index) || (oracles[msg.sender].indexes[2] == index), "Index does not match oracle request");


        bytes32 key = keccak256(abi.encodePacked(index, airline, flight, timestamp)); 
        require(oracleResponses[key].isOpen, "Flight or timestamp do not match oracle request");

        oracleResponses[key].responses[statusCode].push(msg.sender);

        // Information isn't considered verified until at least MIN_RESPONSES
        // oracles respond with the *** same *** information
        emit OracleReport(airline, flight, timestamp, statusCode);
        if (oracleResponses[key].responses[statusCode].length >= MIN_RESPONSES) {

            emit FlightStatusInfo(airline, flight, timestamp, statusCode);

            // Handle flight status as appropriate
            processFlightStatus(airline, flight, timestamp, statusCode);
        }
    }


    function getFlightKey
                        (
                            address airline,
                            string flight,
                            uint256 timestamp
                        )
                        pure
                        internal
                        returns(bytes32) 
    {
        return keccak256(abi.encodePacked(airline, flight, timestamp));
    }

    // Returns array of three non-duplicating integers from 0-9
    function generateIndexes
                            (                       
                                address account         
                            )
                            internal
                            returns(uint8[3])
    {
        uint8[3] memory indexes;
        indexes[0] = getRandomIndex(account);
        
        indexes[1] = indexes[0];
        while(indexes[1] == indexes[0]) {
            indexes[1] = getRandomIndex(account);
        }

        indexes[2] = indexes[1];
        while((indexes[2] == indexes[0]) || (indexes[2] == indexes[1])) {
            indexes[2] = getRandomIndex(account);
        }

        return indexes;
    }

    // Returns array of three non-duplicating integers from 0-9
    function getRandomIndex
                            (
                                address account
                            )
                            internal
                            returns (uint8)
    {
        uint8 maxValue = 10;

        // Pseudo random number...the incrementing nonce adds variation
        uint8 random = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - nonce++), account))) % maxValue);

        if (nonce > 250) {
            nonce = 0;  // Can only fetch blockhashes for last 256 blocks so we adapt
        }

        return random;
    }

// endregion

}

contract FlightSuretyDataInterface {
    function isOperational() external returns(bool);
    function registerAirline(address airlineAddress, string airlineName, address _registeredByAirlineAddress) external;
    function makeAirlineVote(address airlineAddress) external;
    function fundAirline(address airline) external;
    function buy(address _passengerAddress, address _airlineAddress, uint256 _amount) external payable;
    function pay(bytes32 flightKey) external payable returns(uint256, address);
    function registerPassengerFlight(address _passengerAddress, bytes32 flightKey) external;
    function creditInsurees(bytes32 flightKey) external;
}