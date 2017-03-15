-- Global Variables
DPSMate.Modules.EDT = {}
DPSMate.Modules.EDT.Hist = "EDTaken"
DPSMate.Options.Options[1]["args"]["enemydamagetaken"] = {
	order = 50,
	type = 'toggle',
	name = DPSMate.L["enemydamagetaken"],
	desc = DPSMate.L["show"].." "..DPSMate.L["enemydamagetaken"]..".",
	get = function() return DPSMateSettings["windows"][DPSMate.Options.Dewdrop:GetOpenedParent().Key]["options"][1]["enemydamagetaken"] end,
	set = function() DPSMate.Options:ToggleDrewDrop(1, "enemydamagetaken", DPSMate.Options.Dewdrop:GetOpenedParent()) end,
}

-- Register the moodule
DPSMate:Register("enemydamagetaken", DPSMate.Modules.EDT, DPSMate.L["enemydamagetaken"])

local tinsert = table.insert
local strformat = string.format

function DPSMate.Modules.EDT:GetSortedTable(arr,k)
	local b, a, total = {}, {}, 0
	for c, v in pairs(arr) do
		local CV = 0
		for cat, val in pairs(v) do
			if cat~="i" then
				CV = CV+val["i"]
			end
		end
		local i = 1
		while true do
			if (not b[i]) then
				tinsert(b, i, CV)
				tinsert(a, i, c)
				break
			else
				if b[i] < CV then
					tinsert(b, i, CV)
					tinsert(a, i, c)
					break
				end
			end
			i=i+1
		end
		total = total + CV
	end
	return b, total, a
end

function DPSMate.Modules.EDT:EvalTable(user, k)
	local a, d, total = {}, {}, 0
	local arr = DPSMate:GetMode(k)
	if arr[user[1]] then
		for cat, val in pairs(arr[user[1]]) do
			local ta, tb = {}, {}
			for ca, va in pairs(val) do
				if ca~="i" then
					local i = 1
					while true do
						if (not tb[i]) then
							tinsert(ta, i, ca)
							tinsert(tb, i, va[13])
							break
						else
							if (tb[i] < va[13]) then
								tinsert(ta, i, ca)
								tinsert(tb, i, va[13])
								break
							end
						end
						i = i + 1
					end
				end
			end
			local i = 1
			while true do
				if (not d[i]) then
					tinsert(a, i, cat)
					tinsert(d, i, {val["i"], ta, tb})
					break
				else
					if (d[i][1] < val["i"]) then
						tinsert(a, i, cat)
						tinsert(d, i, {val["i"], ta, tb})
						break
					end
				end
				i = i + 1
			end
			total=total+val["i"]
		end
	end
	return a, total, d
end

function DPSMate.Modules.EDT:GetSettingValues(arr, cbt, k,ecbt)
	local pt = ""

	local name, value, perc, sortedTable, total, a, p, strt = {}, {}, {}, {}, 0, 0, "", {[1]="",[2]=""}
	if DPSMateSettings["windows"][k]["numberformat"] == 2 or DPSMateSettings["windows"][k]["numberformat"] == 4 then p = "K"; pt="K" end
	sortedTable, total, a = DPSMate.Modules.EDT:GetSortedTable(arr,k)
	for cat, val in pairs(sortedTable) do
		local dmg, tot, sort, dmgr, totr, sortr = DPSMate:FormatNumbers(val, total, sortedTable[1], k)
		if dmg==0 then break end; if totr<=10000 then pt="" end; if dmgr<=10000 then p="" end
		local str = {[1]="",[2]="",[3]="",[4]=""}
		local pname = DPSMate:GetUserById(a[cat])
		if DPSMateSettings["columnsedt"][1] then str[1] = " "..DPSMate:Commas(dmg, k)..p; strt[2] = " "..DPSMate:Commas(tot, k)..pt end
		if DPSMateSettings["columnsedt"][3] then str[2] = " ("..strformat("%.1f", 100*dmgr/totr).."%)" end
		if DPSMateSettings["columnsedt"][2] then str[3] = "("..strformat("%.1f", dmg/cbt)..p..")"; strt[1] = "("..strformat("%.1f", tot/cbt)..pt..")" end
		if DPSMateSettings["columnsedt"][4] then str[4] = " ("..strformat("%.1f", dmg/(ecbt[pname] or cbt))..p..")" end
		tinsert(name, pname)
		tinsert(value, str[3]..str[1]..str[4]..str[2])
		tinsert(perc, 100*(dmgr/sortr))
	end
	return name, value, perc, strt
end

function DPSMate.Modules.EDT:ShowTooltip(user, k)
	if DPSMateSettings["informativetooltips"] then
		local a,b,c = DPSMate.Modules.EDT:EvalTable(DPSMateUser[user], k)
		local ab, abn, p, i = {}, {}, 1, 1
		
		while a[i] do
			p = 1
			while c[i][2][p] do
				if ab[c[i][2][p]] then
					ab[c[i][2][p]] = ab[c[i][2][p]] + c[i][3][p]
				else
					ab[c[i][2][p]] = c[i][3][p]
				end
				p = p + 1
			end
			i = i + 1
		end
		for cat, val in pairs(ab) do
			if val>0 then
				i = 1
				while true do
					if (not abn[i]) then
						tinsert(abn, i, {cat, val})
						break
					else
						if (abn[i][2] < val) then
							tinsert(abn, i, {cat, val})
							break
						end
					end
					i = i + 1
				end
			end
		end
		ab = nil
		
		GameTooltip:AddLine(DPSMate.L["tttop"]..DPSMateSettings["subviewrows"]..DPSMate.L["ttdamage"]..DPSMate.L["ttabilities"])
		for i=1, DPSMateSettings["subviewrows"] do
			if not abn[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMate:GetAbilityById(abn[i][1]), abn[i][2].." ("..strformat("%.2f", 100*abn[i][2]/b).."%)", 1,1,1,1,1,1)
		end
		
		GameTooltip:AddLine(DPSMate.L["tttop"]..DPSMateSettings["subviewrows"]..DPSMate.L["ttattacked"])
		for i=1, DPSMateSettings["subviewrows"] do
			if not a[i] then break end
			GameTooltip:AddDoubleLine(i..". "..DPSMate:GetUserById(a[i]),c[i][1].." ("..strformat("%.2f", 100*c[i][1]/b).."%)",1,1,1,1,1,1)
		end
	end
end

function DPSMate.Modules.EDT:OpenDetails(obj, key, bool)
	if bool then
		DPSMate.Modules.DetailsEDT:UpdateCompare(obj, key, bool)
	else
		DPSMate.Modules.DetailsEDT:UpdateDetails(obj, key)
	end
end

function DPSMate.Modules.EDT:OpenTotalDetails(obj, key)
	DPSMate.Modules.DetailsEDTTotal:UpdateDetails(obj, key)
end

