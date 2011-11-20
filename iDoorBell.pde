
#include "WiFly.h"
#include "Credentials.h"
#include "Prowl.h"

// Don't use pins 10 - 13, they are reserved for SPI interface with WiFly
const int rledPin = 3;
const int gledPin = 4;
const int switchPin = 5;
int switchState = 0;
unsigned long activeFrom = 0;
boolean iamreading = false;
int count = 0;

Client client(server, port); // Initialise the WiFly Client

/* 
 * Initialise the Arduino
 *  - set up the I/O pins
 *  - connect to the Wifi
 *  - send an initialised message through Prowl
 */
void setup() {
  
  Serial.begin(115200);
  Serial.println("\niDoorbell v0.2");

  pinMode(switchPin, INPUT);
  pinMode(gledPin, OUTPUT);
  pinMode(rledPin, OUTPUT);
  digitalWrite(gledPin, HIGH);
  digitalWrite(rledPin, HIGH);

  connectToWifi();
  
  prowlAdd("Initialised", "iDoorbell+Ready");  // Send a message through Prowl

  digitalWrite(gledPin, LOW);
  digitalWrite(rledPin, LOW);
  
}

/* 
 * Main Run Loop
 *  - check to see if bell button switch is pressed and has not been pressed recently
 *  - send Ding Dong message through Prowl and deactivate switch for a short while
 *  - Check to see if there is any HTTP server response data to print
 *  - close the open network connection if it's finished with
 *  - If it's less than 30 secs since the button was last pressed, switch red led on
 */
void loop() {
  
  // Serial.print("Time: ");
  // Serial.print(activeFrom);
  // Serial.print(" - ");
  // Serial.print(millis());
 
  // When button pressed and it hasn't been deactivated by an earlier press, 
  // send a notification through Prowl
  switchState = digitalRead(switchPin);
  if (switchState == HIGH) {
    if (activeFrom < millis()) {
      digitalWrite(gledPin, HIGH);
      activeFrom = millis() + deactivationInterval;
      Serial.println("Ringing the bell");
      prowlAdd("Ding+Dong", "There+is+someone+at+the+door");
    } else {
      Serial.print("Switch Deactivated for ");
      Serial.print((activeFrom - millis()) /1000);
      Serial.println(" secs");
    }
  }

  // Check to see if there is any HTTP server response data to print
  while (client.available()) {
    iamreading = true;
    char c = client.read();
    Serial.print(c);
    
    // Handle line end and break long lines > 80 chars 
    // just to make them easier to read
    if (c == 10) { // carriage return
      count = 0;
    } else {
      count++;
    }
    if (count > 80) {
      count = 0;
      Serial.println();
    }
  }
  
  
  // close the open network connection if it's finished with
  if (!client.connected() && iamreading) {
    iamreading = false;
    Serial.println("\nDisconnecting.");
    client.flush();
    client.stop();
    digitalWrite(gledPin, LOW);
  }
  

  // If it's less than 30 secs since the button was last pressed, 
  // switch red led on
  if (activeFrom < millis()) {
      digitalWrite(rledPin, LOW);
  } else {
      digitalWrite(rledPin, HIGH);
  }
    
  
}

/* 
 * Initialise and connect to the Wifi access point
 */
void connectToWifi() {
  WiFly.begin();

  if (!WiFly.join(ssid, passphrase)) {
    Serial.println("WiFi Association failed.");
    while (1) {
      // Hang on failure.
    }
  }  

  WiFly.configure(WIFLY_BAUD, 38400);  
  
}

/* 
 * Send message through Prowl
 *  - open a network connection to Prowl's api server
 *  - build and send HTTP POST data to Prowl's Add api
 */
void prowlAdd(String event, String description) {
  
  Serial.print("Connecting to Prowl...");
  if (client.connect()) {

    Serial.println("connected");

    int contentLength = fixedContentLength + event.length() + description.length();
  
    Serial.println("Posting event " + event + " (" + String(contentLength) + " bytes)");
  
    client.print("POST ");
    client.print(path); 
    client.println(" HTTP/1.0");
  
    client.print("Host: ");
    client.println(server); // Important for HTTP/1.1 server, even though we decalre HTTP/1.0 
  
    client.println("User-Agent: Arduino-WiFly/1.0");
  
    client.println("Content-Type: application/x-www-form-urlencoded");
  
    client.print("Content-Length: ");
    client.println(contentLength);
  
    client.println(); // Important blank line between HTTP headers and body
  
    client.print(apikeyParam);
    client.print(apikey);
  
    client.print(applicationParam);
    client.print(application);
  
    client.print(eventParam);
    client.print(event);
  
    client.print(descriptionParam);
    client.println(description);
 
  } else {

    Serial.println("connection failed");

  }

}



