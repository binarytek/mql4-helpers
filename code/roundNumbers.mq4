//+------------------------------------------------------------------+
//|                                                 roundNumbers.mq4 |
//|                                                        binarytek |
//|                                     https://github.com/binarytek |
//+------------------------------------------------------------------+
#property copyright "binarytek"
#property link      "https://github.com/binarytek"
#property version   "1.00"
#property strict
#property indicator_chart_window


bool isNewBar = false;

int marketDigits = 0;
int marketRoundDigits = 0;
double ratesD1[][6];
double dailyOpen = 0;
double dailyPivot = 0;

bool isSignalBarBullish = false;
bool afterResultBar = false;
int wins = 0;
int losses = 0;

// parameters
int lastNumOfCandles = 60;
double maxWickRatio = 0.75;
string roundNumbers[7] = { "000", "500"};

//int movePriceDiff = 100;
double movePriceDiffDouble = 0.150;
int moveNumOfBars = 60;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
//--- indicator buffers mapping
   marketDigits = (int)MarketInfo(OrderSymbol(),MODE_DIGITS);
   marketRoundDigits = marketDigits - 2;
   
   Print("marketDigits ", marketDigits);
   Print("marketRoundDigits ", marketRoundDigits);
   
   // 5, 100 -> 0.00100
   // 4, 100 -> 0.0100
   // movePriceDiffDouble = TODO;
   
   Print("RN: ", findStrArrayInEl(roundNumbers, "1.6000"));
   
   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[]) {

   checkNewBar();
   
   
   if (isNewBar == false)
      return(rates_total);
      
   
   ArrayCopyRates(ratesD1, Symbol(), PERIOD_D1);
   if(ratesD1[0][1] != dailyOpen) {
      dailyOpen = ratesD1[0][1];
      dailyPivot = normalizeToMarket( (ratesD1[0][2] + ratesD1[0][3] + ratesD1[0][4]) / 3 );
      //Print("New Daily Open / Pivot: ", dailyOpen, " / ", dailyPivot);
   }
   int HH = TimeHour(Time[0]);
   int MM = TimeMinute(Time[0]);
   //Print("Time Diff: ", HH," ", MM);
   if (HH == 0 && MM <= 7)
      return(rates_total);
   
   
   // Print("New Bar ! Previous Close: ", close[1], " ", rates_total);
   
   int lastBarIndex = 1;
   //if (containsFreshRoundNumberForBar(lastBarIndex)) {
   if (containsFreshDailyOpenPivot(lastBarIndex) && isBigMove(lastBarIndex, dailyOpen)) { //  && !isWickBig(lastBarIndex)
   
      Print("Signal Bar ! ", open[lastBarIndex], " to ", close[lastBarIndex]);   
      isSignalBarBullish = isBullishBar(lastBarIndex);
      afterResultBar = true;
      
   } else if(afterResultBar){
   
      if((isBullishBar(1) != isSignalBarBullish)) {
         Print("WIN");
         wins++;
      } else {
         Print("LOSS");
         losses++;
      }
      
      Print("Wins:Losses = ", wins, ":", losses);
      afterResultBar = false;
   }
   
   return(rates_total);
  }
//+------------------------------------------------------------------+

bool containsFreshDailyOpenPivot(int barIndex) {
  if(containsDailyOpenPivotForBar(barIndex)) {
      
      int i = barIndex + 1;
      int iMax = getSmallerInt(lastNumOfCandles, ArraySize(Close));
      bool foundInHistory = false;
      
      for(; i <= iMax; i++) {
         if(containsDailyOpenPivotForBar(i)) {
            foundInHistory = true;
            break;
         }
      }
      
      if(!foundInHistory) {
         Print("DO: ", dailyOpen);
      }
      
      return !foundInHistory;
      
      /*
      if (isWickBig(barIndex)) {
         Print("BIG WICK: ", dailyOpen);
         Print("Wins:Losses = ", wins, ":", losses);
         return false;
      } else {
         return !foundInHistory;
      }
      */
  }
  else return false;
}

bool containsDailyOpenPivotForBar(int barIndex) {
   if(isPriceBetween(dailyOpen, Open[barIndex], Close[barIndex])) return true;
   //else if(isPriceBetween(dailyPivot, Open[barIndex], Close[barIndex])) return true;
   else return false;
}

bool isPriceBetween(double price, double openPrice, double closePrice) {
   if (openPrice <= price && price <= closePrice) return true;
   else if (closePrice <= price && price <= openPrice) return true;
   else return false;
}

