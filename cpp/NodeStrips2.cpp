#include <Arduino.h>
#include "RGB.h"
#include <ESP8266WiFi.h>
#include <WebSocketsServer.h>
#include <Hash.h>

WebSocketsServer webSocket = WebSocketsServer(81);

RGB led = RGB(D5, D6, D7);

int interval = 5;


void webSocketEvent(uint8_t num, WStype_t type, uint8_t * payload, size_t lenght) {
  if (type == WStype_TEXT) {

    //make the payload easier to use
    String text = String((char *) &payload[0]);

    //a way so the app can check if they are connected and get data
    if (text == "X") {
      String data = "X ";
      data +=  interval >= 10 ? String(interval, DEC) : "0" + String(interval, DEC);
      data += " ";
      data += String(led.r, HEX);
      data += " ";
      data += String(led.b, HEX);
      data += " ";
      data += String(led.g, HEX);
      data += " ";
      data += led.tick() ? "FADE" : "RGB";
      data += " ";
      data += led.on == true ? "ON" : "OFF";
      webSocket.sendTXT(num, data);
      Serial.println(data);
    }

    //turns the lights on and starts FADE mode
    if (text == "ON") {
      Serial.println("ON");
      led.start();
    }

    //turns lights off and stops FADE mode
    if (text == "OFF") {
      Serial.println("OFF");
      led.stop();
    }

    //have a set button that sets the rgb color

    //Sets fade speed
    if (text.startsWith("S")) {
      interval = dec2bin(payload, 1);
      Serial.println(interval);
    }

    //sets a color.
    if (text.startsWith("C")) {
      led.setColor(hex2bin(payload, 1), hex2bin(payload, 3), hex2bin(payload, 5));
      Serial.println(hex2bin(payload, 1));
      Serial.println(hex2bin(payload, 3));
      Serial.println(hex2bin(payload, 5));
    }

  }
}

unsigned char hex2bin(unsigned char * str, unsigned char offset) {//low level blah blah blah
  unsigned char ret = 0;
  unsigned char buf[2];
  memcpy(buf, &str[0] + offset, 2);
  ret += buf[0] <= '9' ? (buf[0] - 48) * 16 : (buf[0] - 55) * 16;
  ret += buf[1] <= '9' ? buf[1] - 48 : buf[1] - 55;
  return ret;
}

unsigned char dec2bin(unsigned char * str, unsigned char offset) {//low level blah blah blah
  unsigned char buf[2];
  memcpy(buf, &str[0] + offset, 2);
  return (buf[0] - 48) * 10 + (buf[1] - 48);
}


void setup() {
  Serial.begin(115200);
  WiFi.begin(ssid, password);
  Serial.println();
  while (WiFi.status() != WL_CONNECTED) {
    delay(100);
    Serial.print("*");
  }
  Serial.println("\n" + WiFi.localIP());
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);
  led.begin();
}

void loop() {
  webSocket.loop();
  delay(led.tick() ? pow(interval, 2) : 100);
}