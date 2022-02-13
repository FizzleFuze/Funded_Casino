return {
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
PlaceObj('ModItemOptionToggle', {
	'name', "ShowReport",
	'comment', "show daily report",
	'DisplayName', "Show Daily Report",
	'Help', "Show a message with a daily report of casino income across the colony",
	'DefaultValue', true,
}),
}

