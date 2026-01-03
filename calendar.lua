#!/usr/bin/env luajit

-- This is based on ISO-8601, except that ISO-8601 thinks weeks start on a Monday, so when a 53rd week exists is inconsistent.
-- This is favorable compared to fucking up the whole system by using the wrong week starting day. Sundays are a transition/exception anyhow.

local day_in_seconds = 60*60*24

local function leftpad(str, len, rep)
  return string.rep(rep or " ", len - #tostring(str)) .. str
end

local function main(start_date)
  local start_time = os.time(start_date)
  start_date = os.date("*t", start_time) -- rebuild to get week day

  -- this is based on the assumption that I'm always starting from day 1 of a month
  if start_date.wday > 4 then
    -- skip this week, it's "part of" the previous month
    start_time = start_time + (7 - start_date.wday + 1) * day_in_seconds
  else
    -- rewind to the beginning of this week
    start_time = start_time - (start_date.wday - 1) * day_in_seconds
  end

  -- find end_time (are we doing 4 or 5 weeks?)
  local start_offset = 7*3 -- how many days after the start_time to check for the end of month
  local day = os.date("*t", start_time + (start_offset - 1) * day_in_seconds) -- subtract one to prevent instant exit
  local end_time
  for i = start_offset, 7*5 do -- up to 5 weeks can appear per month
    local test_day = os.date("*t", start_time + (i - 1) * day_in_seconds)
    if test_day.day < day.day then
      if day.wday > 3 then
        -- fast-forward to the end of this week
        end_time = os.time(day) + (7 - day.wday) * day_in_seconds
      else
        -- skip the last week, it's "part of" the next month
        end_time = os.time(day) - day.wday * day_in_seconds
      end
      break
    else
      day = test_day
    end
  end
  if not end_time then -- I don't know if this is actually required, but I'd rather be careful
    end_time = os.time(day)
  end

  -- create list of date links
  local days = {}
  local current_time = start_time
  while current_time <= end_time do
    days[#days + 1] = os.date("[[%Y-%m-%d\\|%d]]", current_time)
    current_time = current_time + day_in_seconds
  end

  -- create output lines
  -- NOTE the 3 and Wednesday in this area is what allows this to function correctly with Sunday-based weeks IIRC
  --       if this fails to align weeks based on when January 4th occurs, then I was wrong and this needs to be changed
  local lines = {
    os.date("###### [[%Y-%m|%B]]", start_time + 3 * day_in_seconds), -- first Wednesday must be in this month
    "|Week|Sun|Mon|Tue|Wed|Thu|Fri|Sat|",
    "|--|--|--|--|--|--|--|--|",
  }
  start_date = os.date("*t", start_time + 3 * day_in_seconds) -- first Wednesday must be in this year
  local week_offset = math.floor((start_date.yday - 1) / 7) + 1
  for i = 1, #days, 7 do
    local week = week_offset + (i - 1) / 7
    week = "[[" .. start_date.year .. "-W" .. leftpad(week, 2, 0) .. "\\|W" .. leftpad(week, 2, 0) .. "]]"
    lines[#lines + 1] = "|" .. week .. "|" .. days[i] .. "|" .. days[i+1] .. "|" .. days[i+2] .. "|" .. days[i+3] .. "|" .. days[i+4] .. "|" .. days[i+5] .. "|" .. days[i+6] .. "|"
  end

  -- TODO replace with outputting to file ?
  for i = 1, #lines do
    print(lines[i])
  end
end

local start_date = {
  year = 2026,
  month = 1,
  day = 1,
}

-- main(start_date)

assert(arg[1], "Pass a 4-digit year to this script.")
start_date.year = arg[1]

for i = 1, 12 do
  start_date.month = i
  main(start_date)
  print()
end
