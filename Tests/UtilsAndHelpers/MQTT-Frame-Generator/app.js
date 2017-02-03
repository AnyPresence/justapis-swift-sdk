'use strict';

//https://www.npmjs.com/package/mqtt-packet
var mqtt = require('mqtt-packet');

console.log("-----------------");

//Constants:

var clientId = "someclientid";
var keepalive = 2000;
var username = "someusername";
var password = new Buffer("somepassword"); // Passwords are buffers 
var willTopic = "/somewilltopic";
var willMessage = new Buffer("Some will message."); // Payloads are buffers
var topic = "/sometopic";
var serverPublishedMessage = "Some Received Message.";
var triggerMessageForServerPublish = "Send me something.";

console.log("----Constants----");
console.log("-----------------");
console.log("Client Id:", clientId);
console.log("Keep Alive:", keepalive);
console.log("username:", username);
console.log("password:", password.toString());
console.log("Will Topic:", willTopic);
console.log("Will Message:", willMessage.toString());
console.log("Topic:", topic);

var connectFrameData = {
  cmd: 'connect',
  protocolId: 'MQTT', // Or 'MQIsdp' in MQTT 3.1.1 
  protocolVersion: 4, // Or 3 in MQTT 3.1 
  clean: false, // Can also be false 
  clientId: clientId,
  keepalive: keepalive, // Seconds which can be any positive number, with 0 as the default setting 
  username: username,
  password: password,
  will: {
    retained: false,
    qos: 1,
    topic: willTopic,
    payload: willMessage
  }
};

var connAckFrameData = {
  cmd: 'connack',
  returnCode: 0, // Or whatever else you see fit 
  sessionPresent: false // Can also be true. 
};


var subscibeFrameData = {
  cmd: 'subscribe',
  messageId: 0,
  subscriptions: [{
    topic: topic,
    qos: 0
  }]
};

var subAckFrameData = {
  cmd: 'suback',
  messageId: 0,
  granted: [0, 1, 2]
};

var publishFrameData = {
  cmd: 'publish',
  messageId: 0,
  qos: 0,
  dup: false,
  topic: topic,
  payload: new Buffer(""),
  retain: false
};

var pubAckFrameData = {
  cmd: 'puback',
  messageId: 0
};

var pubRecFrameData = {
  cmd: 'pubrec',
  messageId: 0
};

var pubRelFrameData = {
  cmd: 'pubrel',
  messageId: 0
};

var pubCompFrameData = {
  cmd: 'pubcomp',
  messageId: 0
};

var unsubscribeFrameData = {
  cmd: 'unsubscribe',
  messageId: 0,
  unsubscriptions: [
    topic
  ]
};

var unsubscribeAckFrameData = {
  cmd: 'unsuback',
  messageId: 0
};

var disconnectFrameData = {
  cmd: 'disconnect'
};

//1st Sequence
connectFrameData.clean = false;
connAckFrameData.returnCode = 0;
console.log("-----------------");
console.log("Connect Clean False:", mqtt.generate(connectFrameData).toString("base64"));
console.log("Connect Clean False Ack:", mqtt.generate(connAckFrameData).toString("base64"));
console.log("Disconnect:", mqtt.generate(disconnectFrameData).toString("base64"));

//2nd Sequence
connectFrameData.clean = false;
connectFrameData.clientId += "_";
connAckFrameData.returnCode = 2;//Identifier Rejected
console.log("-----------------");
console.log("Client Id:", connectFrameData.clientId);
console.log("Connect Clean False With Error:", mqtt.generate(connectFrameData).toString("base64"));
console.log("Connect Clean False With Error Ack:", mqtt.generate(connAckFrameData).toString("base64"));
console.log("Disconnect:", mqtt.generate(disconnectFrameData).toString("base64"));

//3rd Sequence
connectFrameData.clean = true;
connectFrameData.clientId = clientId;
connAckFrameData.returnCode = 0;
console.log("-----------------");
console.log("Connect Clean True:", mqtt.generate(connectFrameData).toString("base64"));
console.log("Connect Clean True Ack:", mqtt.generate(connAckFrameData).toString("base64"));

var messageId = 2;//Running Message Id

