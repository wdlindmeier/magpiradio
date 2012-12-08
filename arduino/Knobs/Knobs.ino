//#include <Encoder.h>

#define LED_R  9
#define LED_G  10
#define LED_B  11

#define POT_L  A1

//these pins can not be changed 2/3 are special pins
#define ENCODER_1 2
#define ENCODER_2 3
#define ENCODER_SX 4 //push button switch

enum {
  TokenIdxLastChannelVal = 0,
  TokenIdxNumChannels,
  NumTokenIdxs
};

const long MIN_KNOB = 0;
const long MAX_KNOB = 1023;

// Rotary encoder values
volatile int lastEncoded = 0;
volatile long encoderValue = 0;
volatile long lastEncoderValue = -999999;

int lastMSB = 0;
int lastLSB = 0;
int buttonPushed = 0;
int numChannels = 0;

boolean didReceiveOpeningPacket = false;
long configFrames = 0;
long favFrames = 0;
// NOTE: Just eyeballing this to get about 2 pulses. It may have to change if more code is added to readSensors()
const long NumFavFramesPulse = 120;

// the setup routine runs once when you press reset:
void setup() {

  Serial.begin(9600);  
  Serial.flush();
  
  pinMode(LED_R, OUTPUT);
  pinMode(LED_G, OUTPUT);
  pinMode(LED_B, OUTPUT);

  pinMode(POT_L, INPUT);
  
  // Encoder
  pinMode(ENCODER_1, INPUT); 
  pinMode(ENCODER_2, INPUT);
  pinMode(ENCODER_SX, INPUT);
  digitalWrite(ENCODER_1, HIGH); //turn pullup resistor on
  digitalWrite(ENCODER_2, HIGH); //turn pullup resistor on
  digitalWrite(ENCODER_SX, HIGH); //turn pullup resistor on

  //call updateEncoder() when any high/low changed seen
  //on interrupt 0 (pin 2), or interrupt 1 (pin 3) 
  attachInterrupt(0, updateEncoder, CHANGE); 
  attachInterrupt(1, updateEncoder, CHANGE);

}

void loop() 
{  
  if(didReceiveOpeningPacket){
    readSensors();    
  }else{    
    readSerial();    
  }  
}

void readSerial()
{
  
  if(Serial.available()){
     
     int MAX_CHAR = 100;
     char readVal[MAX_CHAR];
     int numChar = Serial.readBytesUntil('\n', readVal, MAX_CHAR);
     String inVal = String(readVal).substring(0, numChar);
     
     if(inVal.indexOf(',') != -1){ // Intial setup
     
        char tokens[numChar];
        inVal.toCharArray(tokens, numChar);      
        char *token;
        char *ts=tokens;
        int tkIdx=0;
        int tokInts[NumTokenIdxs];
        while ((token = strtok_r(ts, ",", &ts)) != NULL){
          if(tkIdx<NumTokenIdxs){
            // Turn the tokens into numbers
            tokInts[tkIdx] = atol(token);
          }
          tkIdx++;
        }

        int lastChannelVal = tokInts[TokenIdxLastChannelVal];
        encoderValue = lastChannelVal;
        numChannels = tokInts[TokenIdxNumChannels];

     }
           
     didReceiveOpeningPacket = true;
     
  }else{
    
    if(configFrames % 1000 == 0){
      Serial.println("?");
    }
    
  }
  
  // Blink the green light until the arduino has serial communication with the pi
  configFrames = (configFrames+1) % 60000;
  int ledVal = ((1.0 + cos(configFrames*0.001)) * 0.5) * 100;
  analogWrite(LED_G, ledVal);
    
}

void throb()
{
    favFrames = (favFrames+1) % NumFavFramesPulse;
    int ledVal = ((1.0 + cos(favFrames*0.1)) * 0.5) * 100;
    analogWrite(LED_R, ledVal);
    analogWrite(LED_G, 0);
    analogWrite(LED_B, 0);
}

void readSensors()
{
  
  if(digitalRead(ENCODER_SX) == LOW){
    buttonPushed = 1; 
  }else{
    buttonPushed = 0;
  }
  
  boolean throbbing = false;
  if(buttonPushed == 1 && favFrames == 0){  
    throbbing = true;
  }else if(favFrames > 0 && favFrames < NumFavFramesPulse){
    throbbing = true;
  }else{
    favFrames = 0;
  }
  
  int potL = analogRead(POT_L);

  // Invert the value, because we want volume 0 to be far left
  int volumeVal = MAX_KNOB - potL;
    
  // NOTE: This encoder seems to "click" around every 4 steps
  long encoderClickVal = encoderValue / 4;
  long channelValue = abs(encoderClickVal % numChannels);

  Serial.print(volumeVal);
  Serial.print(",");
  Serial.print(channelValue);
  Serial.print(",");
  Serial.println(buttonPushed);

  if(throbbing){

    throb();
    
  }else{

    if(channelValue == 0){
      
      analogWrite(LED_R, 0);
      analogWrite(LED_G, 0);
      analogWrite(LED_B, 0);
      
    }else{
      
      // Convert the channel progress into RGB.
      // Lovely.
      float rf,gf,bf;
      float scalarChannel = (float)(channelValue-1) / (float)(numChannels-1);
      int h = round(360.0 * scalarChannel);
      HSVtoRGB(&rf,&gf,&bf,h,1.0,0.5);
      int r = rf*255; 
      int g = gf*255; 
      int b = bf*255;
      
      analogWrite(LED_R, r);
      analogWrite(LED_G, g);
      analogWrite(LED_B, b);
      
    }
    
    delay(50);        // delay in between reads for stability
    
  }
  
}

void updateEncoder()
{
  
  int MSB = digitalRead(ENCODER_1); //MSB = most significant bit
  int LSB = digitalRead(ENCODER_2); //LSB = least significant bit

  int encoded = (MSB << 1) |LSB; //converting the 2 pin value to single number
  int sum  = (lastEncoded << 2) | encoded; //adding it to the previous encoded value

  if(sum == 0b1101 || sum == 0b0100 || sum == 0b0010 || sum == 0b1011) encoderValue ++;
  if(sum == 0b1110 || sum == 0b0111 || sum == 0b0001 || sum == 0b1000) encoderValue --;
  
  lastEncoded = encoded; //store this value for next time
  
}

void HSVtoRGB( float *r, float *g, float *b, float h, float s, float v )
{
	int i;
	float f, p, q, t;
	if( s == 0 ) {
		// achromatic (grey)
		*r = *g = *b = v;
		return;
	}
	h /= 60;			// sector 0 to 5
	i = floor( h );
	f = h - i;			// factorial part of h
	p = v * ( 1 - s );
	q = v * ( 1 - s * f );
	t = v * ( 1 - s * ( 1 - f ) );
	switch( i ) {
		case 0:
			*r = v;
			*g = t;
			*b = p;
			break;
		case 1:
			*r = q;
			*g = v;
			*b = p;
			break;
		case 2:
			*r = p;
			*g = v;
			*b = t;
			break;
		case 3:
			*r = p;
			*g = q;
			*b = v;
			break;
		case 4:
			*r = t;
			*g = p;
			*b = v;
			break;
		default:		// case 5:
			*r = v;
			*g = p;
			*b = q;
			break;
	}
}
