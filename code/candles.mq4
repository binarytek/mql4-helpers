//+------------------------------------------------------------------+
//|                                                      candles.mq4 |
//|                                                        binarytek |
//|                                     https://github.com/binarytek |
//+------------------------------------------------------------------+
#property copyright "binarytek"
#property link      "https://github.com/binarytek"
#property version   "0.01"
#property strict
#property indicator_chart_window




bool isNewBar = false;
int marketDigits = 0;

int count = 0;

double hammerSmallWickRatio = 1;
double hammerBigWickRatio = 2;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit() {
   marketDigits = (int)MarketInfo(OrderSymbol(),MODE_DIGITS);
   
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
      
   int barIndex = 1;
   Print("Open/Close: ", Open[barIndex], " / ", Close[barIndex]);
   
   int twoBarContinuation = checkTwoBarContinuation(barIndex);
   if(twoBarContinuation != 0) {
      count++;
   
      if (twoBarContinuation == 1) {
         drawArrowUp(barIndex, "Bar-"+IntegerToString(count), High[barIndex]+10*Point, Lime);
      } else if (twoBarContinuation == -1) {
         drawArrowDown(barIndex, "Bar-"+IntegerToString(count), Low[barIndex]-10*Point, Red);
      }
   }
      
//--- return value of prev_calculated for next call
   return(rates_total);
}
//+------------------------------------------------------------------+


void drawArrowUp(int barIndex, string ArrowName,double LinePrice,color LineColor) {
   ObjectCreate(ArrowName, OBJ_ARROW, 0, Time[barIndex], LinePrice); //draw an up arrow
   ObjectSet(ArrowName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet(ArrowName, OBJPROP_ARROWCODE, SYMBOL_ARROWUP);
   ObjectSet(ArrowName, OBJPROP_COLOR,LineColor);
}

void drawArrowDown(int barIndex, string ArrowName,double LinePrice,color LineColor) {
   ObjectCreate(ArrowName, OBJ_ARROW, 0, Time[barIndex], LinePrice); //draw an up arrow
   ObjectSet(ArrowName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSet(ArrowName, OBJPROP_ARROWCODE, SYMBOL_ARROWDOWN);
   ObjectSet(ArrowName, OBJPROP_COLOR,LineColor);
}

/**
 * Checks if the last two bars are a continuation pattern.
 * 
 * @Returns: 1 for CALL signal, -1 for PUT signal, 0 for no signal.
 * @Depends: normalizeToMarket()
 * @See: http://www.binaryoptionsedge.com/topic/1835-nedds-2-bar-continution/
 */
int checkTwoBarContinuation(int curBarIndex) {
   int prevBarIndex = curBarIndex + 1;
   
   if (isInsideBar(curBarIndex) && !isInsideBar(prevBarIndex)) { // avoid IB in IB
      if (isBearishBar(prevBarIndex) && isBullishBar(curBarIndex)) {
         if (isInvertedHammer(prevBarIndex) || isInvertedHammer(curBarIndex)) { // CALL
            return 1;
         }
         else return 0;
      }
      else if (isBullishBar(prevBarIndex) && isBearishBar(curBarIndex)) {
         if (isHangingMan(prevBarIndex) || isHangingMan(curBarIndex)) { // PUT
            return -1;
         }
         else return 0;
      }
      else return 0;
   }
   return false;
}

/**
 * Is within (with the wicks/shadows) and smaller than the previous bar
 * 
 * @Depends: normalizeToMarket()
 */
bool isInsideBar(int barIndex) {
   bool isWithin = High[barIndex] <= High[barIndex+1] && Low[barIndex] >= Low[barIndex+1];
   bool isSmaller = normalizeToMarket(High[barIndex] - Low[barIndex]) < normalizeToMarket(High[barIndex+1] - Low[barIndex+1]);
   return isWithin && isSmaller;
}

/**
 * Checks if the bar with the given index is a hanging man.
 * Compares its body to the size of the top and bottom shadows using the two ratio variables in the depend section.
 * If doji, returns false.
 *  
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
 * @Depends: normalizeToMarket(), hammerSmallWickRatio, hammerBigWickRatio
 */
bool isInvertedHammer(int barIndex) {
   if (Open[barIndex] != Close[barIndex]) {
      double bodySize = normalizeToMarket(MathAbs(Open[barIndex] - Close[barIndex]));
      
      double topWickSize = normalizeToMarket(High[barIndex] - MathMax(Open[barIndex], Close[barIndex]));
      double bottomWickSize = normalizeToMarket(MathMin(Open[barIndex], Close[barIndex]) - Low[barIndex]);
      
      Print("Sizes: ", bodySize, "  /  ", topWickSize, "  /  ", bottomWickSize);
      
      return bodySize >= normalizeToMarket(bottomWickSize * hammerSmallWickRatio) && normalizeToMarket(bodySize * hammerBigWickRatio) <= topWickSize;
   } else {
      return false;
   }
}

bool isBullishBar(int barIndex) {
   return (Close[barIndex] - Open[barIndex]) > 0;
}
bool isBearishBar(int barIndex) {
   return (Open[barIndex] - Close[barIndex]) > 0;
}


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
 * @Depend: marketDigits
 */
double normalizeToMarket(double price) {
   return NormalizeDouble(price, marketDigits);
}
