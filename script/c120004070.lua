--虚魅魔灵融合
local m=120004070
local cm=_G["c"..m]
function cm.initial_effect(c)
	--这个卡名的卡在1回合只能发动1张。
    --①：自己的手卡·场上的怪兽作为融合素材，把1只融合怪兽融合召唤。
    --自己灵摆区域有「虚魅魔灵」或「阿格里埃娜」卡存在的场合，
    --也能让自己的额外卡组的表侧表示的电子界族灵摆怪兽的回到卡组作为融合素材。
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,m+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(cm.target)
	e1:SetOperation(cm.activate)
	c:RegisterEffect(e1)
end

function cm.filter1(c,e)
	return not c:IsImmuneToEffect(e)
end
function cm.filter2(c,e,tp,material,f,chkf)
	return c:IsType(TYPE_FUSION) and (not f or f(c))
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false) and c:CheckFusionMaterial(material,nil,chkf)
end
function cm.pzonefilter(c)
	return c:IsSetCard(0xf90) or c:IsSetCard(0xf91)
end
function cm.extraDeckMaterialFilter1(c,e)
	return c:IsType(TYPE_PENDULUM) and c:IsRace(RACE_CYBERSE) and c:IsFaceup() and c:IsCanBeFusionMaterial() 
		and c:IsAbleToDeck() and not c:IsImmuneToEffect(e)
end
function cm.extraDeckMaterialFilter2(c,e)
	return c:IsType(TYPE_PENDULUM) and c:IsRace(RACE_CYBERSE) and c:IsFaceup() and c:IsCanBeFusionMaterial()
		and c:IsAbleToDeck() and not c:IsImmuneToEffect(e)
end
function cm.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp
		local mg1=Duel.GetFusionMaterial(tp)
        if Duel.IsExistingMatchingCard(cm.pzonefilter,tp,LOCATION_PZONE,0,1,nil) then
			mg1:Merge(Duel.GetMatchingGroup(cm.extraDeckMaterialFilter1,tp,LOCATION_EXTRA,0,nil,e))
		end
		local res=Duel.IsExistingMatchingCard(cm.filter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg1,nil,chkf)
		if not res then
			local ce=Duel.GetChainMaterial(tp)
			if ce~=nil then
				local fgroup=ce:GetTarget()
				local mg2=fgroup(ce,e,tp)
				local mf=ce:GetValue()
				res=Duel.IsExistingMatchingCard(cm.filter2,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg2,mf,chkf)
			end
		end
		return res
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function cm.activate(e,tp,eg,ep,ev,re,r,rp)
	local chkf=tp
	local mg1=Duel.GetFusionMaterial(tp):Filter(cm.filter1,nil,e)
	if Duel.IsExistingMatchingCard(cm.pzonefilter,tp,LOCATION_PZONE,0,1,nil) then
		local sg=Duel.GetMatchingGroup(cm.extraDeckMaterialFilter2,tp,LOCATION_EXTRA,0,nil,e)
		if sg:GetCount()>0 then
			mg1:Merge(sg)
		end
	end
	local sg1=Duel.GetMatchingGroup(cm.filter2,tp,LOCATION_EXTRA,0,nil,e,tp,mg1,nil,chkf)
	local mg2=nil
	local sg2=nil
	local ce=Duel.GetChainMaterial(tp)
	if ce~=nil then
		local fgroup=ce:GetTarget()
		mg2=fgroup(ce,e,tp)
		local mf=ce:GetValue()
		sg2=Duel.GetMatchingGroup(cm.filter2,tp,LOCATION_EXTRA,0,nil,e,tp,mg2,mf,chkf)
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
			local rg=mat1:Filter(Card.IsLocation,nil,LOCATION_EXTRA)
			mat1:Sub(rg)
			Duel.SendtoGrave(mat1,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
            Duel.SendtoDeck(rg,nil, SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
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
