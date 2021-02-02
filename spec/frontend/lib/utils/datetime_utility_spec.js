import $ from 'jquery';
import timezoneMock from 'timezone-mock';
import { __, s__ } from '~/locale';
import '~/commons/bootstrap';
import * as datetimeUtility from '~/lib/utils/datetime_utility';

describe('Date time utils', () => {
  describe('timeFor', () => {
    it('returns localize `past due` when in past', () => {
      const date = new Date();
      date.setFullYear(date.getFullYear() - 1);

      expect(datetimeUtility.timeFor(date)).toBe(s__('Timeago|Past due'));
    });

    it('returns localized remaining time when in the future', () => {
      const date = new Date();
      date.setFullYear(date.getFullYear() + 1);

      // Add a day to prevent a transient error. If date is even 1 second
      // short of a full year, timeFor will return '11 months remaining'
      date.setDate(date.getDate() + 1);

      expect(datetimeUtility.timeFor(date)).toBe(s__('Timeago|1 year remaining'));
    });
  });

  describe('get localized day name', () => {
    it('should return Sunday', () => {
      const day = datetimeUtility.getDayName(new Date('07/17/2016'));

      expect(day).toBe(__('Sunday'));
    });

    it('should return Monday', () => {
      const day = datetimeUtility.getDayName(new Date('07/18/2016'));

      expect(day).toBe(__('Monday'));
    });

    it('should return Tuesday', () => {
      const day = datetimeUtility.getDayName(new Date('07/19/2016'));

      expect(day).toBe(__('Tuesday'));
    });

    it('should return Wednesday', () => {
      const day = datetimeUtility.getDayName(new Date('07/20/2016'));

      expect(day).toBe(__('Wednesday'));
    });

    it('should return Thursday', () => {
      const day = datetimeUtility.getDayName(new Date('07/21/2016'));

      expect(day).toBe(__('Thursday'));
    });

    it('should return Friday', () => {
      const day = datetimeUtility.getDayName(new Date('07/22/2016'));

      expect(day).toBe(__('Friday'));
    });

    it('should return Saturday', () => {
      const day = datetimeUtility.getDayName(new Date('07/23/2016'));

      expect(day).toBe(__('Saturday'));
    });
  });

  describe('formatDateAsMonth', () => {
    it('should format dash cased date properly', () => {
      const formattedMonth = datetimeUtility.formatDateAsMonth(new Date('2020-06-28'));

      expect(formattedMonth).toBe('Jun');
    });

    it('should format return the non-abbreviated month', () => {
      const formattedMonth = datetimeUtility.formatDateAsMonth(new Date('2020-07-28'), {
        abbreviated: false,
      });

      expect(formattedMonth).toBe('July');
    });

    it('should format date with slashes properly', () => {
      const formattedMonth = datetimeUtility.formatDateAsMonth(new Date('07/23/2016'));

      expect(formattedMonth).toBe('Jul');
    });

    it('should format ISO date properly', () => {
      const formattedMonth = datetimeUtility.formatDateAsMonth('2016-07-23T00:00:00.559Z');

      expect(formattedMonth).toBe('Jul');
    });
  });

  describe('formatDate', () => {
    it('should format date properly', () => {
      const formattedDate = datetimeUtility.formatDate(new Date('07/23/2016'));

      expect(formattedDate).toBe('Jul 23, 2016 12:00am GMT+0000');
    });

    it('should format ISO date properly', () => {
      const formattedDate = datetimeUtility.formatDate('2016-07-23T00:00:00.559Z');

      expect(formattedDate).toBe('Jul 23, 2016 12:00am GMT+0000');
    });

    it('should throw an error if date is invalid', () => {
      expect(() => {
        datetimeUtility.formatDate('2016-07-23 00:00:00 UTC');
      }).toThrow(new Error('Invalid date'));
    });

    describe('convert local timezone to UTC with utc parameter', () => {
      const midnightUTC = '2020-07-09';
      const format = 'mmm d, yyyy';

      beforeEach(() => {
        timezoneMock.register('US/Pacific');
      });

      afterEach(() => {
        timezoneMock.unregister();
      });

      it('defaults to false', () => {
        const formattedDate = datetimeUtility.formatDate(midnightUTC, format);

        expect(formattedDate).toBe('Jul 8, 2020');
      });

      it('converts local time to UTC if utc flag is true', () => {
        const formattedDate = datetimeUtility.formatDate(midnightUTC, format, true);

        expect(formattedDate).toBe('Jul 9, 2020');
      });
    });
  });

  describe('get day difference', () => {
    it('should return 7', () => {
      const firstDay = new Date('07/01/2016');
      const secondDay = new Date('07/08/2016');
      const difference = datetimeUtility.getDayDifference(firstDay, secondDay);

      expect(difference).toBe(7);
    });

    it('should return 31', () => {
      const firstDay = new Date('07/01/2016');
      const secondDay = new Date('08/01/2016');
      const difference = datetimeUtility.getDayDifference(firstDay, secondDay);

      expect(difference).toBe(31);
    });

    it('should return 365', () => {
      const firstDay = new Date('07/02/2015');
      const secondDay = new Date('07/01/2016');
      const difference = datetimeUtility.getDayDifference(firstDay, secondDay);

      expect(difference).toBe(365);
    });
  });
});

