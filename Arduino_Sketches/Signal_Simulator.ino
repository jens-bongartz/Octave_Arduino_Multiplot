
#include <TimerOne.h>

int faADC  = 200;
int ampl1 = 100;
int ampl2 = 5;
int f1 = 2; 
int f2 = 50;

const float pi = 3.14159;

// Analoge Eingänge
int adcChannel = 0; // A0
long t_alt = 0;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  Timer1.initialize(1000000/faADC);             
  Timer1.attachInterrupt(readADC);                             
}

void loop() {
}

void readADC() {
  float t = millis();
  float s1 = ampl1*cos(2*pi*f1*(t/1000));
  float s2 = ampl2*cos(2*pi*f2*(t/1000));  
  int simValue = round (s1 + s2);
  int dt = t - t_alt;
  t_alt = t;
  Serial.print("SIM:");
  Serial.print(simValue);
  Serial.print(",dt:");
  Serial.println(dt);
}

void serialEvent() {
  char inChar = Serial.read();
  if (inChar == 's') {   // 's'top
    Timer1.stop();
  }
  if (inChar == 't') {   //  restar't'
    Timer1.restart();
  }
}
