
var Test = require('../config/testConfig.js');
var BigNumber = require('bignumber.js');

contract('Flight Surety Tests', async (accounts) => {

  var config;
  before('setup contract', async () => {
    config = await Test.Config(accounts);
    await config.flightSuretyData.authorizeContract(config.flightSuretyApp.address);
  });

  /****************************************************************************************/
  /* Operations and Settings                                                              */
  /****************************************************************************************/

  it(`(multiparty) has correct initial isOperational() value`, async function () {

    // Get operating status
    let status = await config.flightSuretyData.isOperational.call();
    assert.equal(status, true, "Incorrect initial operating status value");

  });

  it(`(multiparty) can block access to setOperatingStatus() for non-Contract Owner account`, async function () {

      // Ensure that access is denied for non-Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false, { from: config.testAddresses[2] });
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, true, "Access not restricted to Contract Owner");
            
  });

  it(`(multiparty) can allow access to setOperatingStatus() for Contract Owner account`, async function () {

      // Ensure that access is allowed for Contract Owner account
      let accessDenied = false;
      try 
      {
          await config.flightSuretyData.setOperatingStatus(false);
      }
      catch(e) {
          accessDenied = true;
      }
      assert.equal(accessDenied, false, "Access not restricted to Contract Owner");
      
  });

  it(`(multiparty) can block access to functions using requireIsOperational when operating status is false`, async function () {

      await config.flightSuretyData.setOperatingStatus(false);

      let reverted = false;
      try 
      {
          await config.flightSurety.setTestingMode(true);
      }
      catch(e) {
          reverted = true;
      }
      assert.equal(reverted, true, "Access not blocked for requireIsOperational");      

      // Set it back for other tests to work
      await config.flightSuretyData.setOperatingStatus(true);

  });

  it('(airline) cannot register an Airline using registerAirline() if it is not funded', async () => {
    
    // ARRANGE
    let newAirline = accounts[2];

    // ACT
    try {
        console.log('here1');
        await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
        console.log('here2');
    }
    catch(e) {

    }
    let result = await config.flightSuretyData.isAirline.call(newAirline); 
    // let countAirlines = await config.flightSuretyData.getAirlinesCount.call(); 
    // console.log(countAirlines);
    // ASSERT
    assert.equal(result, false, "Airline should not be able to register another airline if it hasn't provided funding");

  });

//   // 1st Test
//   it("(airline) register an Airline using registerAirline()", async () => {
//     // ARRANGE
//     let newAirline = accounts[2];

//     try {
//         console.log('here1');
//         await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});
//         console.log('here2');
//     }
//     catch(e) {

//     }

//     // await config.flightSuretyApp.registerAirline(newAirline, {from: config.firstAirline});

//     // Declare and Initialize a variable for event
//     var eventEmitted = false

//     // Watch the emitted event Harvested()
//     var event = config.flightSuretyData.Registered()
//     await event.watch((err, res) => {
//         eventEmitted = true
//     })

//     assert.equal(eventEmitted, true, 'Invalid event emitted')
// })
 

});
