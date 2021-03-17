/*
 * Arduino Radar 360
 *
 * Designed by ZulNs @Gorontalo, 13 March 2021
 */

#include <Servo.h>

#define SERVO1_PIN 7
#define TRIG1_PIN  6
#define ECHO1_PIN  5
#define SERVO2_PIN 4
#define TRIG2_PIN  3
#define ECHO2_PIN  2

Servo servo1;
Servo servo2;

void setup() {
  Serial.begin(76800);

  pinMode(TRIG1_PIN, OUTPUT);
  pinMode(TRIG2_PIN, OUTPUT);
  servo1.attach(SERVO1_PIN);
  servo2.attach(SERVO2_PIN);

  servo1.write(0);
  servo2.write(0);
}

void loop() {
  static int16_t angle = 1;
  float distance;
  uint8_t chr;

  while (Serial.available()) {
    chr = Serial.read();
    if (chr == 'P') {
      if (angle < 180) {
        distance = getDistance(TRIG1_PIN, ECHO1_PIN);
      }
      else {
        distance = getDistance(TRIG2_PIN, ECHO2_PIN);
      }
      Serial.print(String(angle) + "," + String(distance, 2) + ";");
      ++angle;
      if (angle == 180) {
        servo1.write(0);
      }
      else if (angle == 360) {
        servo2.write(0);
        angle = 0;
      }
      else if (angle < 180) {
        servo1.write(angle);
      }
      else {
        servo2.write(angle);
      }
    }
  }
}

float getDistance(uint8_t trigPin, uint8_t echoPin) {
  uint32_t duration;
  
  digitalWrite(trigPin, LOW);
  delayMicroseconds(4);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(12);
  digitalWrite(trigPin, LOW);
  duration = pulseIn(echoPin, HIGH, 18000UL);
  if (duration == 0) {
    duration = 18000UL;
  }
  delayMicroseconds(18001UL - duration);
  return duration * 0.01715; // return in cm
}
