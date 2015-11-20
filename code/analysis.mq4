
void findConsequentCandles()
{
   Print("FindConsequentCandles start.");

   int lastBarIndex = ArraySize(High) - 1;
   int i;
   int numberOfSameCandles = 1;
   
   for (i = 1; i <= lastBarIndex; i++)
   {
      if (i != lastBarIndex) // skip last candle, as it is already considered in the loop before.
      {
         int curCandleType = getCandleType(Open[i], Close[i]);
         int prevCandleType = getCandleType(Open[i+1], Close[i+1]);
         
         if (curCandleType == prevCandleType)
         {
            numberOfSameCandles++;
            // go to previous candle
         }
         else
         {
            if (numberOfSameCandles > 1) // there were at least two candles of the same type
            {
               sameCandlesSum[numberOfSameCandles]++;
               if (numberOfSameCandles > 6)
               {
                  Print(numberOfSameCandles, " candles at ", Time[i+1]);
               }
            }
            numberOfSameCandles = 0;
         }
      }
   }
   
   int lastSameCandleSum = ArraySize(sameCandlesSum) - 1;
   for (i = 1; i <= lastSameCandleSum; i++)
   {
      if (sameCandlesSum[i] > 0)
      {
         Print(i, " candles appeared ", sameCandlesSum[i], " times.");
      }
      sameCandlesSum[i] = 0; // initialize
   }
   
   Print(lastBarIndex, " bars were tested. Beginning: ", Time[lastBarIndex]);

   Print("FindConsequentCandles end.");
}
