--虚魅魔灵 「用户界面」盖提娅
local m=120004020
local cm=_G["c"..m]
function cm.initial_effect(c)
	aux.AddLinkProcedure(c,cm.linkMaterialFilter,2)
	c:EnableReviveLimit()
	aux.EnablePendulumAttribute(c,false)

    --这个卡名的灵摆效果1回合只能使用1次。
    --①：自己主要阶段才能发动。
    --灵摆区域的这张卡回到卡组，从卡组选1只电子界族灵摆怪兽在自己的灵摆区域放置。
    local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1,m)
	e1:SetTarget(cm.e1tg)
	e1:SetOperation(cm.e1op)
	c:RegisterEffect(e1)

    -- 这个卡名的①的效果1回合只能使用1次。
    -- ①：自己·对方的主要阶段才能发动。
    -- 自己的手卡·场上·灵摆区域的电子界族怪兽卡作为融合素材，把1只融合怪兽融合召唤。
	local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_MZONE)
	e2:SetTarget(cm.e2tg)
	e2:SetOperation(cm.e2op)
	c:RegisterEffect(e2)

    -- ②：怪兽区域的这张卡被破坏的场合或者作为融合·连接素材表侧表示加入额外卡组的场合才能发动。
    -- 这张卡在自己的灵摆区域放置。
    local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_DESTROYED)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCondition(cm.e3con)
	e3:SetTarget(cm.e3tg)
	e3:SetOperation(cm.e3op)
	c:RegisterEffect(e3)
    local e4=e3:Clone()
    e4:SetCode(EVENT_BE_MATERIAL)
    e4:SetCondition(cm.e4con)
	c:RegisterEffect(e4)
end

--#region linkMaterial
function cm.linkMaterialFilter(c)
	return c:IsType(TYPE_PENDULUM) and c:IsRace(RACE_CYBERSE)
	
end
--#endregion linkMaterial

--#region e1
function cm.e1filter(c)
	return c:IsType(TYPE_PENDULUM) and c:IsRace(RACE_CYBERSE) and not c:IsForbidden()
end
function cm.e1tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(cm.e1filter,tp,LOCATION_DECK,0,1,nil) end
end
function cm.e1op(e,tp,eg,ep,ev,re,r,rp)
    local tc=e:GetHandler()
	if Duel.SendtoDeck(tc, nil, SEQ_DECKSHUFFLE, REASON_EFFECT) then
		if not Duel.CheckLocation(tp,LOCATION_PZONE,0) and not Duel.CheckLocation(tp,LOCATION_PZONE,1) then return end
        Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOFIELD)
        local g=Duel.SelectMatchingCard(tp,cm.e1filter,tp,LOCATION_DECK,0,1,1,nil)
        if g:GetCount()>0 then
            Duel.MoveToField(g:GetFirst(),tp,tp,LOCATION_PZONE,POS_FACEUP,true)
        end
    end
end
--#endregion e1

--#region e2
function cm.e2materialFilter(c,e)
	return c:IsCanBeFusionMaterial() and not c:IsImmuneToEffect(e) and c:IsRace(RACE_CYBERSE)
end
function cm.e2pzoneMaterialFilter(c,e)
	return c:IsOnField() and not c:IsImmuneToEffect(e) and c:IsRace(RACE_CYBERSE)
end
function cm.e2fmonsterFilter(c,e,tp,m,f,gc,chkf)
	return c:IsType(TYPE_FUSION) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) and c:CheckFusionMaterial(m,gc,chkf)
end
function cm.e2tg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		local chkf=tp
		local mg1=Duel.GetFusionMaterial(tp):Filter(cm.e2materialFilter,nil,e)
		mg1:Merge(Duel.GetMatchingGroup(cm.e2materialFilter,tp,LOCATION_PZONE,0,nil,e))
		local res=Duel.IsExistingMatchingCard(cm.e2fmonsterFilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg1,nil,c,chkf)
		if not res then
			local ce=Duel.GetChainMaterial(tp)
			if ce~=nil then
				local fgroup=ce:GetTarget()
				local mg2=fgroup(ce,e,tp)
				local mf=ce:GetValue()
				res=Duel.IsExistingMatchingCard(cm.e2fmonsterFilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg2,mf,c,chkf)
			end
		end
		return res
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function cm.e2op(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local chkf=tp
	if not c:IsRelateToEffect(e) or c:IsImmuneToEffect(e) then return end
	local mg1=Duel.GetFusionMaterial(tp):Filter(cm.e2materialFilter,nil,e)
	mg1:Merge(Duel.GetMatchingGroup(cm.e2materialFilter,tp,LOCATION_PZONE,0,nil,e))
	local sg1=Duel.GetMatchingGroup(cm.e2fmonsterFilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg1,nil,c,chkf)
	local mg2=nil
	local sg2=nil
	local ce=Duel.GetChainMaterial(tp)
	if ce~=nil then
		local fgroup=ce:GetTarget()
		mg2=fgroup(ce,e,tp)
		local mf=ce:GetValue()
		sg2=Duel.GetMatchingGroup(cm.e2fmonsterFilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg2,mf,c,chkf)
	end
	if sg1:GetCount()>0 or (sg2~=nil and sg2:GetCount()>0) then
		local sg=sg1:Clone()
		if sg2 then sg:Merge(sg2) end
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local tg=sg:Select(tp,1,1,nil)
		local tc=tg:GetFirst()
		if sg1:IsContains(tc) and (sg2==nil or not sg2:IsContains(tc) or not Duel.SelectYesNo(tp,ce:GetDescription())) then
			local mat1=Duel.SelectFusionMaterial(tp,tc,mg1,nil,chkf)
			tc:SetMaterial(mat1)
			Duel.SendtoGrave(mat1,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
			Duel.BreakEffect()
			Duel.SpecialSummon(tc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
		else
			local mat2=Duel.SelectFusionMaterial(tp,tc,mg2,nil,chkf)
			local fop=ce:GetOperation()
			fop(ce,e,tp,tc,mat2)
		end
		tc:CompleteProcedure()
	end
end
--#endregion e2

--#region e3+e4
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
function cm.e4con(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return (c:IsFaceup() and c:IsLocation(LOCATION_EXTRA)) and r==REASON_FUSION
end
--#endregion e3+e4