describe('timeIntervalInWords', () => {
  it('should return string with number of minutes and seconds', () => {
    expect(datetimeUtility.timeIntervalInWords(9.54)).toEqual(s__('Timeago|9 seconds'));
    expect(datetimeUtility.timeIntervalInWords(1)).toEqual(s__('Timeago|1 second'));
    expect(datetimeUtility.timeIntervalInWords(200)).toEqual(s__('Timeago|3 minutes 20 seconds'));
    expect(datetimeUtility.timeIntervalInWords(6008)).toEqual(s__('Timeago|100 minutes 8 seconds'));
  });
});

describe('dateInWords', () => {
  const date = new Date('07/01/2016');

  it('should return date in words', () => {
    expect(datetimeUtility.dateInWords(date)).toEqual(s__('July 1, 2016'));
  });

  it('should return abbreviated month name', () => {
    expect(datetimeUtility.dateInWords(date, true)).toEqual(s__('Jul 1, 2016'));
  });

  it('should return date in words without year', () => {
    expect(datetimeUtility.dateInWords(date, true, true)).toEqual(s__('Jul 1'));
  });
});

describe('monthInWords', () => {
  const date = new Date('2017-01-20');

  it('returns month name from provided date', () => {
    expect(datetimeUtility.monthInWords(date)).toBe(s__('January'));
  });

  it('returns abbreviated month name from provided date', () => {
    expect(datetimeUtility.monthInWords(date, true)).toBe(s__('Jan'));
  });
});

describe('totalDaysInMonth', () => {
  it('returns number of days in a month for given date', () => {
    // 1st Feb, 2016 (leap year)
    expect(datetimeUtility.totalDaysInMonth(new Date(2016, 1, 1))).toBe(29);

    // 1st Feb, 2017
    expect(datetimeUtility.totalDaysInMonth(new Date(2017, 1, 1))).toBe(28);

    // 1st Jan, 2017
    expect(datetimeUtility.totalDaysInMonth(new Date(2017, 0, 1))).toBe(31);
  });
});

describe('getSundays', () => {
  it('returns array of dates representing all Sundays of the month', () => {
    // December, 2017 (it has 5 Sundays)
    const dateOfSundays = [3, 10, 17, 24, 31];
    const sundays = datetimeUtility.getSundays(new Date(2017, 11, 1));

    expect(sundays.length).toBe(5);
    sundays.forEach((sunday, index) => {
      expect(sunday.getDate()).toBe(dateOfSundays[index]);
    });
  });
});

describe('getTimeframeWindowFrom', () => {
  it('returns array of date objects upto provided length (positive number) into the future starting from provided startDate', () => {
    const startDate = new Date(2018, 0, 1);
    const mockTimeframe = [
      new Date(2018, 0, 1),
      new Date(2018, 1, 1),
      new Date(2018, 2, 1),
      new Date(2018, 3, 1),
      new Date(2018, 4, 31),
    ];
    const timeframe = datetimeUtility.getTimeframeWindowFrom(startDate, 5);

    expect(timeframe.length).toBe(5);
    timeframe.forEach((timeframeItem, index) => {
      expect(timeframeItem.getFullYear()).toBe(mockTimeframe[index].getFullYear());
      expect(timeframeItem.getMonth()).toBe(mockTimeframe[index].getMonth());
      expect(timeframeItem.getDate()).toBe(mockTimeframe[index].getDate());
    });
  });

  it('returns array of date objects upto provided length (negative number) into the past starting from provided startDate', () => {
    const startDate = new Date(2018, 0, 1);
    const mockTimeframe = [
      new Date(2018, 0, 1),
      new Date(2017, 11, 1),
      new Date(2017, 10, 1),
      new Date(2017, 9, 1),
      new Date(2017, 8, 1),
    ];
    const timeframe = datetimeUtility.getTimeframeWindowFrom(startDate, -5);

    expect(timeframe.length).toBe(5);
    timeframe.forEach((timeframeItem, index) => {
      expect(timeframeItem.getFullYear()).toBe(mockTimeframe[index].getFullYear());
      expect(timeframeItem.getMonth()).toBe(mockTimeframe[index].getMonth());
      expect(timeframeItem.getDate()).toBe(mockTimeframe[index].getDate());
    });
  });
});

describe('formatTime', () => {
  const expectedTimestamps = [
    [0, '00:00:00'],
    [1000, '00:00:01'],
    [42000, '00:00:42'],
    [121000, '00:02:01'],
    [10921000, '03:02:01'],
    [108000000, '30:00:00'],
  ];

  expectedTimestamps.forEach(([milliseconds, expectedTimestamp]) => {
    it(`formats ${milliseconds}ms as ${expectedTimestamp}`, () => {
      expect(datetimeUtility.formatTime(milliseconds)).toBe(expectedTimestamp);
    });
  });
});

describe('datefix', () => {
  describe('pad', () => {
    it('should add a 0 when length is smaller than 2', () => {
      expect(datetimeUtility.pad(2)).toEqual('02');
    });

    it('should not add a zero when length matches the default', () => {
      expect(datetimeUtility.pad(12)).toEqual('12');
    });

    it('should add a 0 when length is smaller than the provided', () => {
      expect(datetimeUtility.pad(12, 3)).toEqual('012');
    });
  });

  describe('parsePikadayDate', () => {
    // removed because of https://gitlab.com/gitlab-org/gitlab-foss/issues/39834
  });

  describe('pikadayToString', () => {
    it('should format a UTC date into yyyy-mm-dd format', () => {
      expect(datetimeUtility.pikadayToString(new Date('2020-01-29:00:00'))).toEqual('2020-01-29');
    });
  });
});

