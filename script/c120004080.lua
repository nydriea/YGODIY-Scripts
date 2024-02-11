--虚魅魔灵 「自动生产」彼列
local m=120004080
local cm=_G["c"..m]
function cm.initial_effect(c)
	c:EnableReviveLimit()
	aux.EnablePendulumAttribute(c,false)
    --「虚魅魔灵」怪兽＋灵摆怪兽
	aux.AddFusionProcFun2(c,aux.FilterBoolFunction(Card.IsFusionSetCard,0xf91),aux.FilterBoolFunction(Card.IsFusionType,TYPE_PENDULUM),true)
	
    --①：只要这张卡在灵摆区域存在，自己场上的电子界族灵摆怪兽的攻击力上升800。
    local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_UPDATE_ATTACK)
	e1:SetRange(LOCATION_PZONE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(cm.e1tg)
	e1:SetValue(800)
	c:RegisterEffect(e1)

    --这个卡名的①的效果1回合只能使用1次。
    --①：自己主要阶段才能发动。从卡组选1张「虚魅魔灵」永续魔法·永续陷阱卡在自己场上表侧表示放置。
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCountLimit(1,m)
	e2:SetTarget(cm.e2target)
	e2:SetOperation(cm.e2op)
	c:RegisterEffect(e2)

    --②：只要这张卡在怪兽区域存在，自己魔法·陷阱区域的「虚魅魔灵」卡不会被对方的效果破坏。
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_SZONE,0)
	e3:SetTarget(aux.TargetBoolFunction(Card.IsSetCard,0xf91))
	e3:SetValue(aux.indoval)
	c:RegisterEffect(e3)
end

--#region e1
function cm.e1tg(e,c)
	return c:IsType(TYPE_PENDULUM) and c:IsRace(RACE_CYBERSE)
end
--#endregion e1

--#region e2
function cm.e2filter(c,tp)
	return c:IsType(TYPE_CONTINUOUS) and c:IsSetCard(0xf91)
		and not c:IsForbidden() and c:CheckUniqueOnField(tp)
end
function cm.e2target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_SZONE)>0
		and Duel.IsExistingMatchingCard(cm.e2filter,tp,LOCATION_DECK,0,1,nil,tp) end
end
function cm.e2op(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_SZONE)<=0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
	local tc=Duel.SelectMatchingCard(tp,cm.e2filter,tp,LOCATION_DECK,0,1,1,nil,tp):GetFirst()
	if tc then Duel.MoveToField(tc,tp,tp,LOCATION_SZONE,POS_FACEUP,true) end
end
--#endregion