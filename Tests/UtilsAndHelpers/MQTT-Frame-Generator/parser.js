'use strict';

//https://www.npmjs.com/package/mqtt-packet
var mqtt = require('mqtt-packet');
var parser = mqtt.parser();

var dataAsBase64 = "NEQACi9zb21ldG9waWMACVNvbWUgTWVzc2FnZSAoMikgd2l0aCBRb1MyLCBkdXA6IGZhbHNlLCByZXRhaW46IGZhbHNlLg";

console.log("-----------------");

// Synchronously emits all the parsed packets 
parser.on('packet', function(packet) {
  console.log(packet);
  // Prints: 
  // 
  // { 
  //   cmd: 'publish', 
  //   retain: false, 
  //   qos: 0, 
  //   dup: false, 
  //   length: 10, 
  //   topic: 'test', 
  //   payload: <Buffer 74 65 73 74> 
  // } 
});
 
parser.parse(new Buffer(dataAsBase64, 'base64'));