describe('prettyTime methods', () => {
  const assertTimeUnits = (obj, minutes, hours, days, weeks) => {
    expect(obj.minutes).toBe(minutes);
    expect(obj.hours).toBe(hours);
    expect(obj.days).toBe(days);
    expect(obj.weeks).toBe(weeks);
  };

  describe('parseSeconds', () => {
    it('should correctly parse a negative value', () => {
      const zeroSeconds = datetimeUtility.parseSeconds(-1000);

      assertTimeUnits(zeroSeconds, 16, 0, 0, 0);
    });

    it('should correctly parse a zero value', () => {
      const zeroSeconds = datetimeUtility.parseSeconds(0);

      assertTimeUnits(zeroSeconds, 0, 0, 0, 0);
    });

    it('should correctly parse a small non-zero second values', () => {
      const subOneMinute = datetimeUtility.parseSeconds(10);
      const aboveOneMinute = datetimeUtility.parseSeconds(100);
      const manyMinutes = datetimeUtility.parseSeconds(1000);

      assertTimeUnits(subOneMinute, 0, 0, 0, 0);
      assertTimeUnits(aboveOneMinute, 1, 0, 0, 0);
      assertTimeUnits(manyMinutes, 16, 0, 0, 0);
    });

    it('should correctly parse large second values', () => {
      const aboveOneHour = datetimeUtility.parseSeconds(4800);
      const aboveOneDay = datetimeUtility.parseSeconds(110000);
      const aboveOneWeek = datetimeUtility.parseSeconds(25000000);

      assertTimeUnits(aboveOneHour, 20, 1, 0, 0);
      assertTimeUnits(aboveOneDay, 33, 6, 3, 0);
      assertTimeUnits(aboveOneWeek, 26, 0, 3, 173);
    });

    it('should correctly accept a custom param for hoursPerDay', () => {
      const config = { hoursPerDay: 24 };

      const aboveOneHour = datetimeUtility.parseSeconds(4800, config);
      const aboveOneDay = datetimeUtility.parseSeconds(110000, config);
      const aboveOneWeek = datetimeUtility.parseSeconds(25000000, config);

      assertTimeUnits(aboveOneHour, 20, 1, 0, 0);
      assertTimeUnits(aboveOneDay, 33, 6, 1, 0);
      assertTimeUnits(aboveOneWeek, 26, 8, 4, 57);
    });

    it('should correctly accept a custom param for daysPerWeek', () => {
      const config = { daysPerWeek: 7 };

      const aboveOneHour = datetimeUtility.parseSeconds(4800, config);
      const aboveOneDay = datetimeUtility.parseSeconds(110000, config);
      const aboveOneWeek = datetimeUtility.parseSeconds(25000000, config);

      assertTimeUnits(aboveOneHour, 20, 1, 0, 0);
      assertTimeUnits(aboveOneDay, 33, 6, 3, 0);
      assertTimeUnits(aboveOneWeek, 26, 0, 0, 124);
    });

    it('should correctly accept custom params for daysPerWeek and hoursPerDay', () => {
      const config = { daysPerWeek: 55, hoursPerDay: 14 };

      const aboveOneHour = datetimeUtility.parseSeconds(4800, config);
      const aboveOneDay = datetimeUtility.parseSeconds(110000, config);
      const aboveOneWeek = datetimeUtility.parseSeconds(25000000, config);

      assertTimeUnits(aboveOneHour, 20, 1, 0, 0);
      assertTimeUnits(aboveOneDay, 33, 2, 2, 0);
      assertTimeUnits(aboveOneWeek, 26, 0, 1, 9);
    });

    it('should correctly parse values when limitedToHours is true', () => {
      const twoDays = datetimeUtility.parseSeconds(173000, { limitToHours: true });

      assertTimeUnits(twoDays, 3, 48, 0, 0);
    });

    it('should correctly parse values when limitedToDays is true', () => {
      const sevenDays = datetimeUtility.parseSeconds(648750, {
        hoursPerDay: 24,
        daysPerWeek: 7,
        limitToDays: true,
      });

      assertTimeUnits(sevenDays, 12, 12, 7, 0);
    });
  });

  describe('stringifyTime', () => {
    it('should stringify values with all non-zero units', () => {
      const timeObject = {
        weeks: 1,
        days: 4,
        hours: 7,
        minutes: 20,
      };

      const timeString = datetimeUtility.stringifyTime(timeObject);

      expect(timeString).toBe('1w 4d 7h 20m');
    });

    it('should stringify values with some non-zero units', () => {
      const timeObject = {
        weeks: 0,
        days: 4,
        hours: 0,
        minutes: 20,
      };

      const timeString = datetimeUtility.stringifyTime(timeObject);

      expect(timeString).toBe('4d 20m');
    });

    it('should stringify values with no non-zero units', () => {
      const timeObject = {
        weeks: 0,
        days: 0,
        hours: 0,
        minutes: 0,
      };

      const timeString = datetimeUtility.stringifyTime(timeObject);

      expect(timeString).toBe('0m');
    });

    it('should return non-condensed representation of time object', () => {
      const timeObject = { weeks: 1, days: 0, hours: 1, minutes: 0 };

      expect(datetimeUtility.stringifyTime(timeObject, true)).toEqual('1 week 1 hour');
    });
  });
});

