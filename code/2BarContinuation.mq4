//+------------------------------------------------------------------+
//| @File: 2BarContinuation.mq4                                      |
//| @Strategy Author: neddihrehat                                    |
//| @Code Author: binarytek                                          |
//| @Code: https://github.com/binarytek                              |
//| @License: MIT                                                    |
//| @See:  binaryoptionsedge.com/topic/1835-nedds-2-bar-continution/ |
//+------------------------------------------------------------------+
#property copyright "binarytek"
#property link      "https://github.com/binarytek"
#property version   "0.01"
#property strict
#property indicator_chart_window


//+------------------------------------------------------------------+
//| Indicator - EXTERN VARS                                          |
//+------------------------------------------------------------------+
int lwMASmallPeriod = 35;
int lwMABigPeriod = 100;

int howManyBarsInHistoryToCheck = 20000; // 


//+------------------------------------------------------------------+
//| Indicator - VARS                                                 |
//+------------------------------------------------------------------+
int count = 0;
double lwMASmall;
double lwMABig;

string arrowObjectName = "2bar";

//+------------------------------------------------------------------+
//| COMMON LIB - VARS                                                |
//+------------------------------------------------------------------+
bool isNewBar = false;
int marketDigits = 0;

enum TREND {
 TREND_UP,
 TREND_DOWN,
 TREND_NONE
};

enum SIGNAL {
 SIGNAL_CALL,
 SIGNAL_PUT,
 SIGNAL_NONE
};

//+------------------------------------------------------------------+
//| CANDLES LIB - VARS                                               |
//+------------------------------------------------------------------+
double hammerSmallWickRatio = 1;
double hammerBigWickRatio = 2;


//+------------------------------------------------------------------+
//| LINES LIB - VARS                                                 |
//+------------------------------------------------------------------+
double dailyOpen = 0;
double ratesD1[][6];
int ratesD1Counter = 0;


//+------------------------------------------------------------------+
//| Indicator - FUNCTIONS                                            |
//+------------------------------------------------------------------+

int OnInit() {
   marketDigits = (int)MarketInfo(OrderSymbol(),MODE_DIGITS);
   processHistoryBars();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason) {
   for(int i = ObjectsTotal() - 1; i>-1; i--) {
      string objName = ObjectName(i);
      if (StringFind(objName, arrowObjectName) > -1) {
         ObjectDelete(objName);
      }
   }
}

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
   
   // continue only if there is a new bar
   checkNewBar();
   if (isNewBar == false)
      return(rates_total);
      
   int barIndex = 1;

   saveDailyOpen(barIndex);
   return processBar(barIndex, rates_total);
}


/**
 * @Depends: howManyBarsInHistoryToCheck
 */
void processHistoryBars() {
   int lastBarIndex = MathMin(howManyBarsInHistoryToCheck, ArraySize(Open)) - 2;
   for(int i = 2; i <= lastBarIndex; i++) {
      saveDailyOpenHistory(i);
      processBar(i, i);
   }
}

int processBar(int barIndex, int rates_total) {

   // Print("Open/Close: ", Open[barIndex], " / ", Close[barIndex]);
   
   lwMASmall = normalizeToMarket(iMA(NULL, 0, lwMASmallPeriod, 0, MODE_LWMA, PRICE_CLOSE, barIndex));
   lwMABig = normalizeToMarket(iMA(NULL, 0, lwMABigPeriod, 0, MODE_LWMA, PRICE_CLOSE, barIndex));
   // Print("lwMA small/big:  ", lwMASmall, "  /  ", lwMABig);
   
   SIGNAL twoBarContSignal = getTwoBarContSignal(barIndex);
   if(twoBarContSignal != SIGNAL_NONE) {
      count++;
   
      if (twoBarContSignal == SIGNAL_CALL) {
         drawArrowUp(barIndex, arrowObjectName+"-"+IntegerToString(count), High[barIndex]+30*Point, Lime);
      } else if (twoBarContSignal == SIGNAL_PUT) {
         drawArrowDown(barIndex, arrowObjectName+"-"+IntegerToString(count), Low[barIndex]-10*Point, Red);
      }
   }
      
   //--- return value of prev_calculated for next call
   return(rates_total);
}


SIGNAL getTwoBarContSignal(int barIndex) {
   TREND trend = getTwoBarTrend(barIndex);
   if (trend != TREND_NONE) {
      SIGNAL signal = getTwoBarContPatternsSignal(barIndex);
      if (signal == SIGNAL_CALL && trend == TREND_UP)
         return SIGNAL_CALL;
      else if (signal == SIGNAL_PUT && trend == TREND_DOWN)
         return SIGNAL_PUT;
      else return SIGNAL_NONE;
   }
   else return SIGNAL_NONE;
}


