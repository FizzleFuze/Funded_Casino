DefineClass.CasinoProfit = {
    __parents = { "Object", },
    default_label = "CasinoProfit",
    ParentHandle = 0,
    TodaysProfit = 0,
    LifetimeProfit = 0,
}

function CasinoProfit:Init()
    if UICity then
        UICity:AddToLabel(self.default_label, self)
    end
end

function CasinoProfit:Done()
    if UICity then
        UICity:RemoveFromLabel(self.default_label, self)
    end
end

function CasinoProfit:ChangeProfit(Amount)
    self.TodaysProfit = self.TodaysProfit + Amount
    self.LifetimeProfit = self.LifetimeProfit + Amount
end