describe('calculateRemainingMilliseconds', () => {
  beforeEach(() => {
    jest.spyOn(Date, 'now').mockImplementation(() => new Date('2063-04-04T00:42:00Z').getTime());
  });

  it('calculates the remaining time for a given end date', () => {
    const milliseconds = datetimeUtility.calculateRemainingMilliseconds('2063-04-04T01:44:03Z');

    expect(milliseconds).toBe(3723000);
  });

  it('returns 0 if the end date has passed', () => {
    const milliseconds = datetimeUtility.calculateRemainingMilliseconds('2063-04-03T00:00:00Z');

    expect(milliseconds).toBe(0);
  });
});

describe('newDate', () => {
  it('returns new date instance from existing date instance', () => {
    const initialDate = new Date(2019, 0, 1);
    const copiedDate = datetimeUtility.newDate(initialDate);

    expect(copiedDate.getTime()).toBe(initialDate.getTime());

    initialDate.setMonth(initialDate.getMonth() + 1);

    expect(copiedDate.getTime()).not.toBe(initialDate.getTime());
  });

  it('returns date instance when provided date param is not of type date or is undefined', () => {
    const initialDate = datetimeUtility.newDate();

    expect(initialDate instanceof Date).toBe(true);
  });
});

describe('getDateInPast', () => {
  const date = new Date('2019-07-16T00:00:00.000Z');
  const daysInPast = 90;

  it('returns the correct date in the past', () => {
    const dateInPast = datetimeUtility.getDateInPast(date, daysInPast);
    const expectedDateInPast = new Date('2019-04-17T00:00:00.000Z');

    expect(dateInPast).toStrictEqual(expectedDateInPast);
  });

  it('does not modifiy the original date', () => {
    datetimeUtility.getDateInPast(date, daysInPast);
    expect(date).toStrictEqual(new Date('2019-07-16T00:00:00.000Z'));
  });
});

describe('getDateInFuture', () => {
  const date = new Date('2019-07-16T00:00:00.000Z');
  const daysInFuture = 90;

  it('returns the correct date in the future', () => {
    const dateInFuture = datetimeUtility.getDateInFuture(date, daysInFuture);
    const expectedDateInFuture = new Date('2019-10-14T00:00:00.000Z');

    expect(dateInFuture).toStrictEqual(expectedDateInFuture);
  });

  it('does not modifiy the original date', () => {
    datetimeUtility.getDateInFuture(date, daysInFuture);
    expect(date).toStrictEqual(new Date('2019-07-16T00:00:00.000Z'));
  });
});

describe('isValidDate', () => {
  it.each`
    valueToCheck                              | isValid
    ${new Date()}                             | ${true}
    ${new Date('December 17, 1995 03:24:00')} | ${true}
    ${new Date('1995-12-17T03:24:00')}        | ${true}
    ${new Date('foo')}                        | ${false}
    ${5}                                      | ${false}
    ${''}                                     | ${false}
    ${false}                                  | ${false}
    ${undefined}                              | ${false}
    ${null}                                   | ${false}
  `('returns $expectedReturnValue when called with $dateToCheck', ({ valueToCheck, isValid }) => {
    expect(datetimeUtility.isValidDate(valueToCheck)).toBe(isValid);
  });
});

describe('getDatesInRange', () => {
  it('returns an empty array if 1st or 2nd argument is not a Date object', () => {
    const d1 = new Date('2019-01-01');
    const d2 = 90;
    const range = datetimeUtility.getDatesInRange(d1, d2);

    expect(range).toEqual([]);
  });

  it('returns a range of dates between two given dates', () => {
    const d1 = new Date('2019-01-01');
    const d2 = new Date('2019-01-31');

    const range = datetimeUtility.getDatesInRange(d1, d2);

    expect(range.length).toEqual(31);
  });

  it('applies mapper function if provided fro each item in range', () => {
    const d1 = new Date('2019-01-01');
    const d2 = new Date('2019-01-31');
    const formatter = (date) => date.getDate();

    const range = datetimeUtility.getDatesInRange(d1, d2, formatter);

    range.forEach((formattedItem, index) => {
      expect(formattedItem).toEqual(index + 1);
    });
  });
});

describe('secondsToMilliseconds', () => {
  it('converts seconds to milliseconds correctly', () => {
    expect(datetimeUtility.secondsToMilliseconds(0)).toBe(0);
    expect(datetimeUtility.secondsToMilliseconds(60)).toBe(60000);
    expect(datetimeUtility.secondsToMilliseconds(123)).toBe(123000);
  });
});

describe('secondsToDays', () => {
  it('converts seconds to days correctly', () => {
    expect(datetimeUtility.secondsToDays(0)).toBe(0);
    expect(datetimeUtility.secondsToDays(90000)).toBe(1);
    expect(datetimeUtility.secondsToDays(270000)).toBe(3);
  });
});

