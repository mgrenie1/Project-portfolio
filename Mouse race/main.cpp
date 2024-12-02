#include <Arduino.h>
#include <SPI.h>
#include <SD.h>
#include <Wire.h>
#include <MPU6050_light.h>
#include <Adafruit_Sensor.h>

// Pin Definitions
#define Right_Motor_Pin 6
#define Left_Motor_Pin 5

#define Left_Sensor_Pin A1
#define Right_Sensor_Pin A0

// Motor Calibration
#define Right_Motor_Traction_Calibration 0
#define Left_Motor_Traction_Calibration 25

#define Right_Moytor_Min_PWM_Calibration 0
#define Left_Motor_Min_PWM_Calibration 15
 
#define Right_Motor_Positive_Calibration Right_Motor_Traction_Calibration + Right_Moytor_Min_PWM_Calibration
#define Left_Motor_Positive_Calibration Left_Motor_Traction_Calibration + Left_Motor_Min_PWM_Calibration

// Motor PWM values
// #define Min_Spin_PWM 50
// #define Min_Drive_PWM 75
#define TURN_PWM 90
#define STRAIGHT_PWM 255
#define UP_DRIVE_PWM 160
#define DOWN_DRIVE_PWM 65

// PID Definitions
#define TurnKp 0.91
//0.70
#define TurnKi 0.0
#define TurnKd 2
//0.50
//0.18
#define TurnKv 0.22
//0.17

#define StraightKp 0.12
#define StraightKi 0.0
#define StraightKd 3.5
#define StraighKv 0.0

// Hill detection definitions
#define UpAngle 11
#define DownAngle -11

// Straight line detection definitions
#define SmallWiggleMinTime 500

#define MinWiggleAngleStraight 12
#define MinWiggleAngleTurn 8

int MinWiggleAngle = 5.5;


// Enums for the states
enum HillState {
  Flat,
  Up,
  Down
};

enum WiggleState {
  Small,
  Large
};

enum TurnState {
  Turns,
  Straight
};

// Hill state variables
HillState CurrentHillState = Flat;
HillState LastHillState = Flat;
bool HasBeenDown = false;
unsigned long straightTimer;

// Straight line detection variables
unsigned long timer = 0;
unsigned long LastSmallWiggleTime = 0;
bool StraightLineDetectionEnabled = true;

WiggleState CurrentWiggleState = Large;
WiggleState LastWiggleState = Large;
TurnState CurrentTurnState = Turns;

// MPU Instance
const int MPU_addr=0x68;
int16_t AcX,AcY,AcZ,Tmp,GyX,GyY,GyZ;
int minVal=265;
int maxVal=402;
double x;
double y;
double z;
double last_z;
float FlatAngleOffset;

MPU6050 mpu(Wire);

// PID variables
double Setpoint = 0.0;
double Error = 0.0;
double ErrorSum = 0.0;
double ErrorSumThreadhold = 0.0;
double Target_Differential = 0.0;
double Last_Error = 0.0;
double SystemGain = 1;

// Motor variables
uint8_t DrivePWM = TURN_PWM;


// PID Variables
float Kp = TurnKp;
float Ki = TurnKi;
float Kd = TurnKd;
float Kv = TurnKv;

void setup() {
  Serial.begin(9600);

  // Pin setup
  pinMode(Right_Motor_Pin, OUTPUT);
  pinMode(Left_Motor_Pin, OUTPUT);
  pinMode(Left_Sensor_Pin, INPUT);
  pinMode(Right_Sensor_Pin, INPUT);

  // Set motor speed to 0 on startup
  analogWrite(Right_Motor_Pin, 0);
  analogWrite(Left_Motor_Pin, 0);

  // MPU setup
  Wire.begin();
  mpu.begin();
  mpu.calcGyroOffsets(); 
  mpu.setFilterAccCoef(1);
  mpu.setFilterGyroCoef(1);

  delay(20);
  FlatAngleOffset = mpu.getAngleY();

    // Set motor speed to 0 on startup
  // analogWrite(Right_Motor_Pin, 200);
  // analogWrite(Left_Motor_Pin, 240);

  // delay(200);


  straightTimer = millis();

}


