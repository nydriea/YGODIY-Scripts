--虚魅魔灵 「密码破译」亚蒙
local m=120004110
local cm=_G["c"..m]
function cm.initial_effect(c)
	aux.EnablePendulumAttribute(c)
	
    --①：1回合1次，另一边的自己的灵摆区域有「虚魅魔灵」卡或者「阿格里埃娜」卡存在的场合才能发动。
    --那张卡破坏，这张卡的灵摆刻度直到回合结束时变成和那张卡的灵摆刻度相同。
    local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1,m)
	e1:SetCondition(cm.e1con)
	e1:SetTarget(cm.e1tg)
	e1:SetOperation(cm.e1op)
	c:RegisterEffect(e1)

    --这个卡名的①的效果1回合只能使用1次。
    --①：把自己场上的怪兽作为作为「虚魅魔灵」怪兽的连接素材的场合，
    --手卡的这张卡也能作为连接素材表侧表示加入自己的额外卡组。
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetCode(EFFECT_EXTRA_LINK_MATERIAL)
	e2:SetRange(LOCATION_HAND)
	e2:SetCountLimit(1,m+1)
	e2:SetValue(cm.e2matval)
	c:RegisterEffect(e2)
	local e2redirect=Effect.CreateEffect(c)
	e2redirect:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e2redirect:SetCode(EFFECT_SEND_REPLACE)
	e2redirect:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2redirect:SetCondition(cm.e2redirectCon)
	e2redirect:SetTarget(cm.e2redirectTg)
	e2redirect:SetValue(cm.e2redirectVal)
	c:RegisterEffect(e2redirect,true)

    --②：这张卡灵摆召唤成功的场合，以场上1张卡为对象才能发动。那张卡破坏。
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCondition(cm.e3con)
	e3:SetTarget(cm.e3tg)
	e3:SetOperation(cm.e3op)
	c:RegisterEffect(e3)
end

--#region e1
function cm.e1pzoneFilter(c)
	return c:IsSetCard(0xf90) or c:IsSetCard(0xf91)
end
function cm.e1con(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(cm.e1pzoneFilter,tp,LOCATION_PZONE,0,1,e:GetHandler())
end
function cm.e1tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(cm.e1filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
    local tc=Duel.GetFirstMatchingCard(cm.e1pzoneFilter,tp,LOCATION_PZONE,0,e:GetHandler())
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,tc,1,tp,LOCATION_PZONE)
end
function cm.e1op(e,tp,eg,ep,ev,re,r,rp)
    local tc=Duel.GetFirstMatchingCard(cm.e1pzoneFilter,tp,LOCATION_PZONE,0,e:GetHandler())
	local c=e:GetHandler()
    if Duel.Destroy(tc,REASON_EFFECT) then
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_CHANGE_LSCALE)
		e1:SetValue(tc:GetLeftScale())
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		c:RegisterEffect(e1)
		local e2=e1:Clone()
		e2:SetCode(EFFECT_CHANGE_RSCALE)
		e2:SetValue(tc:GetRightScale())
		c:RegisterEffect(e2)
    end
end
--#endregion e1

--#region e2
function cm.e2MFilter(c)
	return c:IsLocation(LOCATION_MZONE)
end
function cm.e2ExMFilter(c)
	return c:IsLocation(LOCATION_HAND) and c:IsCode(m)
end
function cm.e2matval(e,lc,mg,c,tp)
	if not lc:IsSetCard(0xf91) then return false,nil end
    local res=not mg or mg:IsExists(cm.e2MFilter,1,nil) and not mg:IsExists(cm.e2ExMFilter,1,nil)
	return true,res
end
function cm.e2redirectCon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsLocation(LOCATION_HAND) and bit.band(c:GetReason(),REASON_MATERIAL+REASON_LINK)==REASON_MATERIAL+REASON_LINK
end
function cm.e2redirectTg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return e:GetHandler():IsAbleToExtra() end
	Duel.SendtoExtraP(e:GetHandler(),nil,REASON_EFFECT)
end
function cm.e2redirectVal(e,c)
	return false
end
--#endregion e2

--#region e3
function cm.e3con(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_PENDULUM)
end
function cm.e3tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsOnField() end
	if chk==0 then return Duel.IsExistingTarget(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectTarget(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function cm.e3op(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.Destroy(tc,REASON_EFFECT)
	end
end
--#endregion e3