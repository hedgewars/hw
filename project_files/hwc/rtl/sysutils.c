#include "SysUtils.h"

#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "system.h"
#include "misc.h"

TDateTime fpcrtl_date()
{
    const int num_days_between_1900_1980 = 29220;

    struct tm ref_date;
    struct tm cur_date;
    time_t local_time;
    time_t ref_time, cur_time;

    double timeDiff;
    double day_time_frac; //fraction that represents the time in one day
    int num_seconds;
    int numDays;

    // unix epoch doesn't work, choose Jan 1st 1980 instead
    ref_date.tm_year = 80;
    ref_date.tm_mon = 0;
    ref_date.tm_mday = 1;
    ref_date.tm_hour = 0;
    ref_date.tm_min = 0;
    ref_date.tm_sec = 0;
    ref_date.tm_isdst = 0;
    ref_date.tm_wday = 0; // ignored
    ref_date.tm_yday = 0; // ignored

    local_time = time(NULL);
    cur_date = *localtime(&local_time);

    cur_date.tm_hour = 0;
    cur_date.tm_min = 0;
    cur_date.tm_sec = 0;

    ref_time = mktime(&ref_date);
    cur_time = mktime(&cur_date);

    timeDiff = difftime(cur_time, ref_time);
    numDays = fpcrtl_round(timeDiff / 3600 / 24) + num_days_between_1900_1980 + 1;

    fpcrtl_printf("[date] tim diff: %f\n", timeDiff);
    fpcrtl_printf("[date] num days between 1980 and today:  %d\n", fpcrtl_round(timeDiff/3600/24));
    fpcrtl_printf("[date] current date: %s\n", asctime(&cur_date));
    fpcrtl_printf("[date] reference date: %s\n", asctime(&ref_date));
    fpcrtl_printf("[date] num days: %d\n", numDays);

    return numDays;
}

TDateTime fpcrtl_time()
{
    struct tm cur_date;
    time_t local_time;
    time_t cur_time;

    double day_time_frac; //fraction that represents the time in one day
    int num_seconds;

    local_time = time(NULL);
    cur_date = *localtime(&local_time);

    num_seconds = cur_date.tm_hour * 3600 + cur_date.tm_min * 60 + cur_date.tm_sec;
    day_time_frac = num_seconds / 3600.0 / 24.0;

    fpcrtl_printf("%f\n", day_time_frac);

    return day_time_frac;
}

TDateTime fpcrtl_now()
{
    return fpcrtl_date() + fpcrtl_time();
}

// Semi-dummy implementation of FormatDateTime
string255 fpcrtl_formatDateTime(string255 FormatStr, TDateTime DateTime)
{
    string255 buffer = STRINIT(FormatStr.str);
    time_t rawtime;
    struct tm* my_tm;

    // DateTime is ignored, always uses current time.
    // TODO: Use DateTime argument properly.
    time(&rawtime);
    my_tm = localtime(&rawtime);

    // Currently uses a hardcoded format string, FormatStr is ignored.
    // The format strings for C and Pascal differ!
    // TODO: Use FormatStr argument properly.
    size_t len = strftime(buffer.str, sizeof(buffer.str), "%Y-%m-%d-%H-%M-%S-0", my_tm);
    buffer.len = len;
    return buffer;
}

string255 fpcrtl_trim(string255 s)
{
    int left, right;

    if(s.len == 0){
        return s;
    }

    for(left = 0; left < s.len; left++)
    {
        if(s.str[left] != ' '){
            break;
        }
    }

    for(right = s.len - 1; right >= 0; right--)
    {
        if(s.str[right] != ' '){
            break;
        }
    }

    if(left > right){
        s.len = 0;
        s.str[0] = 0;
        return s;
    }

    s.len = right - left + 1;
    memmove(s.str, s.str + left, s.len);

    s.str[s.len] = 0;

    return s;
}

Integer fpcrtl_strToInt(string255 s)
{
    s.str[s.len] = 0;
    return atoi(s.str);
}

string255 fpcrtl_extractFileDir(string255 f)
{
    const char sep[] = {'\\', '/', ':'};
    LongInt i,j;

    i = f.len - 1;
    while(i >= 0){
        for(j = 0; j < sizeof(sep); j++){
            if(f.str[i] == sep[j]){
                goto FPCRTL_EXTRACTFILEDIR_END;
            }
        }
        i--;
    }
FPCRTL_EXTRACTFILEDIR_END:
    return fpcrtl_copy(f, 1, i);
}

//function ExtractFileName(const FileName: string): string;
//var
//  i : longint;
//  EndSep : Set of Char;
//begin
//  I := Length(FileName);
//  EndSep:=AllowDirectorySeparators+AllowDriveSeparators;
//  while (I > 0) and not (FileName[I] in EndSep) do
//    Dec(I);
//  Result := Copy(FileName, I + 1, MaxInt);
//end;

string255 fpcrtl_extractFileName(string255 f)
{
    const char sep[] = {'\\', '/', ':'};
    LongInt i,j;

    i = f.len - 1;
    while(i >= 0){
        for(j = 0; j < sizeof(sep); j++){
            if(f.str[i] == sep[j]){
                goto FPCRTL_EXTRACTFILENAME_END;
            }
        }
        i--;
    }
FPCRTL_EXTRACTFILENAME_END:
    return fpcrtl_copy(f, i + 2, 256);
}

string255 fpcrtl_strPas(PChar p)
{
    return fpcrtl_pchar2str(p);
}