bool isBigMove(int barIndex, double price) {
      bool foundInHistory = false;
   
      int i = barIndex + 1;
      int iMax = getSmallerInt(moveNumOfBars, ArraySize(Close));
      
      double searchedPrice = 0;
      if (isBullishBar(barIndex)) searchedPrice = price - movePriceDiffDouble;
      else searchedPrice = price + movePriceDiffDouble;
      Print("Big Move ... searchedPrice: ", searchedPrice);
      
      for(; i <= iMax; i++) {
         if(isPriceBetween(searchedPrice, Open[i], Close[i])) {
            foundInHistory = true;
            Print("Big Move: ", price);
            break;
         }
      }
      
      return foundInHistory;
}

bool containsFreshRoundNumberForBar(int barIndex) {
  string sRoundNumber = getRoundNumber(Open[barIndex], Close[barIndex]);
  if(sRoundNumber != "" && findStrArrayInEl(roundNumbers, sRoundNumber)) {
      
      int i = barIndex + 1;
      int iMax = getSmallerInt(lastNumOfCandles, ArraySize(Close));
      bool roundNumberFoundInHistory = false;
      
      for(; i <= iMax; i++) {
         if(containsRoundNumberForBar(i)) {
            roundNumberFoundInHistory = true;
            break;
         }
      }
      
      if(!roundNumberFoundInHistory) {
         Print("RN: ", StringToDouble(sRoundNumber));
         return isBigMove(barIndex, StringToDouble(sRoundNumber));
      } else {
         return false;
      }
      
      /*
      if (isWickBig(barIndex)) {
         Print("BIG WICK: ", sRoundNumber);
         Print("Wins:Losses = ", wins, ":", losses);
         return false;
      } else {
         return !roundNumberFoundInHistory;
      }
      */
  }
  else return false;
}

bool containsRoundNumberForBar(int barIndex) {
   return containsRoundNumber(Open[barIndex], Close[barIndex]);
}

bool containsRoundNumber(double openPrice, double closePrice) {  // 1.05697 1.05715
   string sRoundNumber = getRoundNumber(openPrice, closePrice);
   return sRoundNumber != "";
}

/**
 * If if finds a round number between the given prices, it returns it as a string.
 * Otherwise return the emtpy string "".
 */
string getRoundNumber(double openPrice, double closePrice) {  // 1.05697 1.05715        1.05715 1.05697 
   string result = "";
   
   // convert the doubles to strings and 
   // check if the the characters from the decimal point to the last round number are changed.
   
   string soPrice = DoubleToString(openPrice, marketDigits);
   string scPrice = DoubleToString(closePrice, marketDigits);
   
   int i = StringFind(soPrice, ".");
   
   int roundNumberDigit = -1;
   int c = i+1;
   int cMax = c + marketRoundDigits - 1;
   for(; c <= cMax; c++) {
      if(StringGetChar(soPrice, c) != StringGetChar(scPrice, c)) {
         roundNumberDigit = c;
         double higherPrice = getHigherDouble(openPrice, closePrice);
         string shigherPrice = DoubleToString(higherPrice, marketDigits);
         string sRoundNumber = StringSubstr(shigherPrice, 0, c+1);
         return DoubleToString(StringToDouble(sRoundNumber), marketDigits);
      }
   }
   
   return result;
}

bool isWickBig(int barIndex) {
   double bodySize = MathAbs(Close[barIndex] - Open[barIndex]);
   
   double wickSize = 0;
   if(isBullishBar(barIndex)) {
      wickSize = MathAbs(Close[barIndex] - High[barIndex]);
   } else {
      wickSize = MathAbs(Close[barIndex] - Low[barIndex]);
   }
   
   if (wickSize == 0) return false;
   if (bodySize == 0) return true;
   
   double wickRatio = wickSize / bodySize;
   return wickRatio >= maxWickRatio;
}


bool isBullishBar(int barIndex) {
   return (Close[barIndex] - Open[barIndex]) > 0;
}

bool isBullish(double openPrice, double closePrice) {
   return (closePrice - openPrice) > 0;
}

bool isBearish(double openPrice, double closePrice) {
   return (closePrice - openPrice) > 0;
}

void checkNewBar() {
   static datetime newTime = 0;
   isNewBar = false;
   if(newTime != Time[0]) {
     newTime = Time[0];
     isNewBar = true;
   }
}

bool findStrArrayInEl(string &strArray[], string elem) {
   int i = 0;
   int iMax = ArraySize(strArray) - 1;
   for(; i <= iMax; i++) {
      if(StringFind(elem, strArray[i]) != -1) {
         return true;
      }
   }
   return false;
}

int getSmallerInt(int one, int two) {
   if (one > two) return two;
   else return one;
}

double getHigherDouble(double one, double two) {
   if (one > two) return one;
   else return two;
}

double normalize(double price, int digits) {
   return NormalizeDouble(price, digits);
}
double normalizeToMarket(double price) {
   return NormalizeDouble(price, marketDigits);
}
double normalizeToRound(double price) {
   return NormalizeDouble(price, marketRoundDigits);
}
