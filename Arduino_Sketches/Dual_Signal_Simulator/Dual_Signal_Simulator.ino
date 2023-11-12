#include <TimerTwo.h>
#include <StandardTypes.h>
#include <TimerOne.h>


int faADC  = 200;
int faADC2 = 50;

int ampl1 = 100;
int ampl2 = 10;
int f1 = 20; 
int f2 = 5;

const float pi = 3.14159;

// Analoge Eingänge
int adcChannel = 0; // A0
long t_alt = 0;
long t_alt2 = 0;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
  Timer1.initialize(1000000/faADC2);             
  Timer1.attachInterrupt(signal2);                                                       
  Timer2.init(1000000/faADC, signal1);
  Timer2.start();                                                                    
}

void loop() {
}

void signal1() {
  float t = millis();
  float s1 = ampl1*cos(2*pi*f1*(t/1000));
  int simValue = s1;
  int dt = t - t_alt;
  t_alt = t;
  Serial.print("SIM:");
  Serial.print(simValue);
  Serial.print(",t:");
  Serial.println(dt);
}

void signal2() {
  float t = millis();
  float s2 = ampl2*cos(2*pi*f2*(t/1000));  
  int simValue = s2;
  int dt = t - t_alt2;
  t_alt2 = t;
  Serial.print("SIG2:");
  Serial.print(simValue);
  Serial.print(",t:");
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
