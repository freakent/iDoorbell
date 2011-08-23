
#include "WiFly.h"
#include "Credentials.h"
#include "Prowl.h"

// Don't use pins 10 - 13, they are reserved for SPI interface with WiFly
const int ledPin = 9;
const int switchPin = 2;
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
  Serial.println("\niDoorbell v0.1");

  pinMode(switchPin, INPUT);
  pinMode(ledPin, OUTPUT);
  digitalWrite(ledPin, HIGH);

  WiFly.begin();

  if (!WiFly.join(ssid, passphrase)) {
    Serial.println("WiFi Association failed.");
    while (1) {
      // Hang on failure.
    }
  }  

  WiFly.configure(WIFLY_BAUD, 9600);

  prowlAdd("Initialised", "iDoorbell+Ready");  // Send a message through Prowl

  digitalWrite(ledPin, LOW);
  
}

/* 
 * Main Run Loop
 *  - check to see if bell button switch is pressed and has not been pressed recently
 *  - send Ding Dong message through Prowl and deactivate switch for a short while
 *  - Check to see if there is any HTTP server response data to print
 *  - close the open network connection if it's finished with
 */
void loop() {
  
 // Serial.print("Time: ");
 // Serial.print(activeFrom);
 // Serial.print(" - ");
 // Serial.print(millis());
  
  switchState = digitalRead(switchPin);
  if (switchState == HIGH) {
    //Serial.print(" Switch High");
    digitalWrite(ledPin, HIGH);
    if (activeFrom < millis()) {
      activeFrom = millis() + deactivationInterval;
      Serial.println("Ringing the bell");
      prowlAdd("Ding+Dong", "There+is+someone+at+the+door");
    } else {
      Serial.print("Switch Deactivated for ");
      Serial.print((activeFrom - millis()) /1000);
      Serial.println(" secs");
    }
  } else {
    //Serial.print(" Switch Low");
    digitalWrite(ledPin, LOW);
  }

  
  while (client.available()) {
    iamreading = true;
    char c = client.read();
    Serial.print(c);
    count++;
    if (count > 180) {
      count = 0;
      Serial.println();
    }
  }
  
  
  
  if (!client.connected() && iamreading) {
    iamreading = false;
    Serial.println("\nDisconnecting.");
    client.stop();
   // for(;;)
   //   ;
  }
  
  
  //delay(1000);
}

/* 
 * Send message through Prowl
 *  - open a network connection to Prowl's api server
 *  - build and send HTTP POST data
 */
void prowlAdd(String event, String description) {
  
  Serial.print("Connecting...");
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



