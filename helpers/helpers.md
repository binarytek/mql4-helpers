// Arrays

// append new element to end of int array
void intArrayPush( int& arr[], int elem ) {
	int size = ArraySize( arr );
	ArrayResize( arr, size + 1 );
	arr[ size ] = elem;
}