TREND getTwoBarTrend(int barIndex) {
   if(lwMABig > dailyOpen && lwMASmall > lwMABig && MathMin(High[barIndex], Low[barIndex]) > lwMABig)
      return TREND_UP;
   else if(lwMABig < dailyOpen && lwMASmall < lwMABig && MathMax(High[barIndex], Low[barIndex]) < lwMABig)
      return TREND_DOWN;
   else return TREND_NONE;   
}

/**
 * Checks if the last two bars are a continuation pattern and returns their signal.
 * 
 * @Returns: <SIGNAL> a signal. See the common lib.
 * @Depends: candles, commons
 * @See: http://www.binaryoptionsedge.com/topic/1835-nedds-2-bar-continution/
 */
SIGNAL getTwoBarContPatternsSignal(int curBarIndex) {
   int prevBarIndex = curBarIndex + 1;
   
   if (isInsideBar(curBarIndex) && !isInsideBar(prevBarIndex)) { // IB; avoid IB in IB
      if (isBearishBar(prevBarIndex) && isBullishBar(curBarIndex)) {
         if (isInvertedHammer(prevBarIndex) || isInvertedHammer(curBarIndex)) {
            return SIGNAL_CALL;
         }
         else return SIGNAL_NONE;
      }
      else if (isBullishBar(prevBarIndex) && isBearishBar(curBarIndex)) {
         if (isHangingMan(prevBarIndex) || isHangingMan(curBarIndex)) {
            return SIGNAL_PUT;
         }
         else return SIGNAL_NONE;
      }
      else return SIGNAL_NONE;
   }
   else if (isOutsideBar(curBarIndex) && !isOutsideBar(prevBarIndex)) { // OB; avoid OB in OB
      if (isBullishBar(curBarIndex) && (isInvertedHammer(prevBarIndex) || isInvertedHammer(curBarIndex))) {
         return SIGNAL_CALL;
      }
      else if (isBearishBar(curBarIndex) && (isHangingMan(prevBarIndex) || isHangingMan(curBarIndex))) {
         return SIGNAL_PUT;
      }
      else return SIGNAL_NONE;
   }
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| LINES LIB - FUNCTIONS                                            |
//+------------------------------------------------------------------+

/**
 * Saves the daily open in the dailyOpen variable.
 * 
 * TODO: How to optimize for speed or get the Daily Open in a simple way?
 * 
 * @Depends: dailyOpen[write]
 */
void saveDailyOpen(int barIndex) {
   ArrayCopyRates(ratesD1, Symbol(), PERIOD_D1);
   // Print("rates size: ", ArrayRange(ratesD1, 0));
   
   if(ratesD1[0][1] != dailyOpen) {
      dailyOpen = ratesD1[0][1];
      Print("New Daily Open for ",  Time[barIndex-1], " : ", dailyOpen);
   }
}


void saveDailyOpenHistory(int barIndex) {
   ArrayCopyRates(ratesD1, Symbol(), PERIOD_D1);
   
   // if a different day
   if (TimeDay(Time[barIndex]) != TimeDay(Time[barIndex+1])) {
      ratesD1Counter++;
      dailyOpen = ratesD1[ratesD1Counter][1];
      Print("History Different Day!  Counter: ", ratesD1Counter, "  Day: ", Time[barIndex], "  Open: ", dailyOpen);
   }
}
   

//+------------------------------------------------------------------+
//| DRAWING LIB - FUNCTIONS                                          |
//+------------------------------------------------------------------+

void drawArrowUp(int barIndex, string ArrowName, double LinePrice, color LineColor) {
   ObjectCreate(ArrowName, OBJ_ARROW, 0, Time[barIndex], LinePrice); //draw an up arrow
   ObjectSet(ArrowName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet(ArrowName, OBJPROP_ARROWCODE, SYMBOL_ARROWUP);
   ObjectSet(ArrowName, OBJPROP_COLOR, LineColor);
   ObjectSet(ArrowName, OBJPROP_BGCOLOR, LineColor);
   ObjectSet(ArrowName, OBJPROP_WIDTH, 4);
}

void drawArrowDown(int barIndex, string ArrowName, double LinePrice, color LineColor) {
   ObjectCreate(ArrowName, OBJ_ARROW, 0, Time[barIndex], LinePrice); //draw an up arrow
   ObjectSet(ArrowName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet(ArrowName, OBJPROP_ARROWCODE, SYMBOL_ARROWDOWN);
   ObjectSet(ArrowName, OBJPROP_COLOR, LineColor);
   ObjectSet(ArrowName, OBJPROP_BGCOLOR, LineColor);
   ObjectSet(ArrowName, OBJPROP_WIDTH, 4);
}

//+------------------------------------------------------------------+
//| CANDLES LIB - FUNCTIONS                                          |
//+------------------------------------------------------------------+

/**
 * Is the given bar within (including wicks/shadows) and smaller than the previous bar?
 * 
 * @Return: <bool>
 * @Depends: normalizeToMarket()
 */
bool isInsideBar(int barIndex) {
   bool isWithin = High[barIndex] <= High[barIndex+1] && Low[barIndex] >= Low[barIndex+1];
   bool isSmaller = normalizeToMarket(High[barIndex] - Low[barIndex]) < normalizeToMarket(High[barIndex+1] - Low[barIndex+1]);
   return isWithin && isSmaller;
}

/**
 * Is the given bar outside (including wicks/shadows) and bigger than the previous bar?
 * 
 * @Return: <bool>
 * @Depends: normalizeToMarket()
 */
bool isOutsideBar(int barIndex) {
   bool isOutside = High[barIndex] >= High[barIndex+1] && Low[barIndex] <= Low[barIndex+1];
   bool isBigger = normalizeToMarket(High[barIndex] - Low[barIndex]) > normalizeToMarket(High[barIndex+1] - Low[barIndex+1]);
   return isOutside && isBigger;
}

/**
 * Checks if the bar with the given index is a hanging man.
 * Compares its body to the size of the top and bottom shadows using the two ratio variables in the depend section.
 * If doji, returns false.
 * 
 * @Return: <bool>
 * @Depends: normalizeToMarket(), hammerSmallWickRatio, hammerBigWickRatio
 */
bool isHangingMan(int barIndex) {
   if (Open[barIndex] != Close[barIndex]) {
      double bodySize = normalizeToMarket(MathAbs(Open[barIndex] - Close[barIndex]));
      
      double topWickSize = normalizeToMarket(High[barIndex] - MathMax(Open[barIndex], Close[barIndex]));
      double bottomWickSize = normalizeToMarket(MathMin(Open[barIndex], Close[barIndex]) - Low[barIndex]);
      
      return bodySize >= normalizeToMarket(topWickSize * hammerSmallWickRatio) && normalizeToMarket(bodySize * hammerBigWickRatio) <= bottomWickSize;
   } else {
      return false;
   }
}

/**
 * Checks if the bar with the given index is an Inversted Hammer (IH).
 * Compares its body to the size of the top and bottom shadows using the two ratio variables in the depend section.
 * If doji, returns false.
 * 
 * @Return: <bool>
 * @Depends: normalizeToMarket(), hammerSmallWickRatio, hammerBigWickRatio
 */
bool isInvertedHammer(int barIndex) {
   if (Open[barIndex] != Close[barIndex]) {
      double bodySize = normalizeToMarket(MathAbs(Open[barIndex] - Close[barIndex]));
      
      double topWickSize = normalizeToMarket(High[barIndex] - MathMax(Open[barIndex], Close[barIndex]));
      double bottomWickSize = normalizeToMarket(MathMin(Open[barIndex], Close[barIndex]) - Low[barIndex]);
      
      // Print("Sizes: ", bodySize, "  /  ", topWickSize, "  /  ", bottomWickSize);
      
      return bodySize >= normalizeToMarket(bottomWickSize * hammerSmallWickRatio) && normalizeToMarket(bodySize * hammerBigWickRatio) <= topWickSize;
   } else {
      return false;
   }
}

/**
 * Checks if the given bar is bullish.
 * 
 * @Return: <bool>
 */
bool isBullishBar(int barIndex) {
   return (Close[barIndex] - Open[barIndex]) > 0;
}

/**
 * Checks if the given bar is bearish.
 * 
 * @Return: <bool>
 */
bool isBearishBar(int barIndex) {
   return (Open[barIndex] - Close[barIndex]) > 0;
}


//+------------------------------------------------------------------+
//| COMMON LIB - FUNCTIONS                                           |
//+------------------------------------------------------------------+


/**
 * Checks on every tick whether it is a new bar.
 *  
 * @Depends: isNewBar[write]
 */
void checkNewBar() {
   static datetime newTime = 0;
   isNewBar = false;
   if(newTime != Time[0]) {
     newTime = Time[0];
     isNewBar = true;
   }
}

/**
 * Normalizes the given double to the market price.
 *  
 * @Depends: marketDigits
 */
double normalizeToMarket(double price) {
   return NormalizeDouble(price, marketDigits);
}
