return {
	PlaceObj('ModItemCode', {
		'name', "CasinoProfit",
		'comment', "Class Def",
		'FileName', "Code/CasinoProfit.lua",
	}),
	PlaceObj('ModItemCode', {
		'name', "FundedCasino",
		'comment', "building code",
		'FileName', "Code/FundedCasino.lua",
	}),
PlaceObj('ModItemOptionChoice', {
	'name', "Gamblers",
	'comment', "Gamblers",
	'DisplayName', "Who gambles funding at casinos?",
	'Help', "Select who gambles funding at the casino:",
	'DefaultValue', "Everyone",
	'ChoiceList', {
		"Everyone",
		"Tourists",
		"Humans (Earth-Born)",
		"Martians (Mars-Born)",
		"Tourists + Humans",
		"Tourists + Martians",
		"Humans + Martians (No Tourists)",
	},
}),
}

