--虚魅魔灵的矩阵网络
local m=120004090
local cm=_G["c"..m]
function cm.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)

	--这个卡名的①②的效果1回合只能使用1次。
    --①：以自己的灵摆区域的1张「虚魅魔灵」卡为对象才能发动。
    --那张卡特殊召唤。这个效果的发动后，直到回合结束时自己不是电子界族怪兽不能特殊召唤。
    local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_SZONE)
	e2:SetCountLimit(1,m)
	e2:SetTarget(cm.e2tg)
	e2:SetOperation(cm.e2op)
	c:RegisterEffect(e2)

    --②：自己·对方的准备阶段才能发动。
    --从自己墓地的怪兽以及除外的自己怪兽之中选最多5只电子界族灵摆怪兽表侧表示加入自己的额外卡组。
    --那之后，选自己场上1张「虚魅魔灵」卡破坏。
    local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_TODECK+CATEGORY_DESTROY)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_PHASE+PHASE_STANDBY)
	e3:SetRange(LOCATION_SZONE)
	e3:SetCountLimit(1,m+1)
	e3:SetTarget(cm.e3tg)
	e3:SetOperation(cm.e3op)
	c:RegisterEffect(e3)
end

--#region e2
function cm.e2filter(c,e,tp)
	return c:IsFaceup() and c:IsSetCard(0xf91) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function cm.e2tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chkc then return chkc:IsLocation(LOCATION_PZONE) and cm.e2filter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0 and
         Duel.IsExistingTarget(cm.e2filter,tp,LOCATION_PZONE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,cm.e2filter,tp,LOCATION_PZONE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function cm.e2op(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end
--#endregion e2

--#region e3
function cm.e3filter(c)
	return c:IsFaceup() and c:IsType(TYPE_PENDULUM) and c:IsRace(RACE_CYBERSE) and c:IsAbleToExtra()
end
function cm.e3desFilter(c)
	return c:IsFaceup() and c:IsSetCard(0xf91)
end
function cm.e3tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return Duel.IsExistingMatchingCard(cm.e3filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOEXTRA,nil,5,0,0)
end
function cm.e3op(e,tp,eg,ep,ev,re,r,rp)
    local g=Duel.GetMatchingGroup(cm.e3filter,tp,LOCATION_GRAVE+LOCATION_REMOVED,0,nil)
    if g:GetCount()>0 then
        Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(e:GetHandler():GetCode(),1))
        local sg=g:SelectSubGroup(tp,aux.TRUE,false,1,5)
        Duel.SendtoExtraP(sg,nil,REASON_EFFECT)
        Duel.BreakEffect()
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
        local dg=Duel.SelectMatchingCard(tp,Card.IsSetCard,tp,LOCATION_ONFIELD,0,1,1,nil,0xf91)
        Duel.Destroy(dg,REASON_EFFECT)
    end
end
--#endregion e3