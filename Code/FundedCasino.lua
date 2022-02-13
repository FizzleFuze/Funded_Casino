--Copyright
--[[
*******************************************************************************
Fizzle_Fuze's Surviving Mars Mods
Copyright (c) 2022 Fizzle Fuze Enterprises (mods@fizzlefuze.com)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

  If your software can interact with users remotely through a computer
network, you should also make sure that it provides a way for users to
get its source.  For example, if your program is a web application, its
interface could display a "Source" link that leads users to an archive
of the code.  There are many ways you could offer source, and different
solutions will be better for different programs; see section 13 for the
specific requirements.

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU AGPL, see
<https://www.gnu.org/licenses/>.
*******************************************************************************
--]]

--mod name
local ModName = "["..CurrentModDef.title.."]"

--logging variables
local Debugging = false

--print log messages to console and disk
local function PrintLog()
  local MsgLog = SharedModEnv["Fizzle_FuzeLog"]

  if #MsgLog > 0 then
    --print logged messages to console and file
    for _, Msg in ipairs(MsgLog) do
      print(Msg)
    end
    FlushLogFile()

    --reset
    SharedModEnv["Fizzle_FuzeLog"] = {}
    return
  end
end

--setup cross-mod variables for log if needed
if not SharedModEnv["Fizzle_FuzeLog"] then
  SharedModEnv["Fizzle_FuzeLog"] = { ModName.." INFO: First Fizzle_Fuze mod loading!" }
end

