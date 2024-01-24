--时络之阿格里埃娜
local m=120004010
local cm=_G["c"..m]
Duel.LoadScript("AnkoRequire.lua")
function cm.initial_effect(c)
	aux.EnablePendulumAttribute(c)

    --这个卡名的灵摆效果1回合只能使用1次。
    --①：只在这张卡在场上表侧表示存在才有1次，自己主要阶段才能发动。
    --从卡组把1只「时络之阿格里埃娜」以外的电子界族灵摆怪兽加入手卡。
    local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_IGNITION)
    e1:SetProperty(EFFECT_FLAG_NO_TURN_RESET)
	e1:SetCountLimit(1,m)
	e1:SetTarget(cm.e1tg)
	e1:SetOperation(cm.e1op)
	c:RegisterEffect(e1)

	--这个卡名的①②的怪兽效果1回合只能使用1次。
    --①：张卡给与对方战斗伤害时才能发动。
    --选自己1张手卡回到卡组最下面。那之后，自己抽2张。
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_BATTLE_DAMAGE)
	e1:SetCountLimit(1,m+1)
	e2:SetCondition(cm.e2con)
	e2:SetTarget(cm.e2tg)
	e2:SetOperation(cm.e2op)
	c:RegisterEffect(e2)

	--②：这张卡特殊召唤成功的场合才能发动。
	--从额外卡组把1张表侧表示的电子界族灵摆怪兽加入手卡。
	local e3=Effect.CreateEffect(c)
	e3:SetCategory(CATEGORY_SEARCH)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCountLimit(1,m+2)
	e3:SetTarget(cm.e3tg)
	e3:SetOperation(cm.e3op)
	c:RegisterEffect(e3)
end

--#region e1
function cm.e1filter(c)
	return not c:IsCode(m) and c:IsRace(RACE_CYBERSE) and c:IsType(TYPE_PENDULUM) and c:IsAbleToHand()
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
	end
end
--#endregion e1

--#region e2
function cm.e2con(e,tp,eg,ep,ev,re,r,rp)
	return ep~=tp
end
function cm.e2tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_HAND,0)>0 end
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
end
function cm.e2op(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(Card.IsAbleToDeck,tp,LOCATION_HAND,0,nil)
	if #g>0 and Duel.IsPlayerCanDraw(tp,2) then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
		local sg=g:Select(tp,1,1,nil)
		Duel.HintSelection(sg)
		Duel.BreakEffect()
		Duel.SendtoDeck(sg,nil,SEQ_DECKBOTTOM,REASON_EFFECT)
		if sg:GetFirst():IsLocation(LOCATION_DECK) then
			Duel.Draw(tp,2,REASON_EFFECT)
		end
	end
end
--#endregion e2

--#region e3
function cm.e3filter(c)
	return c:IsFaceup() and c:IsRace(RACE_CYBERSE) and c:IsType(TYPE_PENDULUM) and c:IsAbleToHand()
end
function cm.e3tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(cm.e3filter,tp,LOCATION_EXTRA,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_EXTRA)
end
function cm.e3op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,cm.e3filter,tp,LOCATION_EXTRA,0,1,1,nil)
	if g:GetCount()>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
--#endregion e3