*! version 2.0.0, 09.01.2018
//version 1.2, 26.02.2015, Anna Chaimani

program sucra
	syntax [varlist], [COMPare(varlist) NOMVmeta ///
	Stats(string asis) RProbabilities(string asis) RANKOGrams ///
	Names(string asis) LABels(string asis) NOPLot NOTABle LCOLor(string) ///
	LPATtern(string) REVerse TITle(string asis) ORDER PSCORE MIN MAX ///
	LEAGUEtable EXPort(string asis) SORT(string asis)]
		
	preserve
		
	if "`pscore'"!="" & "`nomvmeta'"!=""{
		di as err "Option {it:pscore} may not be combined with option {it:nomvmeta}"
		exit
	}
	if "`pscore'"!="" & "`rankograms'"!=""{
		di as err "Option {it:pscore} may not be combined with option {it:rankograms}"
		exit
	}	
	if "`pscore'"!="" & "`compare'"!=""{
		di as err "Option {it:pscore} may not be combined with option {it:compare()}"
		exit
	}	
	if "`pscore'"!="" & "`min'"=="" & "`max'"==""{
		di as err "Option {it:pscore} requires option {it:min/max}"
		exit
	}	
	if "`min'"!="" & "`max'"!=""{
		di as err "Option {it:max} may not be combined with option {it:min}"
		exit
	}	
	if "`pscore'"=="" & "`leaguetable'"!=""{
		di as err "Option {it:leaguetable} requires option {it:pscore}"
		exit
	}	
	if `"`sort'"'!="" & "`leaguetable'"==""{
		di as err "Option {it:sort} requires option {it:leaguetable}"
		exit
	}	
	if `"`sort'"'!="" & `"`labels'"'==""{
		di as err "Option {it:sort} requires option {it:labels}"
		exit
	}		
	
	tempname _nallobs
	local nallobs=`=_N'
	tempvar _rankstart
	qui gen `_rankstart'=_n
	
	if `"`stats'"'==""{
		cap drop Treatment SUCRA PrBest
		cap drop P_score
	}		
	if "`compare'"!="" & "`compare'"=="`varlist'"{
		di as err "Option {it:compare()} requires a different set of ranking probabilities"
		exit _rc
	}
	if `"`stats'"'!=""{
		if `"`rprobabilities'"'==""{
			di as err "Option {it:stats()} requires option {it:rprobabilities()}"
			exit _rc
		}
		if "`compare'"!=""{
			di as err "Option {it:compare()} may not be combined with option {it:stats()}"
			exit _rc
		}
		if "`nomvmeta'"==""{
			di as err "Option {it:stats()} requires option {it:}"
			exit _rc
		}	
	}
	if `"`names'"'!= ""{
		tokenize `"`names'"'
		forvalues i=1/2 {
			local _n`i' "``i''"
			if "``i''"==""{
				local _n`i' "Model `i'"
			}
		}
	}	
	else {
		local _n1 "Model 1"
		local _n2 "Model 2"
		}
	if "`lcolor'"!= ""{
		tokenize "`lcolor'"
		forvalues i=1/2 {
			local _lc`i' "``i''"
		}
		if "`2'"==""{
			local _lc2 "cranberry"		
		}
	}	
	else{
		local _lc1 "black"
		local _lc2 "cranberry"		
	}
	if "`lpattern'"!= ""{
		tokenize "`lpattern'"
		forvalues i=1/2 {
			local _lp`i' "``i''"
		}
		if "`2'"==""{
			local _lp2 "dash"		
		}
	}
	else{
		local _lp1 "solid"
		local _lp2 "dash"		
	}
	if "`rankograms'" !=""{
		local ytitle "Probabilities"
		local yvar1 _pr1
		local yvar2 _pr21
	}
	else{
		local ytitle "Cumulative Probabilities"
		local yvar1 _cpr1
		local yvar2 _cpr21
	}	
	if `"`stats'"'==""{	
	
		/*input: ranking probabilities as derived from mvmeta*/
	
		if "`nomvmeta'"==""{
			local form:char _dta[network_format]
			if "`form'"!="augmented"{
				di as err "Data not in augmented format, see {helpb network setup} or {helpb network import} for details"
				exit
			}		
			local dim:char _dta[network_dim]
			local ntm=`dim'+1
		
			if "`pscore'"==""{
				tempname _A
				mkmat `varlist',mat(`_A')
				forvalues i=1/`ntm'{
					local j=`i'-1
					mat _R`i'=`_A'[1,`=`j'*`ntm'+1'..`=`i'*`ntm'']
				}
				mat _R=_R1
				forvalues i=2/`ntm'{
					mat _R=_R\_R`i'
					mat drop _R`i'
				}
				qui svmat _R,names(_rank_)
				forvalues i=1/`ntm'{
					qui replace _rank_`i'=_rank_`i'/100
				}
				mat drop _R	
			}
			local ref:char _dta[network_ref]
			local trts:char _dta[network_trtlistnoref]
			tokenize `trts'
			local tr1 `ref'
			forvalues i=1/`dim'{
				local tr`=`i'+1' ``i''
			}			
			cap lab drop _trt
			cap lab drop _ttrt
			lab def _ttrt 1 "`tr1'"
			forvalues i=2/`ntm'{
				lab def _ttrt `i' "`tr`i''",add
			}       
			if `"`labels'"' == ""{
				lab def _trt 1 "`tr1'"
				forvalues i=2/`ntm'{
					lab def _trt `i' "`tr`i''",add
				}       
				forvalues i=1/`ntm'{            
					local lab`i' "`tr`i''"
				}
			}
			if `"`labels'"' != ""{
				tokenize `"`labels'"'
				forvalues i=1/`ntm'{
					if "``i''"!=""{
						local t`i' "``i''"
					}
				}
				lab def _trt 1 "`t1'"
				forvalues i=2/`ntm'{
					lab def _trt `i' "`t`i''",add
				}
				forvalues i=1/`ntm'{            
					local lab`i' "`t`i''"
				}
			}      			
		}
		
		/*input: the columns of the treatment by ranking probabilities matrix*/
		else{
			qui des `varlist'
			unab vart: `varlist'
			local ntm=`: word count `vart''
			if `"`stats'"'==""{
				cap{
					assert `ntm'==_N
				}
				if _rc!=0{
					di as err "Number of treatments not equal to number of possible ranks"
					exit _rc
				}
			}
			tokenize "`vart'"
			forvalues i=1/`ntm'{
				local _t`i' "``i''"
				gen _rank_`i'=`_t`i'' 
			}
		}
		
		/*compare two different sets of ranking probabilities*/
		
		if "`compare'"!=""{
			if "`nomvmeta'"==""{
				tempname _B
				mkmat `compare',mat(`_B')
				forvalues i=1/`ntm'{
					local j=`i'-1
					mat _RR`i'=`_B'[1,`=`j'*`ntm'+1'..`=`i'*`ntm'']
				}
				mat _RR=_RR1
				forvalues i=2/`ntm'{
					mat _RR=_RR\_RR`i'
					mat drop _RR`i'
				}
				qui svmat _RR,names(_rank2_)
				forvalues i=1/`ntm'{
					qui replace _rank2_`i'=_rank2_`i'/100
				}
				mat drop _RR			
			}
			else{
				qui des `compare'
				unab varc: `compare'
				tokenize "`varc'"
				forvalues i=1/`ntm'{
					local _tt`i' "``i''"
					qui rename `_tt`i'' _rank2_`i'
				}
			}
		}
	}
	
	/*input: ranking probabilities as derived from WinBUGS*/
	
	if `"`stats'"'!=""{
		local _rp `"`rprobabilities'"'
		tokenize `"`stats'"'
		forvalues i=1/2 {
			local _s`i' "``i''"
		}
		tempname RANK1
		file open `RANK1' using `"`_s1'"',read
		if `"`_s2'"' != "" {
			tempname RANK2
			file open `RANK2' using `"`_s2'"',read
		}	
		di as text _newline " Warning: Ranking probabilities will be extracted from file(s) {it:`_s1'} {it:`_s2'}"
		qui insheet using `"`_s1'"',clear tab 
		cap rename v2 node
		cap rename v1 node
		qui keep node mean
		qui split node,par([)
		qui keep if node1=="`_rp'"
		
		cap{
			assert _N>0
		}
		if _rc!=0{
			di as err "No ranking probabilities found for Model 1"
			drop _all
			if `old'==1{
				use `_PD'
			}				
			exit _rc				
		}	
		qui split node2,par(,)
		if "`reverse'"!=""{
			qui split node22,par(])
			local node node221
		}
		else{
			local node node21
		}
		qui destring `node',replace
		if "`reverse'"!=""{
			qui destring node21,replace
			qui sort node221 node21
		}
		qui egen _nt=max(`node')
		local ntm=_nt
		forvalues i=1/`ntm' {
			tempname _E`i'
			mkmat mean if `node'==`i',matrix(`_E`i'')
			qui svmat `_E`i'',names(_rank_`i')
			qui rename _rank_`i'1 _rank_`i'
		}
		qui keep _rank*
		qui drop if _rank_1==.
		tempfile RANK1
		qui save `RANK1'
	
		if `"`_s2'"' != "" {
			qui insheet using `"`_s2'"',clear tab 
			cap rename v2 node
			cap rename v1 node
			qui keep node mean
			qui split node,par([)
			qui keep if node1=="`_rp'"
			
			cap{
				assert _N>0
			}
			if _rc!=0{
				di as err "No ranking probabilities found for Model 2"
				drop _all
				if `old'==1{
					use `_PD'
				}				
				exit _rc				
			}	
			qui split node2,par(,)
			if "`reverse'"!=""{
				qui split node22,par(])
				local node node221
			}
			else{
				local node node21
			}			
			qui destring `node',replace
			if "`reverse'"!=""{
				qui destring node21,replace
				qui sort node221 node21
			}
			forvalues i=1/`ntm' {
				tempname _EE`i'
				mkmat mean if `node'==`i',matrix(`_EE`i'')
				qui svmat `_EE`i'',names(_rank2_`i')
				qui rename _rank2_`i'1 _rank2_`i'
			}
			qui keep _rank2*
			qui drop if _rank2_1==.
			tempfile RANK2
			qui save `RANK2'
			qui merge using `RANK1'
		}
	}
	if `"`labels'"' != "" & "`nomvmeta'" != ""{
		tokenize `"`labels'"'
		forvalues i=1/`ntm'{
			local lab`i' "``i''"
			if "``i''"==""{
				local lab`i' "`i'"
			}
		}
	}
	if `"`stats'"'=="" & "`nomvmeta'"!=""{
		forvalues i=1/`ntm'{
			local lab`i' "`_t`i''"
		}
	}
	if `"`labels'"' == "" & `"`stats'"'==""{
		forvalues i=1/`ntm'{
			local lab`i' "`i'"
		}
	}	
	if "`pscore'"==""{
	
	/*calculate the cumulative ranking probabilities and the SUCRA values*/
		
		forvalues i=1/`ntm' {
			qui gen _cum_rank_`i'=sum(_rank_`i') if _n<=`ntm'
			qui gen _p_rank_`i'=_rank_`i'*_n
			qui egen _m_rank_`i'=sum(_p_rank_`i')
			cap gen _cum_rank2_`i'=sum(_rank2_`i') if _n<=`ntm'
			cap gen _p_rank2_`i'=_rank2_`i'*_n
			cap egen _m_rank2_`i'=sum(_p_rank2_`i')
			qui replace _cum_rank_`i'=1 if _cum_rank_`i'>1
			cap replace _cum_rank2_`i'=1 if _cum_rank2_`i'>1		
			qui gen _sums_`i'=(sum(_cum_rank_`i'))/(`ntm'-1) if _n<=`ntm'
			qui gen _sucra_`i'=_sums_`i' if _n==(`ntm'-1) 
			qui egen _suc_`i'=sum(_sucra_`i') if _n<=`ntm'
			qui gen _pbest_`i'=_rank_`i' if _n==1
			qui replace _pbest_`i'=sum(_pbest_`i') if _n<=`ntm'
			cap gen _sums2_`i'=(sum(_cum_rank2_`i'))/(`ntm'-1) if _n<=`ntm'
			cap gen _sucra2_`i'=_sums2_`i' if _n==(`ntm'-1) 
			cap egen _suc2_`i'=sum(_sucra2_`i') if _n<=`ntm'
			cap gen _pbest2_`i'=_rank2_`i' if _n==1	
			cap replace _pbest2_`i'=sum(_pbest2_`i') if _n<=`ntm'
		}	
		qui gen Treatment=_n if _n<=`ntm'
		qui gen _ttreat=Treatment
		if `"`labels'"'!="" | (`"`stats'"'=="" & "`nomvmeta'"!=""){
			qui tostring Treatment,replace
			forvalues i=1/`ntm' {
				qui replace Treatment="`lab`i''" if Treatment=="`i'"
			}
		}
		if "`notable'"== ""{
			tempvar ttorder torder tneworder
			qui gen SUCRA=""
			qui gen PrBest=""
			qui gen MeanRank=""
			forvalues i=1/`ntm' {
				qui replace SUCRA=string(round(_suc_`i'*100,0.1),"%04.1f") if _ttreat==`i'
				qui replace PrBest=string(round(_pbest_`i'*100,0.1),"%04.1f") if _ttreat==`i'
				qui replace MeanRank=string(round(_m_rank_`i',0.1),"%04.1f") if _ttreat==`i'
			}	
			di as res _newline "Treatment Relative Ranking of `_n1'"	
			if "`order'"==""{
				li Treatment SUCRA PrBest MeanRank if SUCRA!="",table div noobs separator(0)
			}
			if "`order'"!=""{
				qui gsort -SUCRA
				qui gen `ttorder'=_n if SUCRA!=""
				li Treatment SUCRA PrBest MeanRank if SUCRA!="",table div noobs separator(0)
			}	
			if `"`export'"'!=""{
				qui export excel Treatment SUCRA PrBest MeanRank if SUCRA!="" using `export' , sheet("SUCRA1") firstrow(var) sheetmodify 
			}
			if "`order'"!=""{
				forvalues i=1/`ntm' {
					local treatorder`i'=`ttorder' in `i'
					local laborder`i'=Treatment in `i'
				}
				lab def _treatorder `treatorder1' "`laborder1'"
				forvalues i=2/`ntm' {
					lab def _treatorder `treatorder`i'' "`laborder`i''",add
				}
				qui encode Treatment,lab(_treatorder) gen(`torder')
				lab var `torder' Treatment
			}	
			qui sort _ttreat
			if "`_s2'" != "" | "`compare'" !=""{
				forvalues i=1/`ntm' {
					qui replace SUCRA=string(round(_suc2_`i'*100,0.1),"%04.1f") if _ttreat==`i'
					qui replace PrBest=string(round(_pbest2_`i'*100,0.1),"%04.1f") if _ttreat==`i'
					qui replace MeanRank=string(round(_m_rank2_`i',0.1),"%04.1f") if _ttreat==`i'
				}		
				di as res _newline "Treatment Relative Ranking of `_n2'"	
				if "`order'"==""{
					li Treatment SUCRA PrBest MeanRank if SUCRA!="",table div noobs separator(0)	
				}
				if "`order'"!=""{
					qui gsort -SUCRA
					li Treatment SUCRA PrBest MeanRank if SUCRA!="",table div noobs separator(0)
				}	
				if `"`export'"'!=""{
					qui export excel Treatment SUCRA PrBest MeanRank if SUCRA!="" using `export' , sheet("SUCRA2") firstrow(var) sheetmodify 
				}				
				qui sort _ttreat
			}
		}
		if "`noplot'"=="" {
			if "`rankograms'"!=""{ 
			
			/*produce rankograms*/
			
				forvalues i=1/`ntm'{
					qui gen _rr`i'=_n if _n<=`ntm'
					qui gen _dd`i'=`i' if _n<=`ntm'
				}
				mkmat _rank_* if _n<=`ntm',mat(_P)
				cap mkmat _rank2_* if _n<=`ntm',mat(_PP)
				mkmat _dd* if _n<=`ntm',mat(_D)
				mkmat _rr* if _n<=`ntm',mat(_R)
				mat _P=vec(_P)
				cap mat _PP=vec(_PP)
				mat _D=vec(_D)
				mat _R=vec(_R)
				local ob=`ntm'^2
			}
			
			/*produce SUCRA plots*/
			
			else{
				forvalues i=1/`ntm'{
					qui replace _cum_rank_`i'=. if _n==`ntm'
					cap replace _cum_rank2_`i'=. if _n==`ntm'
					qui egen _maxcum_`i'=max(_cum_rank_`i') if _n<=`ntm'
					cap egen _maxcum2_`i'=max(_cum_rank2_`i') if _n<=`ntm'
					qui replace _cum_rank_`i'=_maxcum_`i' if _n==`ntm'
					cap replace _cum_rank2_`i'=_maxcum2_`i' if _n==`ntm'
					cap drop _maxcum_`i' _maxcum2_`i'
				}
				local ntmc=`ntm'+2
				cap set obs `ntmc'
				forvalues i=1/`ntmc'{
					cap replace _cum_rank_`i'=1 in `ntmc'
					cap replace _cum_rank2_`i'=1 in `ntmc'
				}			
				forvalues i=1/`ntm'{
					qui gen _rr`i'=_n if _n<=`ntmc'
					qui gen _dd`i'=`i' if _n<=`ntmc'
				}
				forvalues i=1/`ntm'{
					qui replace _rr`i'=`ntm' in `ntmc'
					cap replace _rr2`i'=`ntm' in `ntmc'
				}
				forvalues i=1/`ntm'{
					qui replace _rr`i'=1.5 in `=`ntmc'-1'
					cap replace _rr2`i'=1.5 in `=`ntmc'-1'
				}	
				forvalues i=1/`ntm'{	
					qui sort _rr`i' _cum_rank_`i'
					cap replace _cum_rank_`i' in 2=_cum_rank_`i'[1]
					cap sort _rr2`i' _cum_rank2_`i'
					cap replace _cum_rank2_`i' in 2=_cum_rank2_`i'[1]
				}			
				forvalues i=1/`ntm'{
					qui replace _rr`i'=_rr`i'+0.5 if _rr`i'!=1 & _rr`i'!=`ntm' & _rr`i'!=1.5 & _n<=`ntmc'
					cap replace _rr2`i'=_rr2`i'+0.5 if _rr2`i'!=1 & _rr2`i'!=`ntm' & _rr2`i'!=1.5 & _n<=`ntmc'
				}
				mkmat _cum_rank_* if _n<=`ntmc',mat(_CP)
				cap mkmat _cum_rank2_* if _n<=`ntmc',mat(_CPP)
				mkmat _dd* if _n<=`ntmc',mat(_D)
				mkmat _rr* if _n<=`ntmc',mat(_R)
				mat _CP=vec(_CP)
				cap mat _CPP=vec(_CPP)
				mat _D=vec(_D)
				mat _R=vec(_R)
				local ob=`ntmc'^2
			}
			cap set obs `ob'
			qui svmat _D,names(_tr)
			qui svmat _R,names(_rt)
			cap mat drop _D
			cap mat drop _R
			
			if `"`labels'"'!="" | (`"`stats'"'=="" & "`nomvmeta'"!=""){
				qui tostring _tr,replace
				forvalues i=1/`ntm' {
					qui replace _tr="`lab`i''" if _tr=="`i'"
				}
			}
			cap drop Treatment
			rename _tr1 Treatment
			if "`order'"!=""{
				qui encode Treatment,lab(_treatorder) gen(`tneworder')
				lab var `tneworder' Treatment
			}
			cap svmat _P,names(_pr)
			cap svmat _CP,names(_cpr)
			cap mat drop _P
			cap mat drop _CP

			if "`_s2'" != "" | "`compare'" !=""{
				cap svmat _PP,names(_pr2)
				cap svmat _CPP,names(_cpr2)
				cap mat drop _PP
				cap mat drop _CPP
				cap drop if Treatment=="."
				
				if "`order'"==""{
					sort Treatment _rt `yvar1' `yvar2'
					line `yvar1' _rt if _rt!=.,by(Treatment,title(`"`title'"') rescale) ylab(0(0.2)1) xlab(1(1)`ntm') xtitle(Rank) ytitle("`ytitle'") lcolor(`_lc1') lpattern(`_lp1')||line `yvar2' _rt if _rt!=.,by(Treatment) lcolor(`_lc2') lpattern(`_lp2') legend(label(1 "`_n1'") label(2 "`_n2'")) 
				}
				if "`order'"!=""{
					sort `tneworder' _rt `yvar1' `yvar2'
					line `yvar1' _rt if _rt!=.,by(`tneworder',title(`"`title'"') rescale) ylab(0(0.2)1) xlab(1(1)`ntm') xtitle(Rank) ytitle("`ytitle'") lcolor(`_lc1') lpattern(`_lp1')||line `yvar2' _rt if _rt!=.,by(Treatment) lcolor(`_lc2') lpattern(`_lp2') legend(label(1 "`_n1'") label(2 "`_n2'")) 
				}
			}
			else{
				cap drop if Treatment=="."
				
				if "`order'"==""{
					sort Treatment _rt `yvar1'
					line `yvar1' _rt if _rt!=.,by(Treatment, title(`"`title'"')rescale) ylab(0(0.2)1) xlab(1(1)`ntm') xtitle(Rank) ytitle("`ytitle'") lcolor(`_lc1') lpattern(`_lp1') 
				}
				if "`order'"!=""{
					sort `tneworder' _rt `yvar1'
					line `yvar1' _rt if _rt!=.,by(`tneworder', title(`"`title'"')rescale) ylab(0(0.2)1) xlab(1(1)`ntm') xtitle(Rank) ytitle("`ytitle'") lcolor(`_lc1') lpattern(`_lp1') 
				}			
			}
		}
	}
	if "`pscore'"!=""{
		tempvar probabilities 
		cap drop _Comparison _Effect_Size _LCI _UCI _LPrI _UPrI
		cap drop _treat*
		qui intervalplot,keep notab noplot lab(`labels')
		cap drop _Standard_Error
		qui gen _Standard_Error=(_UCI-_LCI)/(2*abs(invnorm(0.025)))
		if "`max'"!=""{
			qui gen `probabilities'=normal(_Effect_Size/_Standard_Error)
		}
		if "`min'"!=""{
			qui gen `probabilities'=1-normal(_Effect_Size/_Standard_Error)
		}		
		if `"`labels'"'!=""{
			qui split _Comparison,par(" vs ") gen(_treat)
		}
		else{
			qui split _Comparison,par(" vs ") gen(_treat)
			qui replace _treat2="ref" if _treat2=="" & _treat1!=""
		}	
		tempvar t11 t22
		qui gen `t11'=_treat1
		qui gen `t22'=_treat2	
		qui drop _treat1 _treat2
		local treat`ntm'=`t22' in 1
		forvalues i=1/`=`ntm'-1'{
			local treat`i'=`t11' in `=`ntm'-`i''
		}		
		forvalues i=1/`ntm'{
			tempvar tt`i'
			qui gen `tt`i''=.
		}
		
		forvalues i=2/`ntm'{
			forvalues j=1/`=`i'-1'{
				local prob`i'_`j'=`probabilities' in `=(`i'-`j')+(`j'-1)*`ntm'-((`j'-1)/2)*`j''
				local invprob`i'_`j'=1-`prob`i'_`j''
				local sprob`i'_`j'=string(round(`prob`i'_`j''*100,0.1),"%9.1f")
				local sinvprob`i'_`j'=string(round(`invprob`i'_`j''*100,0.1),"%9.1f")
			}
		}
		forvalues i=1/`ntm'{
			forvalues j=`=`i'+1'/`ntm'{
				qui replace `tt`i'' in `j'=`prob`=`ntm'-`i'+1'_`=`ntm'-`j'+1'' if `tt`i''==.
				qui replace `tt`j'' in `i'=`invprob`=`ntm'-`i'+1'_`=`ntm'-`j'+1'' if `tt`j''==.			
			}
		}	
		tempvar ord
		qui gen P_score=""
		qui gen Treatment=""
		qui gen `ord'=.
		forvalues i=1/`ntm'{
			tempvar psc`i' spsc`i'
			qui egen `psc`i''=sum(`tt`i'')
			qui replace `psc`i''=`psc`i''/(`ntm'-1)
			gen `spsc`i''=string(round(`psc`i''*100,0.1),"%04.1f")
			local pscore`i'=`spsc`i'' in `i'
			qui replace P_score in `i'="`pscore`i''"
			qui replace Treatment in `i'="`treat`i''"
		}
		forvalues i=1/`ntm'{
			qui replace `ord'=`i' if Treatment=="`lab`i''"
		}
		if "`order'"==""{
			qui sort `ord'
			li Treatment P_score if P_score!="",table div noobs separator(0)	
		}
		if "`order'"!=""{
			qui gsort -P_score
			li Treatment P_score if P_score!="",table div noobs separator(0)
		}
		if `"`export'"'!=""{
			qui export excel Treatment P_score if P_score!="" using `export' , sheet("P-score") firstrow(var) sheetmodify 
		}		
		if "`leaguetable'"!=""{
			restore
			cap drop _treat*
			forvalues i=1/`ntm'{
				qui gen _treat`i'=""
			}			
			if `"`sort'"' != ""{
				tokenize `"`sort'"'
				forvalues i=1/`ntm'{
					local tsort`i' "``i''"
					if "``i''"==""{
						local tsort`i' "`i'"
					}
				}
			}
			
			forvalues i=1/`ntm'{
				if `"`sort'"' == ""{
					qui replace _treat`i' in `i'="`treat`i''"
				}
				if `"`sort'"' != ""{
					qui replace _treat`i' in `i'="`tsort`i''"
				}
			}
			if `"`sort'"' != ""{
				forvalues i=1/`ntm'{
					forvalues j=1/`ntm'{
						if "`treat`i''"=="`tsort`j''"{
							local coin`i'_`j'=1 
						}
						else{
							local coin`i'_`j'=0
						}
					}
				}			
				forvalues i=1/`ntm'{
					forvalues j=`=`i'+1'/`ntm'{
						forvalues c=1/`ntm'{
							forvalues k=1/`ntm'{
								if `coin`i'_`c''==1 & `coin`j'_`k''==1{
									qui replace _treat`c' in `k'="`sprob`=`ntm'-`i'+1'_`=`ntm'-`j'+1''" if _treat`c'==""
									qui replace _treat`k' in `c'="`sinvprob`=`ntm'-`i'+1'_`=`ntm'-`j'+1''" if _treat`k'==""	
								}								
							}
						}
					}
				}
			}
			if `"`sort'"' == ""{
				forvalues i=1/`ntm'{
					forvalues j=`=`i'+1'/`ntm'{
						qui replace _treat`i' in `j'="`sprob`=`ntm'-`i'+1'_`=`ntm'-`j'+1''" if _treat`i'==""
						qui replace _treat`j' in `i'="`sinvprob`=`ntm'-`i'+1'_`=`ntm'-`j'+1''" if _treat`j'==""	
					}
				}			
			}
			if `"`export'"'!=""{
				qui export excel _treat* if _treat1!="" using `export' , sheet("League table") firstrow(var) sheetmodify 
			}				
		}
	}
	
end
