--虚魅魔灵 「行为归纳」玛帕斯
local m=120004050
local cm=_G["c"..m]
function cm.initial_effect(c)
	aux.EnablePendulumAttribute(c)
	
    --这个卡名的灵摆效果1回合只能使用1次。
    --①：另一边的自己的灵摆区域有「虚魅魔灵」卡或者「阿格里埃娜」卡存在的场合才能发动。
    --这张卡破坏，从自己的卡组·墓地选1只「虚魅魔灵」灵摆怪兽在自己的灵摆区域放置。
    --那之后，自己的灵摆区域的卡全部回到手卡。
    --这个效果发动后，直到回合结束时自己不是电子界族怪兽不能特殊召唤。
    local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1,m)
	e1:SetCondition(cm.e1con)
	e1:SetTarget(cm.e1tg)
	e1:SetOperation(cm.e1op)
	c:RegisterEffect(e1)

    --这个卡名的②的怪兽效果1回合只能使用1次。
    --①：自己的电子界族灵摆怪兽进行战斗的从伤害步骤开始时到伤害计算前，把这张卡从手卡丢弃才能发动。
    --那只怪兽的攻击力直到回合结束时上升1000。
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_ATKCHANGE)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_HAND)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP)
	e2:SetHintTiming(TIMING_DAMAGE_STEP)
	e2:SetCondition(cm.e2con)
	e2:SetCost(cm.e2cost)
	e2:SetOperation(cm.e2op)
	c:RegisterEffect(e2)

    --②：这张卡被战斗·效果破坏的场合发动。给与对方1000伤害。
    local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_DAMAGE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
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
function cm.e1filter(c)
    return c:IsSetCard(0xf91) and c:IsType(TYPE_PENDULUM) and not c:IsForbidden()
end
function cm.e1splimit(e,c)
	return not c:IsRace(RACE_CYBERSE)
end
function cm.e1tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(cm.e1filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_PZONE)
    Duel.SetOperationInfo(0,CATEGORY_DESTROY,e:GetHandler(),1,tp,LOCATION_PZONE)
end
function cm.e1op(e,tp,eg,ep,ev,re,r,rp)
    if Duel.Destroy(e:GetHandler(),REASON_EFFECT) then
		if not Duel.CheckLocation(tp,LOCATION_PZONE,0) and not Duel.CheckLocation(tp,LOCATION_PZONE,1) then return end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
        local g=Duel.SelectMatchingCard(tp,cm.e1filter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
        local tc=g:GetFirst()
        if not tc then return end
        Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,false)
        local e1=Effect.CreateEffect(e:GetHandler())
        e1:SetType(EFFECT_TYPE_FIELD)
        e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
        e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
        e1:SetTargetRange(1,0)
        e1:SetTarget(cm.e1splimit)
        e1:SetReset(RESET_PHASE+PHASE_END)
        Duel.RegisterEffect(e1,tp)
        Duel.BreakEffect()
    end
	Duel.BreakEffect()
	local pg=Duel.GetMatchingGroup(aux.TRUE,tp,LOCATION_PZONE,0,nil)
	if pg:GetCount()>0 then
		Duel.SendtoHand(pg,nil,REASON_EFFECT)
	end
end
--#endregion e1

--#region e2
function cm.e2con(e,tp,eg,ep,ev,re,r,rp)
	local phase=Duel.GetCurrentPhase()
	if phase~=PHASE_DAMAGE or Duel.IsDamageCalculated() then return false end
	local tc=Duel.GetAttackTarget()
	if not tc then return false end
	if tc:IsControler(1-tp) then tc=Duel.GetAttacker() end
	e:SetLabelObject(tc)
	return tc:IsFaceup() and tc:IsType(TYPE_PENDULUM) and tc:IsRace(RACE_CYBERSE) and tc:IsRelateToBattle()
end
function cm.e2cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsDiscardable() end
	Duel.SendtoGrave(e:GetHandler(),REASON_COST+REASON_DISCARD)
end
function cm.e2op(e,tp,eg,ep,ev,re,r,rp)
	local tc=e:GetLabelObject()
	if tc:IsRelateToBattle() and tc:IsFaceup() and tc:IsControler(tp) then
		local e1=Effect.CreateEffect(e:GetHandler())
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(1000)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
		tc:RegisterEffect(e1)
	end
end
--#endregion e2

--#region e3
function cm.e3con(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_EFFECT) or c:IsReason(REASON_BATTLE)
end
function cm.e3tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetTargetPlayer(1-tp)
	Duel.SetTargetParam(1000)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,1000)
end
function cm.e3op(e,tp,eg,ep,ev,re,r,rp)
	local p,d=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER,CHAININFO_TARGET_PARAM)
	Duel.Damage(p,d,REASON_EFFECT)
end
--#endregion