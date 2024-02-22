--虚魅魔灵 「场景重建」巴巴托斯
local m=120004160
local cm=_G["c"..m]
function cm.initial_effect(c)
	aux.EnablePendulumAttribute(c)
	
    --这个卡名的灵摆效果1回合只能使用1次。
    --①：自己主要阶段才能发动。从自己卡组上面把3张卡翻开。
    --可以从那之中选1只电子界族灵摆怪兽加入手卡，这张卡的灵摆刻度直到回合结束时变成和那只灵摆怪兽的灵摆刻度相同。
    --剩下的卡用喜欢的顺序回到卡组最下面。
    local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1,m)
	e1:SetTarget(cm.e1tg)
	e1:SetOperation(cm.e1op)
	c:RegisterEffect(e1)

    --这个卡名的怪兽效果1回合只能使用1次。
    --①：对方把怪兽的效果发动时，把这张卡从手卡丢弃才能发动。
    --那个发动无效并破坏。
    --这个效果的发动后，直到下个回合的结束时，自己不能把电子界族灵摆怪兽以外的怪兽的效果发动。
    local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_NEGATE+CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_CHAINING)
	e2:SetProperty(EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DAMAGE_CAL)
	e2:SetRange(LOCATION_HAND)
	e2:SetCondition(cm.e2con)
	e2:SetCost(cm.e2cost)
	e2:SetTarget(cm.e2tg)
	e2:SetOperation(cm.e2op)
	c:RegisterEffect(e2)
end

--#region e1
function cm.e1tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=3 end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,0,LOCATION_DECK)
end
function cm.e1filter(c,e,tp,ft)
	return c:IsType(TYPE_PENDULUM) and c:IsRace(RACE_CYBERSE) and c:IsAbleToHand()
end
function cm.e1op(e,tp,eg,ep,ev,re,r,rp)
	Duel.ConfirmDecktop(tp,3)
	local g=Duel.GetDecktopGroup(tp,3)
    local ct=g:GetCount()
	if ct()>0 and g:IsExists(cm.e1filter,1,nil) and Duel.SelectYesNo(tp,aux.Stringid(m,2)) then
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
        local sg=g:FilterSelect(tp,cm.e1filter,1,1,nil)
        Duel.SendtoHand(sg,nil,REASON_EFFECT)
        Duel.ConfirmCards(1-tp,sg)
        Duel.ShuffleHand(tp)
	end
	if ct>0 then
		Duel.SortDecktop(tp,tp,ct)
		for i=1,ct do
			local mg=Duel.GetDecktopGroup(tp,1)
			Duel.MoveSequence(mg:GetFirst(),SEQ_DECKBOTTOM)
		end
	end
end
--#endregion e1

--#region e2
function cm.e2con(e,tp,eg,ep,ev,re,r,rp)
	return ep~=tp and re:IsActiveType(TYPE_MONSTER) and Duel.IsChainNegatable(ev)
end
function cm.e2cost(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then return c:IsDiscardable() end
	Duel.SendtoGrave(c,REASON_COST+REASON_DISCARD)
end
function cm.e2tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_NEGATE,eg,1,0,0)
	if re:GetHandler():IsDestructable() and re:GetHandler():IsRelateToEffect(re) then
		Duel.SetOperationInfo(0,CATEGORY_DESTROY,eg,1,0,0)
	end
end
function cm.e2op(e,tp,eg,ep,ev,re,r,rp)
	if Duel.NegateActivation(ev) and re:GetHandler():IsRelateToEffect(re) then
		Duel.Destroy(eg,REASON_EFFECT)
	end
    local e1=Effect.CreateEffect(e:GetHandler())
    e1:SetType(EFFECT_TYPE_FIELD)
    e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
    e1:SetCode(EFFECT_CANNOT_ACTIVATE)
    e1:SetTargetRange(1,0)
    e1:SetValue(cm.e2aclimit)
    e1:SetReset(RESET_PHASE+PHASE_END,2)
    Duel.RegisterEffect(e1,tp)
end
function cm.e2aclimit(e,re,tp)
    local c=re:GetHandler()
	return re:IsActiveType(TYPE_MONSTER) and not (c:IsRace(RACE_CYBERSE) and c:IsType(TYPE_PENDULUM))
end

--#endregion e2