/*
 * BlinkMuinoFade -- Fade up and down all BlinkM's LEDs.
 *
 * Based on the standard "Blink" Arduino example.
 * 
 * 2011 - Tod E. Kurt - http://todbot.com/blog/ - http://thingm.com/
 * 2011 - Naim Busek - adding sleep
 */
//****************************************************************

#include <avr/sleep.h>
#include <avr/wdt.h>

#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif


int nint;
volatile boolean f_wdt=1;
volatile byte state = 0x01;

const int step_cnt = 100;

// BlinkM / BlinkM MinM pins
const int redPin = 3;  // 
const int grnPin = 4;  //
const int bluPin = 1;  // will blink when programming
const int sdaPin = 0;  // 'd' pin, can be digital I/O
const int sclPin = 2;  // 'c' pin, can be digital or analog I/O

//#define REDID  0
//#define BLUEID 1
//#define GREENID 2
//#define MIN_COLOR REDID
//#define MAX_COLOR GREENID
//
//int colorID = REDID;
//
//const int ledPinCnt = 3;
//const int ledPins[ledPinCnt] = { redPin, grnPin, bluPin};


#define RED  0x01
#define BLUE 0x02
#define GREEN 0x04

// RED
// GREEN
// BLUE
// RED + GREEN
// RED + BLUE
// GREEN + BLUE
// RED + GREEN + BLUE

const int colorSeqLen = 7; 
const int colorSeq[colorSeqLen] = {
  RED, GREEN, BLUE, RED|GREEN, RED|BLUE, GREEN|BLUE, RED|GREEN|BLUE};

int colorSeqID = 0;


void setup()
{
  pinMode(redPin, OUTPUT);     
  pinMode(grnPin, OUTPUT);     
  pinMode(bluPin, OUTPUT);     

  pinMode(sdaPin, INPUT);
  pinMode(sclPin, INPUT);
  digitalWrite(sclPin, HIGH);

  // CPU Sleep Modes 
  // SM1 SM0 Sleep Mode
  // 0  0 Idle
  // 0  1 ADC Noise Reduction
  // 1  0 Power-down
  // 1  1 Reserved

  sleep_disable();                     // System continues execution here when watchdog timed out
  set_sleep_mode(SLEEP_MODE_PWR_DOWN); // sleep mode is set here
//  cbi( MCUCR,SE );     // sleep enable, power down mode
//  sbi( MCUCR,SM1 );    // power down mode
//  cbi( MCUCR,SM0 );    // power down mode

  setup_watchdog(8);
}


void loop()
{
  if (f_wdt==1) {  // wait for timed out watchdog / flag is set when a watchdog timeout occurs
    f_wdt=0;       // reset flag

    nint++;

    if (0x01 == state) {

      // fade up
      for(byte i=1; i<step_cnt; i++) {
        byte on  = i;
        byte off = step_cnt-on;
        for( byte j=0; j<step_cnt; j++ ) {
          if (RED & colorSeq[colorSeqID]) {
            digitalWrite(redPin, HIGH);
          }
          if (BLUE & colorSeq[colorSeqID]) {
            digitalWrite(bluPin, HIGH);
          }
          if (GREEN & colorSeq[colorSeqID]) {
            digitalWrite(grnPin, HIGH);
          }
          delayMicroseconds(on);
          digitalWrite(redPin, LOW);
          digitalWrite(bluPin, LOW);
          digitalWrite(grnPin, LOW);
          delayMicroseconds(off);
        }
      }
      // fade down
      for(byte i=1; i<step_cnt; i++) {
        byte on  = step_cnt-i;
        byte off = i;
        for( byte j=0; j<step_cnt; j++ ) {
          if (RED & colorSeq[colorSeqID]) {
            digitalWrite(redPin, HIGH);
          }
          if (BLUE & colorSeq[colorSeqID]) {
            digitalWrite(bluPin, HIGH);
          }
          if (GREEN & colorSeq[colorSeqID]) {
            digitalWrite(grnPin, HIGH);
          }
          delayMicroseconds(on);
          digitalWrite(redPin, LOW);
          digitalWrite(bluPin, LOW);
          digitalWrite(grnPin, LOW);
          delayMicroseconds(off);
        }
      }
      colorSeqID = (++colorSeqID)%colorSeqLen;

      if ( 0 == digitalRead(sclPin)) {
        state = 0x00;
      }
    }
    system_sleep();
  }
}


//     digitalWrite(redPin, HIGH);
//      delay(500);
//      digitalWrite(redPin, LOW);
//      delay(500);
//
//      digitalWrite(grnPin, HIGH);
//      delay(500);
//      digitalWrite(grnPin, LOW);
//      delay(500);
//
//      digitalWrite(bluPin, HIGH);
//      delay(500);
//      digitalWrite(bluPin, LOW);
//      delay(500);
//
//      delay(500);


//****************************************************************  
// set system into the sleep state 
// system wakes up when wtchdog is timed out
void system_sleep() {

  cbi(ADCSRA,ADEN);                    // switch Analog to Digitalconverter OFF

  set_sleep_mode(SLEEP_MODE_PWR_DOWN); // sleep mode is set here
  sleep_mode();                        // System sleeps here

  sbi(ADCSRA,ADEN);                    // switch Analog to Digitalconverter ON

  // TODO: enable sclPin to wake system on external interrupt and not use WDT for wake up
}


//****************************************************************
// 0=16ms, 1=32ms,2=64ms,3=128ms,4=250ms,5=500ms,
// 6=1 sec,7=2 sec, 8=4 sec, 9= 8sec
void setup_watchdog(int ii) {

  byte bb;

  if (ii > 9 ) ii=9;
  bb=ii & 7;
  if (ii > 7) bb|= (1<<5);
  bb|= (1<<WDCE);

  MCUSR &= ~(1<<WDRF);
  // start timed sequence
  WDTCR |= (1<<WDCE) | (1<<WDE);
  // set new watchdog timeout value
  WDTCR = bb;
  WDTCR |= _BV(WDIE);
}


//****************************************************************  
// Watchdog Interrupt Service / is executed when  watchdog timed out
ISR(WDT_vect) {
  f_wdt=1;  // set global flag

  if ( 0 == digitalRead(sclPin)) {
    state = 0x01;
  }
}









