
local f = CreateFrame('Frame', nil, InterfaceOptionsFramePanelContainer)
f.name = 'AddonMan'
f:Hide()

InterfaceOptions_AddCategory(f)
f:SetScript('OnShow', function()

    local tinsert = table.insert
    local tsort = table.sort
    local sfmt = string.format

    local addon_meta = {
        __index = function(self, k)
            if(k == 'name') then
                local name = GetAddOnInfo(self.index)
                self[name] = name
                return self[name]
            elseif(k == 'loaded') then
                if(IsAddOnLoaded(self.name)) then
                    self.loaded = true
                    return true
                end
                return false
            elseif(k == 'enabled') then
                return select(4, GetAddOnInfo(self.name))
            elseif(k == 'mem') then
                local mem = GetAddOnMemoryUsage(self.name)
                if(mem > 1024) then
                    return sfmt('%.1f Mib', mem/1024)
                else
                    return sfmt('%d Kib', mem)
                end
            elseif(k == 'reason') then
                local reason = select(6, GetAddOnInfo(self.index))
                if(reason ~= 'DISABLED') then
                    return reason
                end
            end
        end,
    }

    local proxy = {}
    local addons = {}
    local showlist = {}

    local num_addons = GetNumAddOns()

    for i = 1, num_addons do
        local info = setmetatable({
            index = i,
        }, addon_meta)

        proxy[info.name] = info
        tinsert(addons, info.name)
    end
    tsort(addons, function(a, b) return a < b end)

    for k, v in ipairs(addons) do
        showlist[k] = v
    end

    local ROWHEIGHT = 20
    local EDGEGAP = 16
    local ROWGAP = 2

    local search = CreateFrame('EditBox', nil, f, 'InputBoxTemplate')
    search:SetHeight(ROWHEIGHT)
    search:SetPoint('TOP', f, 0, -20)
    search:SetPoint('LEFT', f, EDGEGAP, 0)
    search:SetPoint('RIGHT', f, -EDGEGAP, 0)
    search:SetText''

    search.clear = (function()
        local btn = CreateFrame('Button', nil, search)
        btn:SetSize(16, 16)
        btn:SetPoint'RIGHT'

        btn.texture = btn:CreateTexture(nil, 'BORDER')
        btn.texture:SetTexture[[Interface\COMMON\VOICECHAT-MUTED]]
        btn.texture:SetAllPoints()

        btn:SetScript('OnClick', function()
            search:SetText''
            search:ClearFocus()
        end)
        return btn
    end)()

    f.rows = (function()
        local check_onclick = function(self)
            local addon = self:GetParent().addon
            local enable = self:GetChecked()
            if(enabled) then
                --EnableAddOn(addon)
            else
                --DisableAddOn(addon)
            end
            f.refresh()
        end

        local load_onclick = function(self)
            local addon = self:GetParent().addon
            LoadAddOn(addon)
            f.refresh()
        end

        local rows = {}

        for i = 1, 16 do
            local row = CreateFrame('Button', nil, f)
            rows[i] = row

            local anchor = rows[i-1] or search
            if(anchor == search) then
                row:SetPoint('TOP', anchor, 'BOTTOM', 0, -8)
                row:SetPoint('RIGHT', anchor, -ROWHEIGHT, 0)
            else
                row:SetPoint('TOP', anchor, 'BOTTOM', 0, -ROWGAP)
                row:SetPoint('RIGHT', anchor)
            end
            row:SetPoint('LEFT', anchor)
            row:SetHeight(ROWHEIGHT)

            local check = CreateFrame('CheckButton', nil, row, 'OptionsCheckButtonTemplate')
            check:SetScript('OnClick', check_onclick)
            check:SetSize(ROWHEIGHT+4, ROWHEIGHT+4)
            check:SetPoint'LEFT'
            --check:SetNormalTexture('Interface\\Buttons\\UI-CheckBox-Up')
            --check:SetPushedTexture('Interface\\Buttons\\UI-CheckBox-Down')
            --check:SetHighlightTexture('Interface\\Buttons\\UI-CheckBox-Highlight')
            --check:SetDisabledCheckedTexture('Interface\\Buttons\\UI-CheckBox-Check-Disabled')
            --check:SetCheckedTexture('Interface\\Buttons\\UI-CheckBox-Check')
            row.check = check

            local title = row:CreateFontString(nil, 'BACKGROUND', 'GameFontNormal')
            title:SetPoint('LEFT', check, 'RIGHT', 4, 0)
            row.title = title

            local mem = row:CreateFontString(nil, 'BACKGROUND', 'GameFontNormal')
            mem:SetPoint('CENTER', row)
            mem:SetJustifyH'CENTER'
            mem:SetTextColor(1, 1, 1)
            row.mem = mem

            local reason = row:CreateFontString(nil, 'BACKGROUND', 'GameFontNormal')
            reason:SetPoint('RIGHT', row, -100, 0)
            reason:SetJustifyH'RIGHT'
            reason:SetTextColor(1, 0, 0)
            row.reason = reason

            local loadbtn = CreateFrame('Button', nil, row, 'OptionsButtonTemplate')
            loadbtn:SetSize(60, 22)
            loadbtn:SetPoint'RIGHT'
            loadbtn:SetText'Load'
            loadbtn:SetScript('OnLoad', load_onclick)
            row.load = loadbtn
        end

        return rows
    end)()

    f.offset = 0
    f.refresh = function()
        if(not f:IsVisible()) then return end

        for i, row in ipairs(f.rows) do
            local index = floor(i+f.offset)
            if(index) <= #showlist then
                local name = showlist[index]
                local info = proxy[name]

                row.addon = name
                row.check:SetChecked(info.enabled)
                row.title:SetText(info.name)
                row.mem:SetText(info.loaded and info.mem)
                row.reason:SetText(info.reason)
                if(info.loaded or info.reason) then
                    row.load:Hide()
                else
                    row.load:Show()
                end
                row:Show()
            else
                row:Hide()
            end
        end
    end
    f:SetScript('OnShow', f.refresh)

    f.scroll = (function()
        local scrollbar = CreateFrame('Slider', nil, f)
        scrollbar:SetWidth(16)
        scrollbar:SetPoint('TOP', f.rows[1])
        scrollbar:SetPoint('BOTTOM', f.rows[#f.rows])
        scrollbar:SetPoint('RIGHT', -16, 0)

        scrollbar:SetThumbTexture'Interface\\Buttons\\UI-ScrollBar-Knob'

        local thumb = scrollbar:GetThumbTexture()
        thumb:SetSize(16, 24)
        thumb:SetTexCoord(1/4, 3/4, 1/8, 7/8)

        scrollbar:SetScript('OnValueChanged', function(self, value)
            f.offset = value
            f.refresh()
        end)

        return scrollbar
    end)()

    search:SetScript('OnEscapePressed', search.ClearFocus)
    search:SetScript('OnEnterPressed', search.ClearFocus)
    search:SetAutoFocus(false)
    search:SetScript('OnTextChanged', function(self)
        local str = self:GetText()
        if(str == '') then
            wipe(showlist)
            for k, v in ipairs(addons) do
                showlist[k] = v
            end
        else
            wipe(showlist)
            for k, v in ipairs(addons) do
                if(v:lower():find(str)) then
                    tinsert(showlist, v)
                end
            end
        end

        f.scroll:SetMinMaxValues(0, math.max(0, #showlist - #f.rows))
        f.scroll:SetValue(0)

        f.refresh()
    end)

    f:EnableMouse()
    f:SetScript('OnMouseWheel', function(self, val)
        f.scroll:SetValue(f.scroll:GetValue() - val*#f.rows/2)
    end)

end)

local dataobj = LibStub:GetLibrary('LibDataBroker-1.1'):NewDataObject('AddonMan', {
	type = 'launcher',
	icon = 'Interface\\Icons\\Spell_Nature_NatureBlessing',
	OnClick = function() InterfaceOptionsFrame_OpenToCategory(f) end,
})

SLASH_RELOAD1 = '/rl'
SlashCmdList.RELOAD = ReloadUI

