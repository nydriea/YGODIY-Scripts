--虚魅魔灵的入侵对抗引擎
local m=120004100
local cm=_G["c"..m]
function cm.initial_effect(c)
	local eActive=Effect.CreateEffect(c)
	eActive:SetType(EFFECT_TYPE_ACTIVATE)
	eActive:SetCode(EVENT_FREE_CHAIN)
	eActive:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	eActive:SetHintTiming(TIMING_DAMAGE_STEP)
	eActive:SetCondition(aux.dscon)
	c:RegisterEffect(eActive)

    --①：「虚魅魔灵的入侵对抗引擎」在自己场上只能有1张表侧表示存在。
	c:SetUniqueOnField(1,0,m)

    --②：1回合1次，对方连锁自己的电子界族灵摆怪兽卡的效果的发动把魔法·陷阱·怪兽的效果发动时才能发动。
    --那个对方的效果无效。
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_CHAINING)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(cm.e1con)
	e1:SetTarget(cm.e1tg)
	e1:SetOperation(cm.e1op)
	c:RegisterEffect(e1)
	local e1clone=e1:Clone()
	e1clone:SetType(EFFECT_TYPE_QUICK_O)
	e1clone:SetRange(LOCATION_SZONE)
	c:RegisterEffect(e1clone)

    --③：1回合1次，自己场上的电子界族灵摆怪兽卡被对方破坏的场合才能发动。选双方场上1张卡破坏。
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCondition(cm.e2con)
	e2:SetTarget(cm.e2tg)
	e2:SetOperation(cm.e2op)
	c:RegisterEffect(e2)
end

--#region e1
function cm.e1con(e,tp,eg,ep,ev,re,r,rp)
	if not Duel.IsChainDisablable(ev) then return false end
	local te,p=Duel.GetChainInfo(ev-1,CHAININFO_TRIGGERING_EFFECT,CHAININFO_TRIGGERING_PLAYER)
	local tc=te:GetHandler()
	return te and tc:IsType(TYPE_PENDULUM) and tc:IsRace(RACE_CYBERSE) and p==tp and rp==1-tp
end
function cm.e1tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_DISABLE,eg,1,0,0)
end
function cm.e1op(e,tp,eg,ep,ev,re,r,rp)
	Duel.NegateEffect(ev)
end
--#endregion e1

--#region e2
function cm.e2filter(c,tp,rp)
	return bit.band(c:GetPreviousTypeOnField(),TYPE_PENDULUM)~=0
		and bit.band(c:GetPreviousRaceOnField(),RACE_CYBERSE)~=0
		and c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsPreviousControler(tp)
		and (c:IsReason(REASON_BATTLE) or (rp==1-tp and c:IsReason(REASON_EFFECT)))
end
function cm.e2con(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(cm.e2filter,1,nil,tp,rp)
end
function cm.e2tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,nil) end
	local g=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,nil)
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,g,1,0,0)
end
function cm.e2op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,aux.TRUE,tp,LOCATION_ONFIELD,LOCATION_ONFIELD,1,1,nil)
	if g:GetCount()>0 then
		Duel.HintSelection(g)
		Duel.Destroy(g,REASON_EFFECT)
	end
end
--#endregion e2