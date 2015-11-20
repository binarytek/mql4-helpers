// Arrays


/*
 * append new element to end of int array
 */
void arrIntPush( int& arr[], int elem ) {
	int size = ArraySize( arr );
	ArrayResize( arr, size + 1 );
	arr[ size ] = elem;
}

/*
 * create a string from int array
 */
string arrIntToStr(int& arr[]) {
   string res = "{ ";
   
   int i;
   int lastArrItem = ArraySize(arr) - 1;
   
   for(i = 0; i <= lastArrItem; i++) {
      res += IntegerToString(arr[i]);
      if (i != lastArrItem) {
         res += ",";
      }
   }
   
   res += " }";
   return res;
}
