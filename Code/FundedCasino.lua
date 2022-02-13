local CasinoComplexServiceOriginal = CasinoComplex.Service
local Gamblers = "Everyone"
local ShowReport = false
local DailyIncome = 0
--local TransactionLog = {}

local function MilFormat(x)
    if x then
      if x == 0 then
        return 0
      elseif x > 100000 then
        return string.format("%.1f", (0.0+x) / 1000000)
      else
        return 0.1
      end
    end
end

local function UpdateOptions()
  Gamblers = CurrentModOptions:GetProperty("Gamblers")
  ShowReport = CurrentModOptions:GetProperty("ShowReport")
end


-- event handlers
function OnMsg.NewDay()
  if UICity then
    if UICity.labels.CasinoComplex then
      local msg = "Casino Report:\n $"..MilFormat(DailyIncome).."M Funding!"

      --print to log
      print("Sol "..(UICity.day-1).." "..msg)
      FlushLogFile()

      --show message on screen
      if ShowReport and UICity.day > 1 then
        AddCustomOnScreenNotification("FundedCasino_Casino_Report", "Casino Report!", msg, nil, nil, nil, UICity.city.map_id)
      end
    end
  end

  --reset
  DailyIncome = 0
end

function OnMsg.ApplyModOptions(id)
  if id == CurrentModId then
    UpdateOptions()
  end
end

OnMsg.ModsReloaded = UpdateOptions

function OnMsg.FundingChanged(...)
  if UICity then
  if UICity.labels.CasinoComplex and UIColony.funds:GetFunding() >= 10000000 then
    for i=1, #UICity.labels.CasinoComplex do
      if UICity.labels.CasinoComplex[i].suspended then
        UICity.labels.CasinoComplex[i]:SetSuspended(false)
      end
    end
    end
  end
end

-- Play a game of roulette!
local function PlayRoulette(unit)
  local Odds = 4637
  local PayoutMod = 2
  local Payout = 0
  local Bet = SessionRandom:Random(47500, 52500)
  local Result = SessionRandom:Random(10000)

  -- for the big gamblers
  if unit.traits.Gambler then
    Odds = 1053
    PayoutMod = 8
  end

  -- for the tourists
  if unit.traits.Tourist then
    Bet = Bet * 5
  end

  -- card counter (... WIP - I know roulette doesn't have cards)
  if unit.traits.Genius then
    Odds = Odds * 2.5
  end

  -- calculate potential payout
  Payout = Bet * PayoutMod

  --fail out if we can't cover the payout
  if UIColony.funds:GetFunding() < Payout then
    return false
  end

  --win or lose, change funding and add to log
  if Result <= Odds then
    UIColony.funds:ChangeFunding(Payout, "Casino")
    DailyIncome = DailyIncome - Payout
  else
    UIColony.funds:ChangeFunding(Bet, "Casino")
    DailyIncome = DailyIncome + Bet
  end 

  return true
end

-- new service function for casino
function CasinoComplex:Service(unit, duration)
  local Gamble = false

  --check if this colonist can gamble
  if Gamblers == "Everyone" then
    Gamble = true
  elseif Gamblers == "Tourists" and unit.traits.Tourist then
    Gamble = true
  elseif Gamblers == "Humans (Earth-Born)" and unit.birthplace ~= "Mars" then
    Gamble = true
  elseif Gamblers == "Tourists + Humans" and (unit.traits.Tourists or unit.birthplace ~= "Mars") then
    Gamble = true
  elseif Gamblers == "Tourists + Martians" and (unit.traits.Tourists or unit.birthplace == "Mars") then
    Gamble = true
  elseif Gamblers == "Humans + Martians (No Tourists)" and not(unit.traits.Tourist) then
    Gamble = true
  end

  --If they can, play roulette, otherwise just do old-school casino.
  if Gamble then
    --If we can't cover the payout they take sanity damage and the casino suspends operation
    if PlayRoulette(unit) then
      CasinoComplexServiceOriginal(self, unit, duration)
    else
      if unit.traits.Gambler then
        unit:ChangeSanity(-25 * const.Scale.Stat, "Casino ran out of funding! ")
      else
        unit:ChangeSanity(-10 * const.Scale.Stat, "Casino ran out of funding! ")
      end

      self:SetSuspended(true, "Out of funding")
      --?
      CasinoComplexServiceOriginal(self, unit, duration)
    end
  else
    CasinoComplexServiceOriginal(self, unit, duration)
  end
end

--Changelog
--[[
v1.4
- reduced variance in amounts gambled
- removed report for sol 0
- removed report when there are no casinos built
v1.3
- Daily income of casinos printed to log file
- Added option to show daily income of casinos
- Added daily message for above option
- Colonists bet more
- Gamblers bet the same amount as colonists
- Gamblers play lower odds for higher payout
- Tourists bet more
- Watch out for geniuses
v1.2
- added option to select who can gamble
 - Everyone, Tourists, Humans, Martians, any combo
--]]