#ifndef _FPCRTL_SYSUTILS_H_
#define _FPCRTL_SYSUTILS_H_

#include "Types.h"

// EFFECTS: return the current date time in pascal notation
//          http://www.merlyn.demon.co.uk/del-prgg.htm#TDT
TDateTime   fpcrtl_now();
#define     fpcrtl_Now              fpcrtl_now
#define     now                     fpcrtl_Now
#define     Now                     fpcrtl_Now

string255   fpcrtl_formatDateTime(string255 FormatStr, TDateTime DateTime);
#define     fpcrtl_FormatDateTime   fpcrtl_formatDateTime

// EFFECTS: return the current time
//          http://www.merlyn.demon.co.uk/del-prgg.htm#TDT
TDateTime   fpcrtl_time();


// EFFECTS: return the current date
//          http://www.merlyn.demon.co.uk/del-prgg.htm#TDT
TDateTime   fpcrtl_date();
#define     date                    fpcrtl_date
#define     Date                    fpcrtl_date

// EFFECTS: Trim strips blank characters (spaces) at the beginning and end of S
// and returns the resulting string. Only #32 characters are stripped.
// If the string contains only spaces, an empty string is returned.
string255   fpcrtl_trim(string255 s);
#define     trim                    fpcrtl_trim
#define     Trim                    fpcrtl_trim

Integer     fpcrtl_strToInt(string255 s);
#define     StrToInt                fpcrtl_strToInt
#define     strToInt                fpcrtl_strToInt

string255   fpcrtl_extractFileDir(string255 f);
#define     fpcrtl_ExtractFileDir  fpcrtl_extractFileDir

string255   fpcrtl_extractFileName(string255 f);
#define     fpcrtl_ExtractFileName  fpcrtl_extractFileName

string255   fpcrtl_strPas(PChar);
#define     fpcrtl_StrPas           fpcrtl_strPas


#endif