//Subscibe/Unsubscibe with qos=0,1,2
var qos;
for (qos = 0; qos <= 2; qos += 1) {
  subscibeFrameData.subscriptions[0].qos = qos;
  subscibeFrameData.messageId = messageId;
  subAckFrameData.messageId = messageId;
  console.log("-----------------");
  console.log("Message Id:", messageId);
  console.log("Subscribe QoS", qos, ":", mqtt.generate(subscibeFrameData).toString("base64"));
  console.log("Subscribe QoS", qos, "Ack", ":", mqtt.generate(subAckFrameData).toString("base64"));
  messageId += 1;

  if (qos !== 2) {
    unsubscribeFrameData.messageId = messageId;
    unsubscribeAckFrameData.messageId = messageId;
    console.log("-----------------");
    console.log("Message Id:", messageId);
    console.log("Unsubscribe MessageId", messageId, ":", mqtt.generate(unsubscribeFrameData).toString("base64"));
    console.log("Unsubscribe MessageId", messageId, "Ack", ":", mqtt.generate(unsubscribeAckFrameData).toString("base64"));
    messageId += 1; 
  }
}

publishFrameData.messageId = messageId;
publishFrameData.dup = true;
publishFrameData.retain = false;
publishFrameData.qos = 0;
publishFrameData.payload = new Buffer("Some Message (0) with QoS0, dup: true, retain: false.");
console.log("-----------------");
console.log("Message Id:", messageId);
console.log("Message:", publishFrameData.payload.toString());
console.log("Publish0:", mqtt.generate(publishFrameData).toString("base64"));
messageId += 1;

publishFrameData.messageId = messageId;
publishFrameData.dup = false;
publishFrameData.retain = true;
publishFrameData.qos = 1;
publishFrameData.payload = new Buffer("Some Message (1) with QoS1, dup: false, retain: true.");
pubAckFrameData.messageId = messageId;
console.log("-----------------");
console.log("Message Id:", messageId);
console.log("Message:", publishFrameData.payload.toString());
console.log("Publish1:", mqtt.generate(publishFrameData).toString("base64"));
console.log("Publish1 Ack:", mqtt.generate(pubAckFrameData).toString("base64"));
messageId += 1;

publishFrameData.messageId = messageId;
publishFrameData.dup = false;
publishFrameData.retain = false;
publishFrameData.qos = 2;
publishFrameData.payload = new Buffer("Some Message (2) with QoS2, dup: false, retain: false.");
pubRecFrameData.messageId = messageId;
pubRelFrameData.messageId = messageId;
pubCompFrameData.messageId = messageId;
console.log("-----------------");
console.log("Message Id:", messageId);
console.log("Message:", publishFrameData.payload.toString());
console.log("Publish2:", mqtt.generate(publishFrameData).toString("base64"));
console.log("Publish2 Rec:", mqtt.generate(pubRecFrameData).toString("base64"));
console.log("Publish2 Rel:", mqtt.generate(pubRelFrameData).toString("base64"));
console.log("Publish2 Comp:", mqtt.generate(pubCompFrameData).toString("base64"));
messageId += 1;

publishFrameData.messageId = messageId;
publishFrameData.dup = false;
publishFrameData.retain = false;
publishFrameData.qos = 0;
publishFrameData.payload = new Buffer(triggerMessageForServerPublish);
console.log("-----------------");
console.log("Trigger Message For Server Publish");
console.log("Message Id:", messageId);
console.log("Message:", publishFrameData.payload.toString());
console.log("Trigger Message For Server Publish:", mqtt.generate(publishFrameData).toString("base64"));
messageId += 1;

publishFrameData.messageId = 101;
publishFrameData.dup = true;
publishFrameData.retain = true;
publishFrameData.qos = 0;
publishFrameData.payload = new Buffer(serverPublishedMessage);
console.log("-----------------");
console.log("Server Publish");
console.log("Message Id:", publishFrameData.messageId);
console.log("Message:", publishFrameData.payload.toString());
console.log("Server Published Message:", mqtt.generate(publishFrameData).toString("base64"));

unsubscribeFrameData.messageId = messageId;
unsubscribeAckFrameData.messageId = messageId;
console.log("-----------------");
console.log("Message Id:", messageId);
console.log("Unsubscribe MessageId", messageId, ":", mqtt.generate(unsubscribeFrameData).toString("base64"));
console.log("Unsubscribe MessageId", messageId, "Ack", ":", mqtt.generate(unsubscribeAckFrameData).toString("base64"));
messageId += 1; 

console.log("-----------------");
console.log("Disconnect:", mqtt.generate(disconnectFrameData).toString("base64"));

console.log("-----------------");