describe('date addition/subtraction methods', () => {
  beforeEach(() => {
    timezoneMock.register('US/Eastern');
  });

  afterEach(() => {
    timezoneMock.unregister();
  });

  describe('dayAfter', () => {
    const input = '2019-03-10T00:00:00.000Z';
    const expectedLocalResult = '2019-03-10T23:00:00.000Z';
    const expectedUTCResult = '2019-03-11T00:00:00.000Z';

    it.each`
      inputAsString | options           | expectedAsString
      ${input}      | ${undefined}      | ${expectedLocalResult}
      ${input}      | ${{}}             | ${expectedLocalResult}
      ${input}      | ${{ utc: false }} | ${expectedLocalResult}
      ${input}      | ${{ utc: true }}  | ${expectedUTCResult}
    `(
      'when the provided date is $inputAsString and the options parameter is $options, returns $expectedAsString',
      ({ inputAsString, options, expectedAsString }) => {
        const inputDate = new Date(inputAsString);
        const actual = datetimeUtility.dayAfter(inputDate, options);

        expect(actual.toISOString()).toBe(expectedAsString);
      },
    );

    it('does not modifiy the original date', () => {
      const inputDate = new Date(input);
      datetimeUtility.dayAfter(inputDate);
      expect(inputDate.toISOString()).toBe(input);
    });
  });

  describe('nDaysAfter', () => {
    const input = '2019-07-16T00:00:00.000Z';

    it.each`
      inputAsString | numberOfDays | options           | expectedAsString
      ${input}      | ${1}         | ${undefined}      | ${'2019-07-17T00:00:00.000Z'}
      ${input}      | ${-1}        | ${undefined}      | ${'2019-07-15T00:00:00.000Z'}
      ${input}      | ${0}         | ${undefined}      | ${'2019-07-16T00:00:00.000Z'}
      ${input}      | ${0.9}       | ${undefined}      | ${'2019-07-16T00:00:00.000Z'}
      ${input}      | ${120}       | ${undefined}      | ${'2019-11-13T01:00:00.000Z'}
      ${input}      | ${120}       | ${{}}             | ${'2019-11-13T01:00:00.000Z'}
      ${input}      | ${120}       | ${{ utc: false }} | ${'2019-11-13T01:00:00.000Z'}
      ${input}      | ${120}       | ${{ utc: true }}  | ${'2019-11-13T00:00:00.000Z'}
    `(
      'when the provided date is $inputAsString, numberOfDays is $numberOfDays, and the options parameter is $options, returns $expectedAsString',
      ({ inputAsString, numberOfDays, options, expectedAsString }) => {
        const inputDate = new Date(inputAsString);
        const actual = datetimeUtility.nDaysAfter(inputDate, numberOfDays, options);

        expect(actual.toISOString()).toBe(expectedAsString);
      },
    );
  });

  describe('nDaysBefore', () => {
    const input = '2019-07-16T00:00:00.000Z';

    it.each`
      inputAsString | numberOfDays | options           | expectedAsString
      ${input}      | ${1}         | ${undefined}      | ${'2019-07-15T00:00:00.000Z'}
      ${input}      | ${-1}        | ${undefined}      | ${'2019-07-17T00:00:00.000Z'}
      ${input}      | ${0}         | ${undefined}      | ${'2019-07-16T00:00:00.000Z'}
      ${input}      | ${0.9}       | ${undefined}      | ${'2019-07-15T00:00:00.000Z'}
      ${input}      | ${180}       | ${undefined}      | ${'2019-01-17T01:00:00.000Z'}
      ${input}      | ${180}       | ${{}}             | ${'2019-01-17T01:00:00.000Z'}
      ${input}      | ${180}       | ${{ utc: false }} | ${'2019-01-17T01:00:00.000Z'}
      ${input}      | ${180}       | ${{ utc: true }}  | ${'2019-01-17T00:00:00.000Z'}
    `(
      'when the provided date is $inputAsString, numberOfDays is $numberOfDays, and the options parameter is $options, returns $expectedAsString',
      ({ inputAsString, numberOfDays, options, expectedAsString }) => {
        const inputDate = new Date(inputAsString);
        const actual = datetimeUtility.nDaysBefore(inputDate, numberOfDays, options);

        expect(actual.toISOString()).toBe(expectedAsString);
      },
    );
  });

  describe('nWeeksAfter', () => {
    const input = '2021-07-16T00:00:00.000Z';

    it.each`
      inputAsString | numberOfWeeks | options           | expectedAsString
      ${input}      | ${1}          | ${undefined}      | ${'2021-07-23T00:00:00.000Z'}
      ${input}      | ${3}          | ${undefined}      | ${'2021-08-06T00:00:00.000Z'}
      ${input}      | ${-1}         | ${undefined}      | ${'2021-07-09T00:00:00.000Z'}
      ${input}      | ${0}          | ${undefined}      | ${'2021-07-16T00:00:00.000Z'}
      ${input}      | ${0.6}        | ${undefined}      | ${'2021-07-20T00:00:00.000Z'}
      ${input}      | ${18}         | ${undefined}      | ${'2021-11-19T01:00:00.000Z'}
      ${input}      | ${18}         | ${{}}             | ${'2021-11-19T01:00:00.000Z'}
      ${input}      | ${18}         | ${{ utc: false }} | ${'2021-11-19T01:00:00.000Z'}
      ${input}      | ${18}         | ${{ utc: true }}  | ${'2021-11-19T00:00:00.000Z'}
    `(
      'when the provided date is $inputAsString, numberOfWeeks is $numberOfWeeks, and the options parameter is $options, returns $expectedAsString',
      ({ inputAsString, numberOfWeeks, options, expectedAsString }) => {
        const inputDate = new Date(inputAsString);
        const actual = datetimeUtility.nWeeksAfter(inputDate, numberOfWeeks, options);

        expect(actual.toISOString()).toBe(expectedAsString);
      },
    );
  });

  describe('nWeeksBefore', () => {
    const input = '2021-07-16T00:00:00.000Z';

    it.each`
      inputAsString | numberOfWeeks | options           | expectedAsString
      ${input}      | ${1}          | ${undefined}      | ${'2021-07-09T00:00:00.000Z'}
      ${input}      | ${3}          | ${undefined}      | ${'2021-06-25T00:00:00.000Z'}
      ${input}      | ${-1}         | ${undefined}      | ${'2021-07-23T00:00:00.000Z'}
      ${input}      | ${0}          | ${undefined}      | ${'2021-07-16T00:00:00.000Z'}
      ${input}      | ${0.6}        | ${undefined}      | ${'2021-07-11T00:00:00.000Z'}
      ${input}      | ${20}         | ${undefined}      | ${'2021-02-26T01:00:00.000Z'}
      ${input}      | ${20}         | ${{}}             | ${'2021-02-26T01:00:00.000Z'}
      ${input}      | ${20}         | ${{ utc: false }} | ${'2021-02-26T01:00:00.000Z'}
      ${input}      | ${20}         | ${{ utc: true }}  | ${'2021-02-26T00:00:00.000Z'}
    `(
      'when the provided date is $inputAsString, numberOfWeeks is $numberOfWeeks, and the options parameter is $options, returns $expectedAsString',
      ({ inputAsString, numberOfWeeks, options, expectedAsString }) => {
        const inputDate = new Date(inputAsString);
        const actual = datetimeUtility.nWeeksBefore(inputDate, numberOfWeeks, options);

        expect(actual.toISOString()).toBe(expectedAsString);
      },
    );
  });

  describe('nMonthsAfter', () => {
    // February has 28 days
    const feb2019 = '2019-02-15T00:00:00.000Z';
    // Except in 2020, it had 29 days
    const feb2020 = '2020-02-15T00:00:00.000Z';
    // April has 30 days
    const apr2020 = '2020-04-15T00:00:00.000Z';
    // May has 31 days
    const may2020 = '2020-05-15T00:00:00.000Z';
    // November 1, 2020 was the day Daylight Saving Time ended in 2020 (in the US)
    const oct2020 = '2020-10-15T00:00:00.000Z';

    it.each`
      inputAsString | numberOfMonths | options           | expectedAsString
      ${feb2019}    | ${1}           | ${undefined}      | ${'2019-03-14T23:00:00.000Z'}
      ${feb2020}    | ${1}           | ${undefined}      | ${'2020-03-14T23:00:00.000Z'}
      ${apr2020}    | ${1}           | ${undefined}      | ${'2020-05-15T00:00:00.000Z'}
      ${may2020}    | ${1}           | ${undefined}      | ${'2020-06-15T00:00:00.000Z'}
      ${may2020}    | ${12}          | ${undefined}      | ${'2021-05-15T00:00:00.000Z'}
      ${may2020}    | ${-1}          | ${undefined}      | ${'2020-04-15T00:00:00.000Z'}
      ${may2020}    | ${0}           | ${undefined}      | ${may2020}
      ${may2020}    | ${0.9}         | ${undefined}      | ${may2020}
      ${oct2020}    | ${1}           | ${undefined}      | ${'2020-11-15T01:00:00.000Z'}
      ${oct2020}    | ${1}           | ${{}}             | ${'2020-11-15T01:00:00.000Z'}
      ${oct2020}    | ${1}           | ${{ utc: false }} | ${'2020-11-15T01:00:00.000Z'}
      ${oct2020}    | ${1}           | ${{ utc: true }}  | ${'2020-11-15T00:00:00.000Z'}
    `(
      'when the provided date is $inputAsString, numberOfMonths is $numberOfMonths, and the options parameter is $options, returns $expectedAsString',
      ({ inputAsString, numberOfMonths, options, expectedAsString }) => {
        const inputDate = new Date(inputAsString);
        const actual = datetimeUtility.nMonthsAfter(inputDate, numberOfMonths, options);

        expect(actual.toISOString()).toBe(expectedAsString);
      },
    );
  });

  describe('nMonthsBefore', () => {
    // The previous month (February) has 28 days
    const march2019 = '2019-03-15T00:00:00.000Z';
    // Except in 2020, it had 29 days
    const march2020 = '2020-03-15T00:00:00.000Z';
    // The previous month (April) has 30 days
    const may2020 = '2020-05-15T00:00:00.000Z';
    // The previous month (May) has 31 days
    const june2020 = '2020-06-15T00:00:00.000Z';
    // November 1, 2020 was the day Daylight Saving Time ended in 2020 (in the US)
    const nov2020 = '2020-11-15T00:00:00.000Z';

    it.each`
      inputAsString | numberOfMonths | options           | expectedAsString
      ${march2019}  | ${1}           | ${undefined}      | ${'2019-02-15T01:00:00.000Z'}
      ${march2020}  | ${1}           | ${undefined}      | ${'2020-02-15T01:00:00.000Z'}
      ${may2020}    | ${1}           | ${undefined}      | ${'2020-04-15T00:00:00.000Z'}
      ${june2020}   | ${1}           | ${undefined}      | ${'2020-05-15T00:00:00.000Z'}
      ${june2020}   | ${12}          | ${undefined}      | ${'2019-06-15T00:00:00.000Z'}
      ${june2020}   | ${-1}          | ${undefined}      | ${'2020-07-15T00:00:00.000Z'}
      ${june2020}   | ${0}           | ${undefined}      | ${june2020}
      ${june2020}   | ${0.9}         | ${undefined}      | ${'2020-05-15T00:00:00.000Z'}
      ${nov2020}    | ${1}           | ${undefined}      | ${'2020-10-14T23:00:00.000Z'}
      ${nov2020}    | ${1}           | ${{}}             | ${'2020-10-14T23:00:00.000Z'}
      ${nov2020}    | ${1}           | ${{ utc: false }} | ${'2020-10-14T23:00:00.000Z'}
      ${nov2020}    | ${1}           | ${{ utc: true }}  | ${'2020-10-15T00:00:00.000Z'}
    `(
      'when the provided date is $inputAsString, numberOfMonths is $numberOfMonths, and the options parameter is $options, returns $expectedAsString',
      ({ inputAsString, numberOfMonths, options, expectedAsString }) => {
        const inputDate = new Date(inputAsString);
        const actual = datetimeUtility.nMonthsBefore(inputDate, numberOfMonths, options);

        expect(actual.toISOString()).toBe(expectedAsString);
      },
    );
  });
});

