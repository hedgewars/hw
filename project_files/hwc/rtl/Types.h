#ifndef _TYPES_H_
#define _TYPES_H_

#include "pas2c.h"

/*
 * Not very useful currently
 */

typedef double TDate;
typedef double TTime;
typedef double TDateTime;
typedef string255 TMonthNameArray[13];
typedef string255 TWeekNameArray[8];

typedef struct {
    Byte CurrencyFormat;
    Byte NegCurrFormat;
    Char ThousandSeparator;
    Char DecimalSeparator;
    Byte CurrencyDecimals;
    Char DateSeparator;
    Char TimeSeparator;
    Char ListSeparator;
    string255 CurrencyString;
    string255 ShortDateFormat;
    string255 LongDateFormat;
    string255 TimeAMString;
    string255 TimePMString;
    string255 ShortTimeFormat;
    string255 LongTimeFormat;
    TMonthNameArray ShortMonthNames;
    TMonthNameArray LongMonthNames;
    TWeekNameArray ShortDayNames;
    TWeekNameArray LongDayNames;
    Word TwoDigitYearCenturyWindow;
}TFormatSettings;

#endif
