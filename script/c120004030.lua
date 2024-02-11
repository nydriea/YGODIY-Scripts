--虚魅魔灵 「模块整合」桀派
local m=120004030
local cm=_G["c"..m]
function cm.initial_effect(c)
	aux.EnablePendulumAttribute(c)
	
    --这个卡名的灵摆效果1回合只能使用1次。
    --①：自己主要阶段才能发动。自己的手卡·场上的怪兽作为融合素材，把1只电子界族融合怪兽融合召唤。
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_PZONE)
	e1:SetCountLimit(1, m)
	e1:SetTarget(cm.e1tg)
	e1:SetOperation(cm.e1op)
	c:RegisterEffect(e1)

    --这个卡名的怪兽效果1回合只能使用1次。
    --①：这张卡召唤·特殊召唤成功的场合才能发动。从以下效果选1个适用。
    --●从额外卡组把1只表侧表示的电子界族灵摆怪兽加入手卡。
    --●从墓地把1张「虚魅魔灵」魔法·陷阱卡加入手卡。这个卡名的怪兽效果1回合只能使用1次。
    local e2=Effect.CreateEffect(c)
	e2:SetCategory(CATEGORY_DESTROY)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1, m+1)
	e2:SetTarget(cm.e2tg)
	e2:SetOperation(cm.e2op)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)
end

--#region e1
function cm.e1materialFilter(c,e)
	return not c:IsImmuneToEffect(e)
end
function cm.e1fusionMonsterFilter(c,e,tp,m,f,chkf)
	return c:IsType(TYPE_FUSION) and c:IsRace(RACE_CYBERSE) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) and c:CheckFusionMaterial(m,nil,chkf)
end
function cm.e1tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp
		local mg1=Duel.GetFusionMaterial(tp)
		local res=Duel.IsExistingMatchingCard(cm.e1fusionMonsterFilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg1,nil,chkf)
		if not res then
			local ce=Duel.GetChainMaterial(tp)
			if ce~=nil then
				local fgroup=ce:GetTarget()
				local mg2=fgroup(ce,e,tp)
				local mf=ce:GetValue()
				res=Duel.IsExistingMatchingCard(cm.e1fusionMonsterFilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg2,mf,chkf)
			end
		end
		return res
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function cm.e1op(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local mg1=Duel.GetFusionMaterial(tp):Filter(cm.e1materialFilter,nil,e)
	local sg1=Duel.GetMatchingGroup(cm.e1fusionMonsterFilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg1,nil,chkf)
	local mg2=nil
	local sg2=nil
	local ce=Duel.GetChainMaterial(tp)
	if ce~=nil then
		local fgroup=ce:GetTarget()
		mg2=fgroup(ce,e,tp)
		local mf=ce:GetValue()
		sg2=Duel.GetMatchingGroup(cm.e1fusionMonsterFilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg2,mf,chkf)
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
--#endregion e1

--#region e2+e3
function cm.e2exFilter(c)
    return c:IsFaceup() and c:IsType(TYPE_PENDULUM) and c:IsRace(RACE_CYBERSE) and c:IsAbleToHand()
end
function cm.e2graveFilter(c)
    return c:IsType(TYPE_SPELL+TYPE_TRAP) and c:IsSetCard(0xf91) and c:IsAbleToHand()
end
function cm.e2tg(e,tp,eg,ep,ev,re,r,rp,chk)
    local g1=Duel.IsExistingMatchingCard(cm.e2exFilter,tp,LOCATION_EXTRA,0,1,nil)
    local g2=Duel.IsExistingMatchingCard(cm.e2graveFilter,tp,LOCATION_GRAVE,0,1,nil)
	if chk==0 then return g1 or g2 end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_EXTRA+LOCATION_GRAVE)
end
function cm.e2op(e,tp,eg,ep,ev,re,r,rp)
	local g1=Duel.GetMatchingGroup(cm.e2exFilter,tp,LOCATION_EXTRA,0,nil)
	local g2=Duel.GetMatchingGroup(cm.e2graveFilter,tp,LOCATION_GRAVE,0,nil)
	if g1:GetCount()>0 or g2:GetCount()>0 then
		if g1:GetCount()==0 then
            --墓地魔陷
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
            local tg=g2:Select(tp,1,1,nil)
			Duel.SendtoHand(tg,nil,REASON_EFFECT)
		elseif g2:GetCount()==0 then
            --额外灵摆
            Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
            local tg=g1:Select(tp,1,1,nil)
			Duel.SendtoHand(tg,nil,REASON_EFFECT)
		else
			Duel.Hint(HINT_SELECTMSG,tp,0)
			local ac=Duel.SelectOption(tp,aux.Stringid(m,1),aux.Stringid(m,2))
			if ac==0 then
                --额外灵摆
                Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
                local tg=g1:Select(tp,1,1,nil)
                Duel.SendtoHand(tg,nil,REASON_EFFECT)
			else
                --墓地魔陷
                Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
                local tg=g2:Select(tp,1,1,nil)
                Duel.SendtoHand(tg,nil,REASON_EFFECT)
            end
		end
	end
end
--#endregion e2+e3