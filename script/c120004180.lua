--虚魅魔灵 「形象设计」罗诺维
local m=120004180
local cm=_G["c"..m]
function cm.initial_effect(c)
	aux.EnablePendulumAttribute(c)
	
    --①：另一边的自己的灵摆区域没有「虚魅魔灵」卡或「阿格里埃娜」卡存在的场合，这张卡的灵摆刻度变成4。
    local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_CHANGE_LSCALE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCondition(cm.e1con)
	e1:SetValue(4)
	c:RegisterEffect(e1)

    --这个卡名的怪兽效果1回合只能使用1次。
    --①：这张卡被战斗·效果破坏的场合才能发动。
    --下次的准备阶段，从自己的额外卡组把「虚魅魔灵 「形象设计」罗诺维」以外的1只表侧表示的电子界族怪兽加入手卡。
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetRange(LOCATION_MZONE)
    e2:SetCountLimit(1,m)
	e2:SetCondition(cm.e2con)
	e2:SetTarget(cm.e2tg)
	e2:SetOperation(cm.e2op)
	c:RegisterEffect(e2)
end

--#region e1
function cm.e1filter(c)
    return c:IsSetCard(0xf90) or c:IsSetCard(0xf91)
end
function cm.e1con(e)
	return not Duel.IsExistingMatchingCard(cm.e1filter,e:GetHandlerPlayer(),LOCATION_PZONE,0,1,e:GetHandler())
end
--#endregion e1

--#region e2
function cm.e2con(e,tp,eg,ep,ev,re,r,rp)
	return bit.band(r,REASON_EFFECT+REASON_BATTLE)~=0
end
function cm.e2tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,0,0)
end
function cm.e2op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e1:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e1:SetCountLimit(1)
	if Duel.GetCurrentPhase()==PHASE_STANDBY then
		e1:SetLabel(Duel.GetTurnCount())
		e1:SetReset(RESET_PHASE+PHASE_STANDBY,2)
	else
		e1:SetLabel(0)
		e1:SetReset(RESET_PHASE+PHASE_STANDBY)
	end
	e1:SetCondition(cm.e2con2)
	e1:SetTarget(cm.e2tg2)
	e1:SetOperation(cm.e2op2)
	Duel.RegisterEffect(e1,tp)
end
function cm.e2con2(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnCount()~=e:GetLabel()
end
function cm.e2filter2(c)
	return c:IsRace(RACE_CYBERSE) and c:IsType(TYPE_PENDULUM) and c:IsFaceup() and c:IsAbleToHand()
        and not c:IsCode(m)
end
function cm.e2tg2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(cm.e2filter2,tp,LOCATION_EXTRA,0,1,nil) end
end
function cm.e2op2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_CARD,0,m)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,cm.e2filter2,tp,LOCATION_EXTRA,0,1,1,nil)
	Duel.SendtoHand(g,nil,REASON_EFFECT)
end

--#endregion e2