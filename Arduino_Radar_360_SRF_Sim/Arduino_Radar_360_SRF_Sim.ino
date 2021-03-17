/*
 * Arduino Radar 360
 * 
 * Arduino's sketch to simulate measurement of object diatances.
 * 
 * Designed by ZulNs @Gorontalo, 13 March 2021
 */

void setup() {
  Serial.begin(76800);
  
  randomSeed(analogRead(0));
}

void loop() {
  static int16_t angle = 0;
  static uint16_t randomAngle;
  static uint8_t  randomLength;
  static float randomDistance;
  float distance;
  uint8_t chr;
  
  while (Serial.available()) {
    chr = Serial.read();
    if (chr == 'P') {
      if (angle == 0) {
        randomAngle = random(0, 360);
        randomLength = random(1, 360);
        randomDistance = random(1, 309);
      }
      if (randomAngle <= angle && angle < randomAngle+randomLength) {
        distance = randomDistance;
      }
      else if (randomAngle+randomLength > 360 && angle < (randomAngle+randomLength)%360) {
        distance = randomDistance;
      }
      else {
        distance = 308.7;
      }
      delay(20);
      Serial.print(String(angle) + "," + String(distance, 2) + ";");
      ++angle;
      if (angle == 360) {
        angle = 0;
      }
    }
  }
}
