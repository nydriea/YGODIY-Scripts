--降临于此刻的旅者
local m=120004150
local cm=_G["c"..m]
function cm.initial_effect(c)
	--这个卡名的卡在1回合只能发动1张，这个卡名的②的效果1回合只能使用1次。
    --①：把手卡1只电子界族灵摆怪兽给对方观看才能发动。
    --从卡组·额外卡组（表侧表示）把1只「阿格里埃娜」怪兽加入手卡。
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,m+EFFECT_COUNT_CODE_OATH)
	e1:SetCost(cm.e1cost)
	e1:SetTarget(cm.e1target)
	e1:SetOperation(cm.e1activate)
	c:RegisterEffect(e1)

    --②：自己场上的「阿格里埃娜」灵摆怪兽卡被对方破坏表侧表示加入额外卡组的场合，
    --把墓地的这张卡除外，以破坏的那1张卡为对象才能发动。
    --那张卡加入手卡或者在自己的灵摆区域放置。
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DAMAGE_STEP+EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,m+1)
	e2:SetCondition(cm.e2con)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(cm.e2tg)
	e2:SetOperation(cm.e2op)
	c:RegisterEffect(e2)
end

--#region e1
function cm.e1filter(c)
	return not c:IsPublic() and c:IsType(TYPE_PENDULUM) and c:IsRace(RACE_CYBERSE)
end
function cm.e1targetDeckFilter(c)
    return c:IsSetCard(0xf90) and c:IsAbleToHand()
end
function cm.e1targetExtraFilter(c)
    return c:IsSetCard(0xf90) and c:IsFaceup() and c:IsAbleToHand()
end
function cm.e1cost(e,tp,eg,ep,ev,re,r,rp,chk)
	e:SetLabel(1)
	if chk==0 then return true end
end
function cm.e1target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		if e:GetLabel()==0 then return false end
		e:SetLabel(0)
		return Duel.IsExistingMatchingCard(cm.e1filter,tp,LOCATION_HAND,0,1,nil) and (Duel.IsExistingMatchingCard(cm.e1targetDeckFilter,tp,LOCATION_DECK,0,1,nil) or Duel.IsExistingMatchingCard(cm.e1targetExtraFilter,tp,LOCATION_EXTRA,0,1,nil))
	end
	e:SetLabel(0)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local g=Duel.SelectMatchingCard(tp,cm.e1filter,tp,LOCATION_HAND,0,1,1,nil)
	Duel.ConfirmCards(1-tp,g)
	Duel.ShuffleHand(tp)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function cm.e1activate(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.GetMatchingGroup(cm.e1targetDeckFilter,tp,LOCATION_DECK,0,1,nil)
    g:Merge(Duel.GetMatchingGroup(cm.e1targetExtraFilter,tp,LOCATION_EXTRA,0,1,nil))
    local tg=g:Select(tp,1,1,nil)
	if tg:GetCount()>0 then
		Duel.SendtoHand(tg,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tg)
	end
end
--#endregion e1

--#region e2
function cm.e2cfilter(c,tp)
	return c:IsReason(REASON_BATTLE+REASON_EFFECT) and c:IsType(TYPE_PENDULUM)
        and c:IsPreviousSetCard(0xf90) and c:IsPreviousControler(tp) and c:IsLocation(LOCATION_EXTRA)
		and c:IsPreviousLocation(LOCATION_ONFIELD) and c:IsPreviousPosition(POS_FACEUP)
end
function cm.e2targetFilter(c,tp)
    return cm.e2cfilter(c,tp) and (c:IsAbleToHand() or (Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1)))
end
function cm.e2con(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(cm.e2cfilter,1,nil,tp)
end
function cm.e2tg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chk==0 then return Duel.IsExistingMatchingCard(cm.e2targetFilter,tp,LOCATION_EXTRA,0,1,1,nil,tp)  end
	if chkc then return eg:IsContains(chkc) and cm.e2cfilter(chkc,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SELECT)
	local g=eg:FilterSelect(tp,cm.e2cfilter,1,1,nil,tp)
	Duel.SetTargetCard(g)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function cm.e2op(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc:IsRelateToEffect(e) then
        local ableth=tc:IsAbleToHand()
        local pzone=Duel.CheckLocation(tp,LOCATION_PZONE,0) or Duel.CheckLocation(tp,LOCATION_PZONE,1)
        if (ableth and pzone) then
            local op=Duel.SelectOption(tp,aux.Stringid(m,0),aux.Stringid(m,1))
            if (op==0) then
                Duel.SendtoHand(tc,nil,REASON_EFFECT)
            else
                Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
            end
        elseif (ableth) then
            Duel.SendtoHand(tc,nil,REASON_EFFECT)
        elseif (pzone) then
            Duel.MoveToField(tc,tp,tp,LOCATION_PZONE,POS_FACEUP,true)
        end
    end
end
--#endregion e2