void loop() {

  /// SENSOR PROCESSING ///

  // Read the sensor values
  int Left_Sensor_Value = analogRead(Left_Sensor_Pin);
  int Right_Sensor_Value = analogRead(Right_Sensor_Pin);

  mpu.update(); 
  y = mpu.getAngleY(); 
  z = mpu.getAngleZ();


  // STATE DETECTION //

  // Check if the mouse is on a hill
  LastHillState = CurrentHillState;
 
  if ((y > FlatAngleOffset + UpAngle)){
    CurrentHillState = Up;
    MinWiggleAngle = 2;
  } else if (y < FlatAngleOffset + DownAngle){
    CurrentHillState = Down;
  } else {
    CurrentHillState = Flat;
  }


  // Set the drive PWM based on the state
  if (CurrentHillState == Up){
    DrivePWM = UP_DRIVE_PWM;
  } else if (CurrentHillState == Down){
    DrivePWM = DOWN_DRIVE_PWM;
  } else if (CurrentHillState == Flat){


    // Set appropriate drive PWM based on the turn state
    if (CurrentTurnState == Turns){
      DrivePWM = TURN_PWM;
    } else {
      DrivePWM = STRAIGHT_PWM;
    }

  }


  // Straight Line Detection
  if (millis() - timer > 100){
    timer = millis();
    double z_diff = z - last_z;
    last_z = z;
    
    // Check if the difference is big
    LastWiggleState = CurrentWiggleState;
    if (abs(z_diff) > MinWiggleAngle){
      CurrentWiggleState = Large;
    } else {
      CurrentWiggleState = Small;
    }

    // If the last wiggle state was large and the current wiggle state is small start timer
    if (CurrentWiggleState == Large){
      LastSmallWiggleTime = millis();
    } else if (LastWiggleState == Large && CurrentWiggleState == Small){
      LastSmallWiggleTime = millis();
    } else if (CurrentHillState != LastHillState){
      LastSmallWiggleTime = millis();
    } else if (CurrentHillState == Up || CurrentHillState == Down){
      LastSmallWiggleTime = millis();
    }

    if (StraightLineDetectionEnabled && (millis() - straightTimer) > 10000){
      // If the last small wiggle time is more than 2s gas it
      if ((millis() - LastSmallWiggleTime) > SmallWiggleMinTime){
        CurrentTurnState = Straight;
        //MinWiggleAngle = MinWiggleAngleStraight;
      } else {
        CurrentTurnState = Turns;
        //MinWiggleAngle = MinWiggleAngleTurn;
      }

    } else {
      CurrentTurnState = Turns;
    }
  }

  // Adjusting PID values based on the turn state
  if (CurrentTurnState == Turns){
    Kp = TurnKp;
    Ki = TurnKi;
    Kd = TurnKd;
    Kv = TurnKv;
  } else {
    Kp = StraightKp;
    Ki = StraightKi;
    Kd = StraightKd;
    Kv = StraighKv;
  }



  ///// PID CALCS /////

  // Calculate the error and cast it to a double
  Error = (double)Right_Sensor_Value - (double)Left_Sensor_Value;

  ErrorSum += Error;

  // Calculate the PID values
  double P = Kp * Error;
  double I = Ki * ErrorSum;
  double D = Kd * (Error - Last_Error);

  Target_Differential =  SystemGain * (P + I + D);
  double V = Kv * abs(Target_Differential);

  // Update the last error
  Last_Error = Error;

  // Calculate the motor speeds
  double Left_Motor_Speed = DrivePWM + Left_Motor_Positive_Calibration + Target_Differential/2.0 - V;
  double Right_Motor_Speed = DrivePWM + Right_Motor_Positive_Calibration - Target_Differential/2.0 - V;


  /// MOTOR LOGIC ///

  // Check if bellow 0 and set to 0 and adjust the other motor
  if (Left_Motor_Speed < 0){
    double diff = abs(Left_Motor_Speed);
    Right_Motor_Speed += diff;
  } else if (Left_Motor_Speed > 255){
    double diff = Left_Motor_Speed - 255;
    Right_Motor_Speed -= diff;
  }

  if (Right_Motor_Speed < 0){
    double diff = abs(Right_Motor_Speed);
    Left_Motor_Speed += diff;
  } else if (Right_Motor_Speed > 255){
    double diff = Right_Motor_Speed - 255;
    Left_Motor_Speed -= diff;
  }

  if (Left_Motor_Speed < 0){
    Left_Motor_Speed = 0;
  } else if (Left_Motor_Speed > 255){
    Left_Motor_Speed = 255;
  }

  if (Right_Motor_Speed < 0){
    Right_Motor_Speed = 0;
  } else if (Right_Motor_Speed > 255){
    Right_Motor_Speed = 255;
  }

  // Set the motor speeds
  analogWrite(Left_Motor_Pin, Left_Motor_Speed);
  analogWrite(Right_Motor_Pin, Right_Motor_Speed);

  // Serial.print("Left Motor Speed: ");
  // Serial.print(Left_Motor_Speed);
  // Serial.print("Right Motor Speed: ");
  // Serial.println(Right_Motor_Speed);
  delay(1.0);
  // Serial.print("Left Sensor Value: ");
  // Serial.print(Left_Sensor_Value);
  // Serial.print(" Right Sensor Value: ");
  // Serial.println(Right_Sensor_Value);

  //Serial.println(CurrentTurnState);

}