describe('approximateDuration', () => {
  it.each`
    seconds
    ${null}
    ${{}}
    ${[]}
    ${-1}
  `('returns a blank string for seconds=$seconds', ({ seconds }) => {
    expect(datetimeUtility.approximateDuration(seconds)).toBe('');
  });

  it.each`
    seconds   | approximation
    ${0}      | ${'less than a minute'}
    ${25}     | ${'less than a minute'}
    ${45}     | ${'1 minute'}
    ${90}     | ${'1 minute'}
    ${100}    | ${'1 minute'}
    ${150}    | ${'2 minutes'}
    ${220}    | ${'3 minutes'}
    ${3000}   | ${'about 1 hour'}
    ${30000}  | ${'about 8 hours'}
    ${100000} | ${'1 day'}
    ${180000} | ${'2 days'}
  `('converts $seconds seconds to $approximation', ({ seconds, approximation }) => {
    expect(datetimeUtility.approximateDuration(seconds)).toBe(approximation);
  });
});

describe('localTimeAgo', () => {
  beforeEach(() => {
    document.body.innerHTML = `<time title="some time" datetime="2020-02-18T22:22:32Z">1 hour ago</time>`;
  });

  it.each`
    timeagoArg | title
    ${false}   | ${'some time'}
    ${true}    | ${'Feb 18, 2020 10:22pm GMT+0000'}
  `('converts $seconds seconds to $approximation', ({ timeagoArg, title }) => {
    const element = document.querySelector('time');
    datetimeUtility.localTimeAgo($(element), timeagoArg);

    jest.runAllTimers();

    expect(element.getAttribute('title')).toBe(title);
  });
});

