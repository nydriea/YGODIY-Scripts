--虚魅魔灵 「精神分析」阿斯蒙蒂斯
local m=120004140
local cm=_G["c"..m]
function cm.initial_effect(c)
	c:EnableReviveLimit()
	aux.EnablePendulumAttribute(c,false)
    --「虚魅魔灵」融合怪兽＋灵摆怪兽
	aux.AddFusionProcFun2(c,cm.fmFilter,aux.FilterBoolFunction(Card.IsFusionType,TYPE_PENDULUM),true)
	
    --这个卡名的灵摆效果1回合只能使用1次。
    --①：另一边的自己的灵摆区域有「虚魅魔灵」卡或「阿格里埃娜」卡存在的场合才能发动。
    --从卡组把1张「虚魅魔灵」卡加入手卡。那之后，这张卡回到卡组。
    local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1,m)
	e1:SetCondition(cm.e1con)
	e1:SetTarget(cm.e1tg)
	e1:SetOperation(cm.e1op)
	c:RegisterEffect(e1)

    --这个卡名的①的怪兽效果1回合只能使用1次。
    --①：自己·对方回合可以发动。得到对方场上1只怪兽的控制权。对方不能应对这个效果把怪兽的效果发动。
    local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_MZONE)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e2:SetCountLimit(1,m+1)
	e2:SetTarget(cm.e2ptg)
	e2:SetOperation(cm.e2pop)
	c:RegisterEffect(e2)

    --②：怪兽区域的这张卡被破坏的场合才能发动。这张卡在自己的灵摆区域放置。
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCondition(cm.e3con)
	e3:SetTarget(cm.e3tg)
	e3:SetOperation(cm.e3op)
	c:RegisterEffect(e3)
end
--#region fusion
function cm.fmFilter(c)
    return c:IsFusionType(TYPE_FUSION) and c:IsFusionSetCard(0xf91)
end
--#endregion fusion

--#region e1
function cm.e1pzoneFilter(c)
	return c:IsSetCard(0xf90) or c:IsSetCard(0xf91)
end
function cm.e1con(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(cm.e1pzoneFilter,tp,LOCATION_PZONE,0,1,e:GetHandler())
end
function cm.e1filter(c)
    return c:IsSetCard(0xf91) and c:IsAbleToHand()
end
function cm.e1tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(cm.e1filter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function cm.e1op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,cm.e1filter,tp,LOCATION_DECK,0,1,1,nil)
	if g:GetCount()>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
        BreakEffect()
        Duel.SendtoDeck(e:GetHandler(),nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
    end
end
--#endregion e1

--#region e2
function cm.e2filter(c,e,tp)
	return c:IsType(TYPE_MONSTER) and c:IsAbleToChangeControler()
end
function cm.e2ptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp) and chkc:IsAbleToChangeControler() end
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_CONTROL,nil,1,0,0)
    Duel.SetChainLimit(cm.e2chlimit)
end
function cm.e2chlimit(e,ep,tp)
	return tp==rp or not e:IsActiveType(TYPE_MONSTER)
end
function cm.e2pop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONTROL)
	local g=Duel.SelectTarget(tp,Card.IsControlerCanBeChanged,tp,0,LOCATION_MZONE,1,1,nil)
    if g:GetCount() then
		Duel.GetControl(g,tp)
    end
end
--#endregion e2

--#region e3
function cm.e3con(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsPreviousLocation(LOCATION_MZONE) and c:IsFaceup()
end
function cm.e3tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1) end
end
function cm.e3op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) then
		Duel.MoveToField(c,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
	end
end
--#endregion e3