#include <WiFiNINA.h>
#include <ArduinoJson.h>

//const int loop_rate = 1; // [mS]
const int sensor_thr = 500;

// trigger cable configuration
const int num_trigger_pin = 8; // num of trigger pins connected to the arduino board
const int trigger_bit_1 = 2;
const int trigger_bit_2 = 3;
const int trigger_bit_3 = 4;
const int trigger_bit_4 = 5;
const int trigger_bit_5 = 6;
const int trigger_bit_6 = 7;
const int trigger_bit_7 = 8;
const int trigger_bit_8 = 9;
int *trigger_ids = (int *) malloc(sizeof(int) * num_trigger_pin); // id for the trigger pins
const int trigger_values_onset[1][8] = { // values for the trigger onset
  {1,0,0,0,0,0,0,0}, // 1 => button
};
const int trigger_values_offset[1][8] = { // values for the trigger onset
  {1,1,0,1,0,0,0,0}, // 11 => button
};
bool trigger_activated = false; // indicate if the trigger was sent

const int sensor_pin = A0; // base

// buil-in led pin colors
const int uno_rev2_led_R = 26; // RED
const int uno_rev2_led_G = 25; // GREEN
const int uno_rev2_led_B = 27; // BLUE

bool sensor_activated = false; // indicate if the sensor is open or close
bool led_on = false; // indicate whether the led for trigger debugging is on

// Json conf for communication with ROS-Neuro
const int json_capacity = JSON_OBJECT_SIZE(3);
StaticJsonDocument<json_capacity> json_sensors;

void setup() {
  Serial.begin(9600);
  WiFiDrv::pinMode(uno_rev2_led_R, OUTPUT);  // RED
  WiFiDrv::pinMode(uno_rev2_led_G, OUTPUT);  // GREEN
  WiFiDrv::pinMode(uno_rev2_led_B, OUTPUT);  // BLUE
  WiFiDrv::digitalWrite(uno_rev2_led_G, LOW);
  led_on = false;

  pinMode(sensor_pin, INPUT);
  const int sensor_value = analogRead(sensor_pin);

  if(sensor_value < sensor_thr){
    sensor_activated = true;
  }
  else {
    sensor_activated = false;
  }
  
  // setup trigger
  trigger_ids[0] = trigger_bit_1;
  trigger_ids[1] = trigger_bit_2;
  trigger_ids[2] = trigger_bit_3;
  trigger_ids[3] = trigger_bit_4;
  trigger_ids[4] = trigger_bit_5;
  trigger_ids[5] = trigger_bit_6;
  trigger_ids[6] = trigger_bit_7;
  trigger_ids[7] = trigger_bit_8;

  for(int t=0; t < num_trigger_pin; t++){
    pinMode(trigger_ids[t], OUTPUT);
    digitalWrite(trigger_ids[t], LOW); // initialize to LOW
  }
}

void loop() { 
  if(trigger_activated){
    // reset the trigger
    trigger_activated = false;

    for(int t=0; t < num_trigger_pin; t++){
      digitalWrite(trigger_ids[t], LOW); // initialize to LOW
    }
  }
  
  const int sensor_value = analogRead(sensor_pin);

  //Serial.println(sensor_value);

  if(sensor_value < sensor_thr && sensor_activated == false){ // object onset
    sensor_activated = true;
      
    // send the trigger (software)
    json_sensors["switch"] = 1;
    json_sensors["onset"] = 1;
    json_sensors["offset"] = 0;

    String output = "";
    serializeJson(json_sensors, output);
    Serial.println(output);

    // send the trigger (hardware)
    trigger_activated = true;
    
    for(int t=0; t < num_trigger_pin; t++){
      if(trigger_values_onset[0][t] == 1){
        digitalWrite(trigger_ids[t], HIGH);
      }
      else {
        digitalWrite(trigger_ids[t], LOW);
      }
    }

    // turn the LED on/off for visual debugging
    digitalWrite(LED_BUILTIN, HIGH);  
    
    if(led_on){
      WiFiDrv::digitalWrite(uno_rev2_led_R, LOW);
      led_on = false;
    }
    else {
      WiFiDrv::digitalWrite(uno_rev2_led_R, HIGH);
      led_on = true;
    }
  }
  else if(sensor_value > sensor_thr && sensor_activated == true){ // object offset
    sensor_activated = false;

    // send the trigger (software)
    json_sensors["switch"] = 1;
    json_sensors["onset"] = 0;
    json_sensors["offset"] = 1;

    String output = "";
    serializeJson(json_sensors, output);
    Serial.println(output);

    // turn the LED on/off for visual debugging
    digitalWrite(LED_BUILTIN, LOW);  
    
    if(led_on){
      WiFiDrv::digitalWrite(uno_rev2_led_R, LOW);
      led_on = false;
    }
    else {
      WiFiDrv::digitalWrite(uno_rev2_led_R, HIGH);
      led_on = true;
    }
  }
  
  //delay(loop_rate);
}