describe('dateFromParams', () => {
  it('returns the expected date object', () => {
    const expectedDate = new Date('2019-07-17T00:00:00.000Z');
    const date = datetimeUtility.dateFromParams(2019, 6, 17);

    expect(date.getYear()).toBe(expectedDate.getYear());
    expect(date.getMonth()).toBe(expectedDate.getMonth());
    expect(date.getDate()).toBe(expectedDate.getDate());
  });
});

describe('differenceInSeconds', () => {
  const startDateTime = new Date('2019-07-17T00:00:00.000Z');

  it.each`
    startDate                               | endDate                                 | expected
    ${startDateTime}                        | ${new Date('2019-07-17T00:00:00.000Z')} | ${0}
    ${startDateTime}                        | ${new Date('2019-07-17T12:00:00.000Z')} | ${43200}
    ${startDateTime}                        | ${new Date('2019-07-18T00:00:00.000Z')} | ${86400}
    ${new Date('2019-07-18T00:00:00.000Z')} | ${startDateTime}                        | ${-86400}
  `('returns $expected for $endDate - $startDate', ({ startDate, endDate, expected }) => {
    expect(datetimeUtility.differenceInSeconds(startDate, endDate)).toBe(expected);
  });
});

describe('differenceInMonths', () => {
  const startDateTime = new Date('2019-07-17T00:00:00.000Z');

  it.each`
    startDate                               | endDate                                 | expected
    ${startDateTime}                        | ${startDateTime}                        | ${0}
    ${startDateTime}                        | ${new Date('2019-12-17T12:00:00.000Z')} | ${5}
    ${startDateTime}                        | ${new Date('2021-02-18T00:00:00.000Z')} | ${19}
    ${new Date('2021-02-18T00:00:00.000Z')} | ${startDateTime}                        | ${-19}
  `('returns $expected for $endDate - $startDate', ({ startDate, endDate, expected }) => {
    expect(datetimeUtility.differenceInMonths(startDate, endDate)).toBe(expected);
  });
});

describe('differenceInMilliseconds', () => {
  const startDateTime = new Date('2019-07-17T00:00:00.000Z');

  it.each`
    startDate                               | endDate                                           | expected
    ${startDateTime.getTime()}              | ${new Date('2019-07-17T00:00:00.000Z')}           | ${0}
    ${startDateTime}                        | ${new Date('2019-07-17T12:00:00.000Z').getTime()} | ${43200000}
    ${startDateTime}                        | ${new Date('2019-07-18T00:00:00.000Z').getTime()} | ${86400000}
    ${new Date('2019-07-18T00:00:00.000Z')} | ${startDateTime.getTime()}                        | ${-86400000}
  `('returns $expected for $endDate - $startDate', ({ startDate, endDate, expected }) => {
    expect(datetimeUtility.differenceInMilliseconds(startDate, endDate)).toBe(expected);
  });
});

