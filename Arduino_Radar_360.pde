/*
 * Arduino Radar 360
 *
 * Designed by ZulNs @Gorontalo, 13 March 2021
 */

import processing.serial.*; // To enable accessing serial port
import processing.sound.*; // To sound alarm by using triangle oscillator
import static javax.swing.JOptionPane.*; // Required by showMessageDialog() or showInputDialog()

static final String APP_TITLE     = "Arduino Radar 360";
static final String VALIDITY_CODE = "88CAE6D2CEDCCAC840C4F240B4EAD89CE640808EDEE4DEDCE8C2D8DE58406266409AC2E4C6D04064606462";
static final float  MAX_DISTANCE  = 308.7;
static final int    BAUD_RATE     = 76800;

Serial serialPort;
TriOsc alarm;

String  serialData     = "";
String  bannerText     = "";
float[] distances;
float   distance = MAX_DISTANCE;
float   lastDistance = MAX_DISTANCE;
float   rxDistance;
float   radius;
float   centerX;
float   centerY;
int     angle = 0;
int     lastAngle = 0;
int     rxAngle;
int     bannerPos;
int     minBannerPos;
int     alarmStartTime;
int     lastReceivedTime;
int     tailScanner = 0;
boolean isAlarming = false;
boolean hasReceived = false;

void setup() {
  String portName = "";
  int i, cd;
  
  if (Serial.list().length > 0) {
    portName = Serial.list()[0];
    try {
      serialPort = new Serial(this, portName, BAUD_RATE);
    }
    catch(Exception e) {
      showMessageDialog(null, "Error opening serial port '" + portName + "' (port busy).\nExiting...", APP_TITLE, ERROR_MESSAGE);
      exit();
    }
  }
  else {
    showMessageDialog(null, "There's no serial port available.\nExiting...", APP_TITLE, WARNING_MESSAGE);
    exit();
  }
  
  size(1366, 720);
  
  distances = new float[360];
  for (i = 0; i < distances.length; ++i) {
    distances[i] = MAX_DISTANCE;
  }
  
  radius = (height < width) ? height : width;
  radius = radius*0.88/2;
  centerX = width/2;
  centerY = height/2;
  bannerPos = width;
  alarm = new TriOsc(this);
  
  for (i = 0; i < VALIDITY_CODE.length(); i+=2) {
    cd = Integer.parseInt(VALIDITY_CODE.substring(i, i+2), 16);
    cd = cd + 256*(cd&1);
    cd >>= 1;
    bannerText += String.valueOf((char)cd);
  }
  
  textSize(20);
  minBannerPos = -(int)textWidth(bannerText);
  
  if (serialPort != null) {
    delay(2000); // Waits for Arduino to reboot since serial port activated.
    serialPort.write('P'); // Sends a request to Arduino to start scanning object distances.
  }
}

void draw() {
  float r;
  int i;
  int deg;
  
  background(32);
  translate(centerX, centerY);
  
  // Draws radar
  noFill();
  strokeWeight(2);
  stroke(64, 128, 255);
  for (i = 1; i <= 3; ++i) {
    circle(0, 0, i*200/MAX_DISTANCE*radius);
  }
  line(-radius*1.05, 0, radius*1.05, 0);
  line(0, -radius*1.05, 0, radius*1.05);
  
  // Draws radar's scanner
  strokeWeight(2);
  for (i = 0; i < tailScanner; ++i) {
    deg = getDegree(angle-i);
    r = radius*distances[deg]/MAX_DISTANCE;
    stroke(128-i*3.31, 255-i*7.69, 255-i*7.69);
    line(0, 0, r*sin(radians(deg)), -r*cos(radians(deg)));
  }
  
  // Draws detected obstacles
  strokeWeight(1);
  stroke(255, 64, 64);
  fill(255, 32, 64);
  for (i = 0; i < 360; ++i) {
    if (distances[i] < MAX_DISTANCE) {
      r = radius*distances[i]/MAX_DISTANCE;
      circle(r*sin(radians(i)), -r*cos(radians(i)), 2);
    }
  }
  
  // Starts alarm sound
  if (distance < MAX_DISTANCE) {
    lastDistance = distance;
    lastAngle = angle;
    if (hasReceived && !isAlarming) {
      alarm.play(1000, 1.0);
      alarmStartTime = millis();
      isAlarming = true;
    }
  }
  
  // Stops alarm sound
  if (isAlarming && millis()-alarmStartTime >= 100) {
    alarm.stop();
  }
  
  // Disables alarm sound
  if (isAlarming && millis()-alarmStartTime >= 1000) {
    isAlarming = false;
  }
  
  // Sets displayed distance to '~'
  if (angle == lastAngle && distance == MAX_DISTANCE) {
    lastDistance = MAX_DISTANCE;
  }
  
  translate(-centerX, -centerY);
  
  // Displays the distance between the current cursor position and the sensor (center point) when it is within the radar coverage area.
  fill(255);
  textSize(20);
  r = sqrt(sq(abs(centerX-mouseX)) + sq(abs(centerY-mouseY)));
  if (r < radius) {
    text(String.format("%.1f cm", r*308.7/radius), mouseX-20, mouseY-20);
  }
  
  // Displays radar's info
  textSize(32);
  text("Angle: " + String.valueOf(angle) + "°", 20, 52);
  if (lastDistance < MAX_DISTANCE) {
    text("Distance: " + String.valueOf(lastDistance) + " cm", 20, 104);
  }
  else {
    text("Distance: ~", 20, 104);
  }
  
  // Displays about
  textSize(20);
  text(bannerText, bannerPos, height-20);
  --bannerPos;
  if (bannerPos < minBannerPos) {
    bannerPos = width;
  }
  
  if (hasReceived) {
    if (millis()-lastReceivedTime >= 30) {
      hasReceived = false;
    }
    else {
      if (tailScanner <= 30) {
        tailScanner = angle;
      }
    }
  }
  else {
    if (tailScanner > 0) {
      --tailScanner;
    }
  }
}

void serialEvent(Serial ser) {
  int chr = ser.read();
  
  if (chr == ',') {
    if (serialData.length() > 0) {
      rxAngle = int(serialData);
      serialData = "";
    }
  }
  else if (chr == ';') {
    if (serialData.length() > 0) {
      rxDistance = float(serialData);
      serialData = "";
    }
    if (0 <= rxAngle && rxAngle < 360 && 0.0 <= rxDistance && rxDistance <= MAX_DISTANCE) {
      angle = rxAngle;
      distance = rxDistance;
      distances[angle] = distance;
      lastReceivedTime = millis();
      hasReceived = true;
    }
    else {
      rxAngle = -1;
      rxDistance = -1.0;
    }
    ser.write('P'); // Resends request to Arduino to advance scanning angle.
  }
  else {
    serialData += Character.toString((char)chr);
  }
}

int getDegree(int angle) {
  angle = angle%360;
  return (angle < 0) ? 360+angle : angle;
}
