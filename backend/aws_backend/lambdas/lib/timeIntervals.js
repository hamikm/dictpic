// WARNING: this library ignores daylight savings!

const secondsPerHour = 3600;
const secondsPerDay = 86400;
const secondsPerWeek = 604800;
const secondsPerLeapYear = 31622400;
const secondsPerCommonYear = 31536000;

const isLeapYear = year => {
    if (year % 4 !== 0) {
        return false;
    } else if (year % 100 !== 0) {
        return true;
    } else if (year % 400 !== 0) {
        return false;
    } else {
        return true;
    }
};

// month is an int from 0 to 11
const secondsInMonth = (month, year) => {
    var days;
    switch (month) {
        case 0:  // january
            days = 31;
            break;
        case 1:  // february
            if (isLeapYear(year)) {
                days = 29;
            } else {
                days = 28;
            }
            break;
        case 2:  // march
            days = 31;
            break;
        case 3:  // april
            days = 30;
            break;
        case 4:  // may
            days = 31;
            break;
        case 5:  // june
            days = 30;
            break;
        case 6:  // july
            days = 31;
            break;
        case 7:  // august
            days = 31;
            break;
        case 8:  // september
            days = 30;
            break;
        case 9:  // october
            days = 31;
            break;
        case 10:
            days = 30;
            break;
        case 11:
            days = 31;
            break;
    }
    return days * secondsPerDay;
};

const secondsInYear = year => {
    return isLeapYear(year) ? secondsPerLeapYear : secondsPerCommonYear;
};

// Return dict of tuples, one for each of hour, day, month, etc. Tuples have
// form (startedAt, delta), where startedAt is the seconds after epoch at
// which that hour/day/month started. Delta is the length of the hour/day/etc
const getColumnMetadataAux = (month, year, secs) => {
    const thisHourStartedAt = secs - secs % secondsPerHour;
    const thisDayStartedAt = secs - secs % secondsPerDay;
    const thisWeekStartedAt = secs - secs % secondsPerWeek;
    
    const secondsInThisMonth = secondsInMonth(month, year);
    const thisMonthStartedAt = secs - secs % secondsInThisMonth;

    const secondsInThisYear = secondsInYear(year);
    const thisYearStartedAt = secs - secs % secondsInThisYear;

    return {
        h: [thisHourStartedAt, secondsPerHour],
        d: [thisDayStartedAt, secondsPerDay],
        w: [thisWeekStartedAt, secondsPerWeek],
        m: [thisMonthStartedAt, secondsInThisMonth],
        y: [thisYearStartedAt, secondsInThisYear],
    };
};

const getColumnMetadata = () => {
    const currDate = new Date();
    const year = currDate.getUTCFullYear();
    const month = currDate.getUTCMonth();
    const secsSinceEpoch = currDate.getTime() / 1000;
    return getColumnMetadataAux(month, year, secsSinceEpoch);
};

exports.isLeapYear = isLeapYear;
exports.secondsPerHour = secondsPerHour;
exports.secondsPerDay = secondsPerDay;
exports.secondsPerWeek = secondsPerWeek;
exports.secondsInMonth = secondsInMonth;
exports.secondsInYear = secondsInYear;
exports.getColumnMetadataAux = getColumnMetadataAux;
exports.getColumnMetadata = getColumnMetadata;