--main logging function
function Fizzle_FuzeLogMessage(...)
  local Sev, Arg = nil, {...}
  local SevType = {"INFO", "DEBUG", "WARNING", "ERROR", "CRITICAL"}

  if #Arg == 0 then
    print(ModName,"/?.lua CRITICAL: No error message!")
    FlushLogFile()
    MsgLog[#MsgLog+1] = ModName.."/?.lua CRITICAL: No error message!"
    SharedModEnv["Fizzle_FuzeLog"] = MsgLog
    return
  end

  for _, ST in ipairs(SevType) do
    if Arg[2] == ST then --2nd arg = severity
      Arg[2] = Arg[2]..": "
      Sev = Arg[2]
      break
    end
  end

  if not Sev then
    Sev = "DEBUG: "
    Arg[2] = "DEBUG: "..Arg[2]
  end

  if (Sev == "DEBUG: " and Debugging == false) or (Sev == "INFO: " and Info == false) then
    return
  end

  local MsgLog = SharedModEnv["Fizzle_FuzeLog"]
  local Msg = ModName.."/"..Arg[1]..".lua "
  for i = 2, #Arg do
    Msg = Msg..tostring(Arg[i])
  end
  MsgLog[#MsgLog+1] = Msg
  SharedModEnv["Fizzle_FuzeLog"] = MsgLog

  if (Debugging == true or Info == true) and Sev == "WARNING" or Sev == "ERROR" or Sev == "CRITICAL" then
    PrintLog()
  end
end

--wrapper logging function for this file
local function Log(...)
  Fizzle_FuzeLogMessage("FundedCasino", ...)
end

--translation strings
local Translate = { ID = {}, Text = {} }

Translate.Text['Rollover'] = "Shows an overview of how much profit this casino has made."
Translate.Text['ProfitTitle'] = "Profit"
Translate.Text['ProfitToday'] = "Today's Income"
Translate.Text['ProfitLifetime'] = "Lifetime Income"

--get every string a unique ID
for k, _ in pairs(Translate.Text) do
  Translate.ID[k] = RandomLocId()
  if not Translate.ID[k] then
    Log("ERROR", "Could not find valid translation ID for '", k, "'!")
  end
end

--locals
local CasinoComplexServiceOriginal = CasinoComplex.Service
local Gamblers = "Everyone"
local NoGC = {}

local function UpdateOptions()
  Gamblers = CurrentModOptions:GetProperty("Gamblers")
end

-- Play a game of roulette!
function CasinoComplex:PlayRoulette(unit)
  local Odds = 4637
  local Payout
  local PayoutMod = 1
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
  Payout = Bet * PayoutMod * -1

  --fail out if we can't cover the payout
  if UIColony.funds:GetFunding() < (Payout * -1) then
    return false
  end

  Log("Result, Odds, Bet, Payout, PayoutMod = ", Result, ", ", Odds, ", " , Bet, ", ", Payout, ", ", PayoutMod, ", ")

  --win or lose, change funding and add to log
  if Result <= Odds then
    Log("Loss: ", Payout)
    self:ProfitChange(Payout)
  else
    Log("Win: ", Bet)
    self:ProfitChange(Bet)
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
    if self:PlayRoulette(unit) then
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

-- update profits
function CasinoComplex:ProfitChange(Amount)
  UIColony.funds:ChangeFunding(Amount, "Casino")

  if UICity.labels.CasinoProfit then
    for _, CasinoProfit in ipairs(UICity.labels.CasinoProfit) do
      if CasinoProfit.ParentHandle == self.handle then
        CasinoProfit:ChangeProfit(Amount)
      end
    end
  end

end

function GetCasinoProfitToday(self)
  if UICity.labels.CasinoProfit then
    for _, CasinoProfit in ipairs(UICity.labels.CasinoProfit) do
      if CasinoProfit.ParentHandle == self.handle then
        return InfobarObj.FmtRes(nil, CasinoProfit.TodaysProfit)
      end
    end
  end
end

function GetCasinoProfitLifetime(self)
  if UICity.labels.CasinoProfit then
    for _, CasinoProfit in ipairs(UICity.labels.CasinoProfit) do
      if CasinoProfit.ParentHandle == self.handle then
        return InfobarObj.FmtRes(nil, CasinoProfit.LifetimeProfit)
      end
    end
  end
end

--add profit info to UI for CasinoComplex
local function AddProfit(XTemplate)
  XTemplate = XTemplate or XTemplates.ipBuilding[1][1]

  --add the section if it is missing
  if not table.find(XTemplate, "Id", "sectionCasinoProfit") then
    table.insert(XTemplate, 2, PlaceObj("XTemplateTemplate", {
      "__template", "sectionCasinoProfit",
      "Id", "sectionCasinoProfit"
    }))
  end

  --no dups
  if XTemplates.sectionCasinoProfit then
    return
  end

  --add the info
  PlaceObj("XTemplate", {
    group = "Infopanel Sections",
    id = "sectionCasinoProfit",
    PlaceObj("XTemplateGroup", {
      "__context_of_kind", "CasinoComplex",
    },{
      PlaceObj("XTemplateTemplate", {
        "__template", "InfopanelSection",
        "Icon", "UI/Icons/Sections/Funding.dds",
        "RolloverText", Translate.Text['Rollover'],
        "Title", T(Translate.ID['ProfitTitle'], Translate.Text['ProfitTitle']),
      },{
        PlaceObj("XTemplateTemplate", {
          "__template", "InfopanelText",
          "Text", T{"<str>: <profit>",
                    str = T(Translate.ID['ProfitToday'], Translate.Text['ProfitToday']), profit = GetCasinoProfitToday,
          },
        }),
        PlaceObj("XTemplateTemplate", {
          "__template", "InfopanelText",
          "Text", T{"<str>: <profit>",
                    str = T(Translate.ID['ProfitLifetime'], Translate.Text['ProfitLifetime']), profit = GetCasinoProfitLifetime,
          },
        })
      })
    })
  })

  Log("FINISH AddProfit()")
end

--setup profit objects
local function SetupObj(obj)
  if obj.class ~= "CasinoComplex" then
    Log("WARNING", "Trying to set up profits for ", obj.class, " instead of a casino!")
    return
  end

  local CasinoProfit = PlaceObj("CasinoProfit")
  CasinoProfit.ParentHandle = obj.handle
  table.insert(NoGC, CasinoProfit) -- it's not trash >.>
end

-- event handlers
OnMsg.ModsReloaded = UpdateOptions
OnMsg.NewHour = PrintLog

function OnMsg.NewDay()
  if UICity.labels.CasinoProfit then
    for _, CasinoProfit in ipairs(UICity.labels.CasinoProfit) do
      CasinoProfit.TodaysProfit = 0
    end
  end

  PrintLog()
end

function OnMsg.ApplyModOptions(id)
  if id == CurrentModId then
    UpdateOptions()
  end
end

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

--event handling (something is built)
function OnMsg.ConstructionComplete(obj)
  if obj.class == "CasinoComplex" then
    SetupObj(obj)
  end
end

--event handling (something is demolished)
function OnMsg.Demolished(obj)
  if obj.class == "CasinoComplex" then
    for _, CP in ipairs(UICity.labels.CasinoProfit) do
      if CP.ParentHandle == obj.handle then
        CP:Done()
      end
    end
  end
end

--event handling (saved game loaded)
function OnMsg.LoadGame()
  MapForEach("map", "CasinoComplex", SetupObj)
end

--event handling (mod reloaded)
function OnMsg.ModsReloaded(...)
  if UICity then
    if UICity.labels.CasinoProfit then
      UICity.labels.CasinoProfit = {}
    end

    MapForEach("map", "CasinoComplex", SetupObj)
  end
end

function OnMsg.ClassesPostprocess()
  AddProfit()
end