describe('dateAtFirstDayOfMonth', () => {
  const date = new Date('2019-07-16T12:00:00.000Z');

  it('returns the date at the first day of the month', () => {
    const startDate = datetimeUtility.dateAtFirstDayOfMonth(date);
    const expectedStartDate = new Date('2019-07-01T12:00:00.000Z');

    expect(startDate).toStrictEqual(expectedStartDate);
  });
});

describe('datesMatch', () => {
  const date = new Date('2019-07-17T00:00:00.000Z');

  it.each`
    date1   | date2                                   | expected
    ${date} | ${new Date('2019-07-17T00:00:00.000Z')} | ${true}
    ${date} | ${new Date('2019-07-17T12:00:00.000Z')} | ${false}
  `('returns $expected for $date1 matches $date2', ({ date1, date2, expected }) => {
    expect(datetimeUtility.datesMatch(date1, date2)).toBe(expected);
  });
});

describe('format24HourTimeStringFromInt', () => {
  const expectedFormattedTimes = [
    [0, '00:00'],
    [2, '02:00'],
    [6, '06:00'],
    [9, '09:00'],
    [10, '10:00'],
    [16, '16:00'],
    [22, '22:00'],
    [32, ''],
    [NaN, ''],
    ['Invalid Int', ''],
    [null, ''],
    [undefined, ''],
  ];

  expectedFormattedTimes.forEach(([timeInt, expectedTimeStringIn24HourNotation]) => {
    it(`formats ${timeInt} as ${expectedTimeStringIn24HourNotation}`, () => {
      expect(datetimeUtility.format24HourTimeStringFromInt(timeInt)).toBe(
        expectedTimeStringIn24HourNotation,
      );
    });
  });
});

describe('getOverlapDateInPeriods', () => {
  const start = new Date(2021, 0, 11);
  const end = new Date(2021, 0, 13);

  describe('when date periods overlap', () => {
    const givenPeriodLeft = new Date(2021, 0, 11);
    const givenPeriodRight = new Date(2021, 0, 14);

    it('returns an overlap object that contains the amount of days overlapping, the amount of hours overlapping, start date of overlap and end date of overlap', () => {
      expect(
        datetimeUtility.getOverlapDateInPeriods(
          { start, end },
          { start: givenPeriodLeft, end: givenPeriodRight },
        ),
      ).toEqual({
        daysOverlap: 2,
        hoursOverlap: 48,
        overlapStartDate: givenPeriodLeft.getTime(),
        overlapEndDate: end.getTime(),
      });
    });
  });

  describe('when date periods do not overlap', () => {
    const givenPeriodLeft = new Date(2021, 0, 9);
    const givenPeriodRight = new Date(2021, 0, 10);

    it('returns an overlap object that contains a 0 value for days overlapping', () => {
      expect(
        datetimeUtility.getOverlapDateInPeriods(
          { start, end },
          { start: givenPeriodLeft, end: givenPeriodRight },
        ),
      ).toEqual({ daysOverlap: 0 });
    });
  });

  describe('when date periods contain an invalid Date', () => {
    const startInvalid = new Date(NaN);
    const endInvalid = new Date(NaN);
    const error = __('Invalid period');

    it('throws an exception when the left period contains an invalid date', () => {
      expect(() =>
        datetimeUtility.getOverlapDateInPeriods({ start, end }, { start: startInvalid, end }),
      ).toThrow(error);
    });

    it('throws an exception when the right period contains an invalid date', () => {
      expect(() =>
        datetimeUtility.getOverlapDateInPeriods({ start, end }, { start, end: endInvalid }),
      ).toThrow(error);
    });
  });
});

describe('isToday', () => {
  const today = new Date();
  it.each`
    date                                    | expected | negation
    ${today}                                | ${true}  | ${'is'}
    ${new Date('2021-01-21T12:00:00.000Z')} | ${false} | ${'is NOT'}
  `('returns $expected as $date $negation today', ({ date, expected }) => {
    expect(datetimeUtility.isToday(date)).toBe(expected);
  });
});

describe('getStartOfDay', () => {
  beforeEach(() => {
    timezoneMock.register('US/Eastern');
  });

  afterEach(() => {
    timezoneMock.unregister();
  });

  it.each`
    inputAsString                      | options           | expectedAsString
    ${'2021-01-29T18:08:23.014Z'}      | ${undefined}      | ${'2021-01-29T05:00:00.000Z'}
    ${'2021-01-29T13:08:23.014-05:00'} | ${undefined}      | ${'2021-01-29T05:00:00.000Z'}
    ${'2021-01-30T03:08:23.014+09:00'} | ${undefined}      | ${'2021-01-29T05:00:00.000Z'}
    ${'2021-01-28T18:08:23.014-10:00'} | ${undefined}      | ${'2021-01-28T05:00:00.000Z'}
    ${'2021-01-28T18:08:23.014-10:00'} | ${{}}             | ${'2021-01-28T05:00:00.000Z'}
    ${'2021-01-28T18:08:23.014-10:00'} | ${{ utc: false }} | ${'2021-01-28T05:00:00.000Z'}
    ${'2021-01-28T18:08:23.014-10:00'} | ${{ utc: true }}  | ${'2021-01-29T00:00:00.000Z'}
  `(
    'when the provided date is $inputAsString and the options parameter is $options, returns $expectedAsString',
    ({ inputAsString, options, expectedAsString }) => {
      const inputDate = new Date(inputAsString);
      const actual = datetimeUtility.getStartOfDay(inputDate, options);

      expect(actual.toISOString()).toEqual(expectedAsString);
    },
  );
});
