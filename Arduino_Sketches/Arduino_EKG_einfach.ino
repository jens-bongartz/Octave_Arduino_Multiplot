int adcChannel = 0; // A0
long t_alt = 0;

void setup() {
  // put your setup code here, to run once:
  Serial.begin(115200);
}

void loop() {
  // put your main code here, to run repeatedly:
  int adcValue = analogRead(adcChannel);
  int t = millis() - t_alt;
  t_alt = millis();
  Serial.print("EKG:");
  Serial.print(adcValue);
  Serial.print(",t:");
  Serial.println(t);
  delay(5);
}
