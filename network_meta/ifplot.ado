*! version 2.0.0, 09.01.2018
//version 1.2, 26.02.2015, Anna Chaimani

program ifplot
	syntax varlist(min=5 max=5) [if] [in] , [NOTABle NOPLot TAU2(string) ///
	REML MM EB FIXED RANDOM LABels(string asis) SUMmary CIlevel(string) ///
	PLOTOPTions(string asis) XLABel(string asis) DETails KEEP SEParate EFORM]
	
	preserve
	
	if "`if'"!= ""{
		qui keep `if'
	}
	if "`in'"!= ""{
		qui keep `in'
	}	
	
	local form:char _dta[network_format]
	if "`form'"!="pairs"{
		di as err "Data not in pairs format, see {helpb network setup} or {helpb network import} for details"
		exit
	}
	if "`noplot'"!="" & "`plotoptions'"!="" {
		di as err "Option {it:noplot} may not be combined with option {it:plotoptions()}" 
		exit
	}	
	if "`tau2'"!="comparison" & "`tau2'"!="" & "`tau2'"!="loop"{
		local nettau2=real("`tau2'")
		if `nettau2'==. | `nettau2'<0{
			di _newline
			di as text " {bf:Warning}: option {it:`tau2'} in option {it:tau2} not allowed, reset to default {it:tau2(loop)}"
			local tau2 "loop"
		}
	}
	if "`tau2'"!="loop" & "`tau2'"!=""{
		if "`eb'"!="" {
			di as err "Option {it:eb} may not be combined with option {it:tau2(`tau2')}" 
			exit
		}
		if "`reml'"!="" {
			di as err "Option {it:reml} may not be combined with option {it:tau2(`tau2')}" 
			exit
		}
		if "`mm'"!="" {
			di as err "Option {it:mm} may not be combined with option {it:tau2(`tau2')}" 
			exit
		}	
	}
	if "`tau2'"!="comparison"{
		if "`fixed'"!="" {
			di as err "Option {it:fixed} can be specified only with option {it:tau2(comparison)}" 
			exit
		}
		if "`random'"!="" {
			di as err "Option {it:random} can be specified only with option {it:tau2(comparison)}" 
			exit
		}		
	}	
	
	cap drop _Loop _IF _seIF _z_value _p_value _LCI_IF _UCI_IF
	cap drop _Loop_Heterogeneity	
	local t1:char _dta[network_t1]
	local t2:char _dta[network_t2]
	qui network convert augment
	local dim:char _dta[network_dim]
	qui network convert pairs
	local ntm=`dim'+1
	local ref:char _dta[network_ref]
	local trts:char _dta[network_trtlistnoref]
	tokenize `trts'
	local tr1 `ref'
	forvalues i=1/`dim'{
		local tr`=`i'+1' ``i''
	}
	cap lab drop _trt
	cap lab drop _ttrt
	lab def _trt 1 "`tr1'"
	lab def _ttrt 1 "`tr1'"
	forvalues i=2/`ntm'{
		lab def _ttrt `i' "`tr`i''",add
	}	
	if `"`labels'"' == ""{
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

	tokenize `varlist'
	local y `1'
	local se `2'
	local id `5'

	
	cap{
		drop Loop
		drop IF
		drop seIF
		drop Heterogeneity
		drop z_value
		drop p_value
		drop LCI
		drop UCI
		drop ROR
	}	
	
	if "`reml'" == "" & "`eb'" == ""{
		local meth "mm"
	}
	if "`reml'" != "" {
		local meth "reml"
	}	
	if "`eb'" != "" {
		local meth "eb"
	}
	if "`fixed'" != "" {
		local het "fixedi"
	}
	else{
		local het "randomi"
	} 
	if "`cilevel'" != "" { 
		local cilevel=real("`cilevel'") 
	}
	else{
		local cilevel=95
	}
	local ci=1-(1-(`cilevel'/100))/2
	if `"`plotoptions'"' != "" {
		local plotoptions `plotoptions'
	}
	else{
		local plotoptions ""
	}

	cap {
		assert `y'!=. & `se'!=.
	}
	if _rc!=0 {
		di as err "Missing {it:effect_size} or {it:standard_error} value found" 
		exit
	}	
	cap { 
		assert `se'>=0
	}
	if _rc!=0 {
		di as err "Negative value of standard error found" 
		exit
	}

		
	/*identify all triangular and quadtratic loops in the network*/
	
	qui{
		tempvar tnew1 tnew2 c told1 told2
		qui encode `t1',gen(`told1') lab(_ttrt)
		qui encode `t2',gen(`told2') lab(_ttrt)
		qui gen `tnew1'=min(`told1',`told2')
		qui gen `tnew2'=max(`told1',`told2')
		qui replace `y'=-`y' if `tnew1'==`told1'			
		by `t1' `t2',sort: replace `tnew1'=. if _n>1
		mkmat `tnew1' if `tnew1'!=.,mat(_treat1)
		mkmat `tnew2' if `tnew1'!=.,mat(_treat2)
	}
	if `ntm'>10{
		di as text _newline "Searching for closed loops..."
	}
	
	mata loops()

	qui egen `c'=concat(`t1' `t2'),punct(_)
	qui tab `c',gen(_dc)
	sort `t1' `t2'
	local nc=rowsof(_treat1)
	forvalues i=1/`nc'{
		sort _dc`i'
		local indc`i'="`c'" in `=_N'
	}
	
	local ntr=_ntr
	local nsq=_nsq
	qui scalar drop _ntr _nsq
	if `ntr'>0{
		di as text _newline " * `ntr' triangular loops found"
	}
	if `nsq'>0{
		di as text " * `nsq' quadratic loops found" _newline
	}	
	local text=`=`ntr'+`nsq''
	if `text'<=10{
		local text=90
	}
	else if `text'>10 & `text'<=30{ 
		local text=70
	}
	else{ 
		local text=50
	}
	if `ntr'==0 & `nsq'==0 {
		di as err "No triangular or quadratic loops found" 
		exit
	}
	qui{
		drop `tnew1' `tnew2' `told1' `told2'
		tempvar na tnew1 tnew2 told1 told2
		qui encode `t1',gen(`told1') lab(_ttrt)
		qui encode `t2',gen(`told2') lab(_ttrt)
		qui gen `tnew1'=min(`told1',`told2')
		qui gen `tnew2'=max(`told1',`told2')	
		by `id',sort: gen `na'=(1+sqrt(1+8*_N))/2
	}
	if `ntr'>0{
		forvalues i=1/`ntr'{
			tempvar trl`i'
			qui gen `trl`i''=1 if ((`tnew1'==_TR[`i',1] & `tnew2'==_TR[`i',2]) | (`tnew1'==_TR[`i',1] & `tnew2'==_TR[`i',3]) | (`tnew1'==_TR[`i',2] & `tnew2'==_TR[`i',3]))
		}
	}
	if `nsq'>0{
		forvalues i=1/`nsq'{
			tempvar sql`i'
			qui gen `sql`i''=1 if ((`tnew1'==_SQ[`i',1] & `tnew2'==_SQ[`i',2]) | (`tnew1'==_SQ[`i',1] & `tnew2'==_SQ[`i',3]) | (`tnew1'==_SQ[`i',1] & `tnew2'==_SQ[`i',4]) | (`tnew1'==_SQ[`i',2] & `tnew2'==_SQ[`i',3]) | (`tnew1'==_SQ[`i',2] & `tnew2'==_SQ[`i',4]) | (`tnew1'==_SQ[`i',3] & `tnew2'==_SQ[`i',4]))	 
		}
	}

	/*identify triangular loops informed only by multi-arm trials*/
	qui{
		if `ntr'>0{
			forvalues i=1/`ntr'{
				tempvar type`i' smallest`i' largest`i'
				by `na' `trl`i'',sort: gen `type`i''=`na' if _n==1 & `trl`i''!=.
				egen `smallest`i''=min(`type`i'')
				egen `largest`i''=max(`type`i'')
				local min`i'=`smallest`i''
				local max`i'=`largest`i''
			}
		}
		
		/*exclude one comparison from multi-arm trials for triangular loops*/
		
		if `ntr'>0{
			forvalues i=1/`ntr'{
				tempvar studies`i' ex`i' ncomp`i'
				gen `ex`i''=.
				if `max`i''>2 & `min`i''==2{
					by `c' `trl`i'',sort: egen `studies`i''=sum(`trl`i'') if `trl`i''!=.
					replace `studies`i''=. if `na'==2
					by `trl`i'' `id',sort: gen `ncomp`i''=_N if `trl`i''!=.
					gsort -`studies`i''
					replace `studies`i''=. if `studies`i''!=`studies`i''[1]
					replace `ex`i''=1 if `trl`i''!=. & `studies`i''!=. & `ncomp`i''==3
					gen _ex`i'=`ex`i''
				}
			}
		}
	}
	if "`details'"!= ""{
		tempvar excl
		qui egen `excl'=rowmax(_ex*)
		di _newline
		di as text " *** Excluded comparisons of multi-arm trials:"
		li `id' _contrast _design if `excl'!=.,table div noobs separator(0)	
		qui drop _ex*
	}
	
	/*estimate direct summary effects and variances*/
	
	qui{
		tempname EStr varEStr ESsq varESsq Hettr Hetsq
		if `ntr'>0{
			mat `EStr'=J(`ntr',3,.)
			mat `varEStr'=J(`ntr',3,.)
			mat `Hettr'=J(`ntr',1,.)
		}
		if `nsq'>0{
			mat `ESsq'=J(`nsq',4,.)
			mat `varESsq'=J(`nsq',4,.)
			mat `Hetsq'=J(`nsq',1,.)
		}	
		forvalues i=1/`nc'{
			sort _dc`i'
			local trdc`i'_1=`tnew1' in `=_N'
			local trdc`i'_2=`tnew2' in `=_N'
		}	

		if "`tau2'"=="comparison"{
			if `ntr'>0{
				forvalues j=1/`ntr'{
					tempvar vtrl`j'
					gen `vtrl`j''=.
					forvalues i=1/`nc'{
						cap metan `y' `se' if `trl`j''==1 & `ex`j''==. & _dc`i'==1,`het' nograph notable
						local estr_`j'_`i'=r(ES)
						local seestr_`j'_`i'=r(seES)
						if `trdc`i'_1'==_OO1[`j',1] & `trdc`i'_2'==_OO1[`j',2] {
							mat `EStr'[`j',1]=`estr_`j'_`i''
							mat `varEStr'[`j',1]=`seestr_`j'_`i''^2
						}
						if `trdc`i'_1'==_OO1[`j',3] & `trdc`i'_2'==_OO1[`j',4] {
							mat `EStr'[`j',2]=`estr_`j'_`i''
							mat `varEStr'[`j',2]=`seestr_`j'_`i''^2
						}		
						if `trdc`i'_1'==_OO1[`j',5] & `trdc`i'_2'==_OO1[`j',6] {
							mat `EStr'[`j',3]=`estr_`j'_`i''
							mat `varEStr'[`j',3]=`seestr_`j'_`i''^2
						}						
					}
				}
			}
			if `nsq'>0{
				forvalues j=1/`nsq'{
					tempvar vsql`j'
					gen `vsql`j''=.
					forvalues i=1/`nc'{
						cap metan `y' `se' if `sql`j''==1 & _dc`i'==1,`het' nograph notable
						local essq_`j'_`i'=r(ES)
						local seessq_`j'_`i'=r(seES)
						if `trdc`i'_1'==_OO2[`j',1] & `trdc`i'_2'==_OO2[`j',2] {
							mat `ESsq'[`j',1]=`essq_`j'_`i''
							mat `varESsq'[`j',1]=`seessq_`j'_`i''^2
						}
						if `trdc`i'_1'==_OO2[`j',3] & `trdc`i'_2'==_OO2[`j',4] {
							mat `ESsq'[`j',2]=`essq_`j'_`i''
							mat `varESsq'[`j',2]=`seessq_`j'_`i''^2
						}		
						if `trdc`i'_1'==_OO2[`j',5] & `trdc`i'_2'==_OO2[`j',6] {
							mat `ESsq'[`j',3]=`essq_`j'_`i''
							mat `varESsq'[`j',3]=`seessq_`j'_`i''^2
						}
						if `trdc`i'_1'==_OO2[`j',7] & `trdc`i'_2'==_OO2[`j',8] {
							mat `ESsq'[`j',4]=`essq_`j'_`i''
							mat `varESsq'[`j',4]=`seessq_`j'_`i''^2
						}						
					}
				}
			}		
		}
	}
	if "`tau2'"=="loop" | "`tau2'"==""{
		if `ntr'>0{
			forvalues i=1/`ntr'{
				tempvar vtrl`i' tau
				qui gen `vtrl`i''=.
				qui gen `tau'=.
				tempname B V
				local ttau`i'=.
				local cov`i'_0 ""
				forvalues j=1/`nc'{
					tempvar sdc`i'_`j'
					qui egen `sdc`i'_`j''=sum(_dc`j') if `trl`i''==1
					qui sort `sdc`i'_`j''
					local ind`i'_`j'=`sdc`i'_`j'' in 1
					if `ind`i'_`j''>0{
						local newcov`i'_`j' "_dc`j'"
					}
					else{
						local newcov`i'_`j' ""
					}
					local cov`i'_`j' "`cov`i'_`=`j'-1'' `newcov`i'_`j''"
					qui drop `sdc`i'_`j''
				}
				cap metareg `y' `cov`i'_`nc'' if `trl`i''==1 & `ex`i''==., wsse(`se') noconstant `meth'
				if _rc==0{
					local ttau`i'=e(tau2)
				}
				if `ttau`i''==.{
					di as text "  {bf:Note:} Heterogeneity of loop `lab`=_TR[`i',1]''-`lab`=_TR[`i',2]''-`lab`=_TR[`i',3]'' cannot be estimated - set equal to 0"
					local ttau`i'=0
					forvalues j=1/`nc'{
						cap metan `y' `se' if `trl`i''==1 & `ex`i''==. & _dc`j'==1,fixedi nograph notable
						local estr_`i'_`j'=r(ES)
						local seestr_`i'_`j'=r(seES)
						if `trdc`j'_1'==_OO1[`i',1] & `trdc`j'_2'==_OO1[`i',2] {
							mat `EStr'[`i',1]=`estr_`i'_`j''
							mat `varEStr'[`i',1]=`seestr_`i'_`j''^2
						}
						if `trdc`j'_1'==_OO1[`i',3] & `trdc`j'_2'==_OO1[`i',4] {
							mat `EStr'[`i',2]=`estr_`i'_`j''
							mat `varEStr'[`i',2]=`seestr_`i'_`j''^2
						}		
						if `trdc`j'_1'==_OO1[`i',5] & `trdc`j'_2'==_OO1[`i',6] {
							mat `EStr'[`i',3]=`estr_`i'_`j''
							mat `varEStr'[`i',3]=`seestr_`i'_`j''^2
						}				
					}
					mat `Hettr'[`i',1]=0
				}
				else{
					mat `B'=e(b)
					mat `V'=e(V)
					local estr1_`i'=`B'[1,1]
					local estr2_`i'=`B'[1,2]
					local estr3_`i'=`B'[1,3]
					local vartr1_`i'=`V'[1,1]
					local vartr2_`i'=`V'[2,2]
					local vartr3_`i'=`V'[3,3]
					mat `Hettr'[`i',1]=e(tau2)
					tokenize "`cov`i'_`nc''"
					forvalues l=1/3{
						forvalues k=1/`nc'{						
							if "``l''"=="_dc`k'" & `trdc`k'_1'==_OO1[`i',1] & `trdc`k'_2'==_OO1[`i',2]{
								mat `EStr'[`i',1]=`estr`l'_`i''
								mat `varEStr'[`i',1]=`vartr`l'_`i''
							}
							if "``l''"=="_dc`k'" & `trdc`k'_1'==_OO1[`i',3] & `trdc`k'_2'==_OO1[`i',4]{
								mat `EStr'[`i',2]=`estr`l'_`i''
								mat `varEStr'[`i',2]=`vartr`l'_`i''
							}	
							if "``l''"=="_dc`k'" & `trdc`k'_1'==_OO1[`i',5] & `trdc`k'_2'==_OO1[`i',6]{
								mat `EStr'[`i',3]=`estr`l'_`i''
								mat `varEStr'[`i',3]=`vartr`l'_`i''
							}									
						}
					}
				}
			}
		}
		if `nsq'>0{
			forvalues i=1/`nsq'{
				tempvar vsql`i' tau
				qui gen `vsql`i''=.
				qui gen `tau'=.
				tempname B V
				local stau`i'=.
				forvalues j=1/`nc'{
					tempvar sdc`i'_`j'
					qui egen `sdc`i'_`j''=sum(_dc`j') if `sql`i''==1
					sort `sdc`i'_`j''
					local ind`i'_`j'=`sdc`i'_`j'' in 1
					if `ind`i'_`j''>0{
						local newcov`i'_`j' "_dc`j'"
					}
					else{
						local newcov`i'_`j' ""
					}
					local cov`i'_`j' "`cov`i'_`=`j'-1'' `newcov`i'_`j''"
					qui drop `sdc`i'_`j''
				}
				cap metareg `y' `cov`i'_`nc'' if `sql`i''==1, wsse(`se') noconstant `meth'
				if _rc==0{
					local stau`i'=e(tau2)
				}
				if `stau`i''==.{
					di as text "  {bf:Note:} Heterogeneity of loop `lab`=_SQ[`i',1]''-`lab`=_SQ[`i',2]''-`lab`=_SQ[`i',3]''-`lab`=_SQ[`i',4]'' cannot be estimated - set equal to 0"
					local stau`i'=0
					forvalues j=1/`nc'{
						cap metan `y' `se' if `sql`i''==1 & _dc`j'==1,fixedi nograph notable
						local essq_`i'_`j'=r(ES)
						local seessq_`i'_`j'=r(seES)
						if `trdc`j'_1'==_OO2[`i',1] & `trdc`j'_2'==_OO2[`i',2] {
							mat `ESsq'[`i',1]=`essq_`i'_`j''
							mat `varESsq'[`i',1]=`seessq_`i'_`j''^2
						}
						if `trdc`j'_1'==_OO2[`i',3] & `trdc`j'_2'==_OO2[`i',4] {
							mat `ESsq'[`i',2]=`essq_`i'_`j''
							mat `varESsq'[`i',2]=`seessq_`i'_`j''^2
						}		
						if `trdc`j'_1'==_OO2[`i',5] & `trdc`j'_2'==_OO2[`i',6] {
							mat `ESsq'[`i',3]=`essq_`i'_`j''
							mat `varESsq'[`i',3]=`seessq_`i'_`j''^2
						}
						if `trdc`j'_1'==_OO2[`i',7] & `trdc`j'_2'==_OO2[`i',8] {
							mat `ESsq'[`i',4]=`essq_`i'_`j''
							mat `varESsq'[`i',4]=`seessq_`i'_`j''^2
						}	
						mat `Hetsq'[`i',1]=0
					}						
				}
				else{
					mat `B'=e(b)
					mat `V'=e(V)
					local essq1_`i'=`B'[1,1]
					local essq2_`i'=`B'[1,2]
					local essq3_`i'=`B'[1,3]
					local essq4_`i'=`B'[1,4]
					local varsq1_`i'=`V'[1,1]
					local varsq2_`i'=`V'[2,2]
					local varsq3_`i'=`V'[3,3]
					local varsq4_`i'=`V'[4,4]	
					mat `Hetsq'[`i',1]=e(tau2)
					tokenize "`cov`i'_`nc''"
					forvalues k=1/`nc'{
						forvalues l=1/4{
							if "``l''"=="_dc`k'" & `trdc`k'_1'==_OO2[`i',1] & `trdc`k'_2'==_OO2[`i',2]{
								mat `ESsq'[`i',1]=`essq`l'_`i''
								mat `varESsq'[`i',1]=`varsq`l'_`i''
							}
							if "``l''"=="_dc`k'" & `trdc`k'_1'==_OO2[`i',3] & `trdc`k'_2'==_OO2[`i',4]{
								mat `ESsq'[`i',2]=`essq`l'_`i''
								mat `varESsq'[`i',2]=`varsq`l'_`i''
							}	
							if "``l''"=="_dc`k'" & `trdc`k'_1'==_OO2[`i',5] & `trdc`k'_2'==_OO2[`i',6]{
								mat `ESsq'[`i',3]=`essq`l'_`i''
								mat `varESsq'[`i',3]=`varsq`l'_`i''
							}	
							if "``l''"=="_dc`k'" & `trdc`k'_1'==_OO2[`i',7] & `trdc`k'_2'==_OO2[`i',8]{
								mat `ESsq'[`i',4]=`essq`l'_`i''
								mat `varESsq'[`i',4]=`varsq`l'_`i''
							}								
						}
					}						
				}
			}
		}		
	}
	
	qui{
		if "`tau2'"!="comparison" & "`tau2'"!="" & "`tau2'"!="loop"{
			tempvar wgt senew
			qui gen `wgt'=1/((`se'^2)+`=`nettau2'')
			qui gen `senew'=sqrt((`se'^2)+`nettau2')
			if `ntr'>0{
				forvalues j=1/`ntr'{
					tempvar vtrl`j'
					gen `vtrl`j''=.
					forvalues i=1/`nc'{
						cap gen trl`j'=`trl`j''
						cap metan `y' `senew' if `trl`j''==1 & `ex`j''==. & _dc`i'==1,wgt(`wgt') nograph notable
						local estr_`j'_`i'=r(ES)
						local seestr_`j'_`i'=r(seES)
						if `trdc`i'_1'==_OO1[`j',1] & `trdc`i'_2'==_OO1[`j',2] {
							mat `EStr'[`j',1]=`estr_`j'_`i''
							mat `varEStr'[`j',1]=`seestr_`j'_`i''^2
						}
						if `trdc`i'_1'==_OO1[`j',3] & `trdc`i'_2'==_OO1[`j',4] {
							mat `EStr'[`j',2]=`estr_`j'_`i''
							mat `varEStr'[`j',2]=`seestr_`j'_`i''^2
						}		
						if `trdc`i'_1'==_OO1[`j',5] & `trdc`i'_2'==_OO1[`j',6] {
							mat `EStr'[`j',3]=`estr_`j'_`i''
							mat `varEStr'[`j',3]=`seestr_`j'_`i''^2
						}						
					}
				}
			}
			if `nsq'>0{
				forvalues j=1/`nsq'{
					tempvar vsql`j'
					gen `vsql`j''=.
					forvalues i=1/`nc'{
						cap gen sql`j'=`sql`j''
						cap metan `y' `senew' if `sql`j''==1 & _dc`i'==1,wgt(`wgt') nograph notable
						local essq_`j'_`i'=r(ES)
						local seessq_`j'_`i'=r(seES)
						if `trdc`i'_1'==_OO2[`j',1] & `trdc`i'_2'==_OO2[`j',2] {
							mat `ESsq'[`j',1]=`essq_`j'_`i''
							mat `varESsq'[`j',1]=`seessq_`j'_`i''^2
						}
						if `trdc`i'_1'==_OO2[`j',3] & `trdc`i'_2'==_OO2[`j',4] {
							mat `ESsq'[`j',2]=`essq_`j'_`i''
							mat `varESsq'[`j',2]=`seessq_`j'_`i''^2
						}		
						if `trdc`i'_1'==_OO2[`j',5] & `trdc`i'_2'==_OO2[`j',6] {
							mat `ESsq'[`j',3]=`essq_`j'_`i''
							mat `varESsq'[`j',3]=`seessq_`j'_`i''^2
						}
						if `trdc`i'_1'==_OO2[`j',7] & `trdc`i'_2'==_OO2[`j',8] {
							mat `ESsq'[`j',4]=`essq_`j'_`i''
							mat `varESsq'[`j',4]=`seessq_`j'_`i''^2
						}						
					}
				}
			}
		}
	}
	
	/*estimate indirect pooled effects and variances*/

	if `ntr'>0{
		mat _DIRtr=J(`ntr',1,.)
		mat _varDIRtr=J(`ntr',1,.)
		mat _INDIRtr=J(`ntr',1,.)
		mat _varINDIRtr=J(`ntr',1,.)
		mat _Hettr=J(`ntr',1,.)
		forvalues i=1/`ntr'{
			mat _DIRtr[`i',1]=`EStr'[`i',1]
			mat _varDIRtr[`i',1]=`varEStr'[`i',1]
			mat _INDIRtr[`i',1]=_INDT[`i',2]*`EStr'[`i',2]+_INDT[`i',3]*`EStr'[`i',3]
			mat _varINDIRtr[`i',1]=`varEStr'[`i',2]+`varEStr'[`i',3]
		}
		cap mat _Hettr=`Hettr'
	}

	if `nsq'>0{
		mat _DIRsq=J(`nsq',1,.)
		mat _varDIRsq=J(`nsq',1,.)
		mat _INDIRsq=J(`nsq',1,.)
		mat _varINDIRsq=J(`nsq',1,.)
		mat _Hetsq=J(`nsq',1,.)
		forvalues i=1/`nsq'{
			mat _DIRsq[`i',1]=`ESsq'[`i',1]
			mat _varDIRsq[`i',1]=`varESsq'[`i',1]
			mat _INDIRsq[`i',1]=_INDS[`i',2]*`ESsq'[`i',2]+_INDS[`i',3]*`ESsq'[`i',3]+_INDS[`i',4]*`ESsq'[`i',4]
			mat _varINDIRsq[`i',1]=`varESsq'[`i',2]+`varESsq'[`i',3]+`varESsq'[`i',4]
		}
		cap mat _Hetsq=`Hetsq'
	}	

	if `ntr'>0 & `nsq'>0{
		mat _DIR=_DIRtr\_DIRsq
		mat _varDIR=_varDIRtr\_varDIRsq
		mat _INDIR=_INDIRtr\_INDIRsq
		mat _varINDIR=_varINDIRtr\_varINDIRsq
		cap mat _Het=_Hettr\_Hetsq
		mat _Loop1=J(`ntr',1,.)
		mat _Loop2=(_TR,_Loop1)
		mat _Loop=_Loop2\_SQ
	}
	if `ntr'>0 & `nsq'==0{
		mat _DIR=_DIRtr
		mat _varDIR=_varDIRtr
		mat _INDIR=_INDIRtr
		mat _varINDIR=_varINDIRtr
		cap mat _Het=_Hettr
		mat _Loop=_TR
	}	
	if `ntr'==0 & `nsq'>0{
		mat _DIR=_DIRsq
		mat _varDIR=_varDIRsq
		mat _INDIR=_INDIRsq
		mat _varINDIR=_varINDIRsq
		cap mat _Het=_Hetsq
		mat _Loop=_SQ
	}	
	mat _IF=J(`=`ntr'+`nsq'',1,.)
	mat _seIF=J(`=`ntr'+`nsq'',1,.)
	forvalues i=1/`=`ntr'+`nsq''{
		mat _IF[`i',1]=abs(_DIR[`i',1]-_INDIR[`i',1])
		mat _seIF[`i',1]=sqrt(_varDIR[`i',1]+_varINDIR[`i',1])
	}
	
	/*get the inconsistency results*/

	qui{
		tempvar _aa _bb _cc _uu _ddd _consistent
		svmat _IF
		rename _IF1 IF
		svmat _seIF
		rename _seIF1 seIF
		cap svmat _Het	
		cap rename _Het1 Heterogeneity
		svmat _Loop
		lab val _Loop* _trt
		decode _Loop1, gen(_tr1)
		decode _Loop2, gen(_tr2)
		decode _Loop3, gen(_tr3)
		cap decode _Loop4, gen(_tr4)
		egen Loop=concat(_tr*) if IF!=.,punct(" ")
		local onlym=0
		forvalues i=1/`ntr'{
			if `min`i''>2{
				local loopn`i'=Loop in `i'
				replace Loop in `i'="*`loopn`i''"
				local onlym=1
			}
		}		
		gen z_value=IF/seIF
		gen p_value=2*(1-normal(abs(z_value)))
		gen LCI=IF-(invnorm(`ci')*seIF)
		gen ROR=exp(IF)
		replace LCI=0 if LCI<0
		gen UCI=IF+(invnorm(`ci')*seIF)
		cap format ROR IF seIF z_value p_value Heterogeneity LCI UCI %9.3f			
		
		gen `_aa'="(" if Loop!=""
		gen `_bb'=")" if Loop!=""
		gen `_cc'=string(round(LCI,0.01),"%9.2f")
		gen `_uu'=string(round(UCI,0.01),"%9.2f")
		
		if "`eform'"!=""{
			replace `_cc'=string(round(exp(LCI),0.01),"%9.2f")
			replace `_uu'=string(round(exp(UCI),0.01),"%9.2f")
		}
		egen `_ddd'=concat(`_cc' `_uu') if Loop!="",punct(,)
		egen CI_`cilevel'=concat(`_aa' `_ddd' `_bb')
		cap gsort -IF -LCI
		gen `_consistent'="With Evidence of Statistical Inconsistency" if LCI>0
		replace `_consistent'="Without Evidence of Statistical Inconsistency" if LCI==0		
	}
		
	if "`eform'"!=""{
		local eform eform
		local name ROR
		local seIF ""
	}
	else{
		local eform ""
		local name IF
		local seIF seIF
	}	
	
	/*list the inconsistency results*/

	if "`tau2'"=="" | "`tau2'"=="loop"{
		rename Heterogeneity Loop_Heterog_tau2
		di as text _newline " Evaluation of inconsistency using loop-specific heterogeneity estimates:"
		if "`separate'"!=""{
			di _newline " Loops With Evidence of Statistical Inconsistency:"
			li Loop `name' `seIF' z_value p_value CI_`cilevel' Loop_Heterog_tau2 if Loop!="" & `_consistent'=="With Evidence of Statistical Inconsistency",table div noobs separator(0) abbreviate(20) 
			di _newline " Loops Without Evidence of Statistical Inconsistency:"
			li Loop `name' `seIF' z_value p_value CI_`cilevel' Loop_Heterog_tau2 if Loop!="" & `_consistent'=="Without Evidence of Statistical Inconsistency",table div noobs separator(0) abbreviate(20) 	
		}
		else{
			li Loop `name' `seIF' z_value p_value CI_`cilevel' Loop_Heterog_tau2 if Loop!="" ,table div noobs separator(0) abbreviate(20) 
		}
		qui rename Loop_Heterog_tau2 Heterogeneity
	}
	else if "`tau2'"=="comparison"{
		if "`separate'"!=""{
			di as text " Evaluation of inconsistency using comparison-specific heterogeneity estimates:"
			di _newline " Loops With Evidence of Statistical Inconsistency:"
			li Loop `name' `seIF' z_value p_value CI_`cilevel' if Loop!="" & `_consistent'=="With Evidence of Statistical Inconsistency",table div noobs separator(0)
			di _newline " Loops Without Evidence of Statistical Inconsistency:"
			li Loop `name' `seIF' z_value p_value CI_`cilevel' if Loop!="" & `_consistent'=="Without Evidence of Statistical Inconsistency",table div noobs separator(0)
		}
		else{
			li Loop `name' `seIF' z_value p_value CI_`cilevel' if Loop!="" ,table div noobs separator(0)
		}
	}	
	else{
		if "`separate'"!=""{
			di as text " Evaluation of inconsistency using network-specific heterogeneity estimate (tau2=`tau2'):"
			di _newline " Loops With Evidence of Statistical Inconsistency:"
			li Loop `name' `seIF' z_value p_value CI_`cilevel' if Loop!="" & `_consistent'=="With Evidence of Statistical Inconsistency",table div noobs separator(0)
			di _newline " Loops Without Evidence of Statistical Inconsistency:"
			li Loop `name' `seIF' z_value p_value CI_`cilevel' if Loop!="" & `_consistent'=="Without Evidence of Statistical Inconsistency",table div noobs separator(0)		
		}
		else{
			li Loop `name' `seIF' z_value p_value CI_`cilevel' if Loop!="" ,table div noobs separator(0)	
		}
	}	
	if `onlym'==1{
		di as text _newline " {bf:Note}: * These loops are formed only by multi-arm trial(s)"
	}

	
	/*store direct and indirect pooled estimates*/
	
	if "`summary'"!= "" {
		di _newline "Treatment codes"
		lab li _ttrt
		di _newline "Direct comparisons"
		if `ntr'>0{
			mat li _OO1,nonames noheader
		}
		if `nsq'>0{
			mat li _OO2,nonames noheader
		}		
		di _newline "Direct effect sizes"
		if `ntr'>0{
			mat li `EStr',nonames noheader format(%9.3f)
		}
		if `nsq'>0{
			mat li `ESsq',nonames noheader format(%9.3f)
		}		
		di _newline "Variance of direct effect sizes"
		if `ntr'>0{
			mat li `varEStr',nonames noheader format(%9.3f)
		}
		if `nsq'>0{
			mat li `varESsq',nonames noheader format(%9.3f)
		}		
		di _newline "Indirect effect size for first comparison"
		if `ntr'>0{
			mat li _INDIRtr,nonames noheader format(%9.3f)
		}
		if `nsq'>0{ 
			mat li _INDIRsq,nonames noheader format(%9.3f)
		}		
		di _newline "Variance of indirect effect size for first comparison"
		if `ntr'>0{
			mat li _varINDIRtr,nonames noheader format(%9.3f)
		}
		if `nsq'>0{
			mat li _varINDIRsq,nonames noheader format(%9.3f)
		}		
	}
	
	/*plot the inconsistency results*/
	
	tempvar _space1 _space2 _space3 _space4 _space5 
	if "`noplot'"==""{
		format IF %9.2f
		label var CI_`cilevel' "`cilevel'%CI (truncated)"
		label var IF "IF"
		tempvar _maxlab
		egen `_maxlab'=max(UCI)
		local maxl=ceil(`_maxlab')
		local maxl2=ceil(`=`maxl'/2')
		local maxl3=ceil(`=`maxl'/4')
		local maxl4=ceil(`=3*`maxl'/4')
		local nn=0
		if "`eform'"!=""{
			local maxl=ceil(exp(`maxl'))
			local maxl2=ceil(exp(`maxl2'))
			local maxl3=ceil(exp(`maxl3'))
			local maxl4=ceil(exp(`maxl4'))
			local nn=1
		}		
		if `"`xlabel'"'!=""{
			local xlab `xlabel'
		}
		else{
			local xlab "`nn',`maxl3',`maxl4',`maxl2',`maxl'"
		}	
		tempname _cons3
		gen `_space1'=" "
		gen `_space2'=" "
		gen `_space3'=" "
		gen `_space4'=" "
		gen `_space5'=" "
		label var `_space1' " "
		label var `_space2' " "
		label var `_space3' " "
		label var `_space4' " "
		label var `_space5' " "
		local 3cons ""

		if `onlym'==1{
			local cons3="{bf:Note}: * These loops are formed only by multi-arm trial(s)"
		}		
		if "`tau2'"=="" | "`tau2'"=="loop"{
			label var Heterogeneity " Loop-specific Heterogeneity({&tau}{sup:2})"
			cap{
				if "`separate'"!=""{
					metan IF LCI UCI,nooverall notable lcols(Loop `_space1' `_space2' `_space3' `_space4' `_space5') rcols(`_space1' `_space2' `name' CI Heterogeneity) nostats `plotoptions' xlab(`xlab') force by(`_consistent') nograph nokeep `eform' astext(`text') note(`cons3')
					metan IF LCI UCI,nooverall notable lcols(Loop `_space1' `_space2' `_space3' `_space4' `_space5') rcols(`_space1' `_space2' `name' CI Heterogeneity) nostats `plotoptions' xlab(`xlab') force by(`_consistent') nosubgroup nokeep `eform' astext(`text') note(`cons3')
				}
				else{
					metan IF LCI UCI,nooverall notable lcols(Loop `_space1' `_space2' `_space3' `_space4' `_space5') rcols(`_space1' `_space2' `name' CI Heterogeneity) nostats `plotoptions' xlab(`xlab') force nokeep `eform' astext(`text') note(`cons3')
				}
			}
			if _rc!=0{
				if "`plotoptions'"==""{
					di as err "Probably insufficient memory - Please, maximize memory number of variables and try again (see {helpb memory} and {helpb maxvar})"
					exit
				}
				else{
					di as err "Option {it:`plotoptions'} in option {it:plotoptions} not allowed"
					exit
				}
			}
		}
		else{
			cap{
				if "`separate'"!=""{
					metan IF LCI UCI ,nooverall notable lcols(Loop `_space1' `_space2' `_space3' `_space4' `_space5') rcols(`_space1' `_space2' `name' CI) nostats `plotoptions' xlab(`xlab') force by(`_consistent') nograph nokeep `eform' astext(`text') note(`cons3')
					metan IF LCI UCI ,nooverall notable lcols(Loop `_space1' `_space2' `_space3' `_space4' `_space5') rcols(`_space1' `_space2' `name' CI) nostats `plotoptions' xlab(`xlab') force by(`_consistent') nosubgroup nokeep `eform' astext(`text') note(`cons3')
				}
				else{
					metan IF LCI UCI ,nooverall notable lcols(Loop `_space1' `_space2' `_space3' `_space4' `_space5') rcols(`_space1' `_space2' `name' CI) nostats `plotoptions' xlab(`xlab') force nokeep `eform' astext(`text') note(`cons3')
				}
			}
			if _rc!=0{
				if "`plotoptions'"==""{
					di as err "Probably insufficient memory - Please, maximize memory number of variables and try again (ses {helpb memory} and {helpb maxvar})"
					exit
				}
				else{
					di as err "Option {it:`plotoptions'} in option {it:plotoptions} not allowed"
					exit
				}
			}
		}
	}

	if "`keep'"!=""{
		qui{
			restore
			cap drop _Loop _IF _seIF _z_value _p_value _LCI_IF _UCI_IF
			cap drop _Loop_Heterogeneity			
			if `"`labels'"' == ""{
				lab def _trt 1 "`tr1'"
				forvalues i=2/`ntm'{
					lab def _trt `i' "`tr`i''",add
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
			}			
			svmat _Loop
			cap lab val _Loop* _trt
			decode _Loop1, gen(_tr1)
			decode _Loop2, gen(_tr2)
			decode _Loop3, gen(_tr3)
			cap decode _Loop4, gen(_tr4)
			egen _Loop=concat(_tr*) if _Loop1!=.,punct(" ")
			forvalues i=1/`ntr'{
				if `min`i''>2{
					local loopn`i'=_Loop in `i'
					replace _Loop in `i'="*`loopn`i''"
				}
			}		
			drop _Loop1 _Loop2 _Loop3
			cap drop _Loop4
			svmat _IF
			rename _IF1 _IF
			svmat _seIF
			rename _seIF1 _seIF		
			gen _LCI_IF=_IF-(invnorm(`ci')*_seIF)
			replace _LCI_IF=0 if _LCI_IF<0
			gen _UCI_IF=_IF+(invnorm(`ci')*_seIF)
			gen _z_value=_IF/_seIF
			gen _p_value=2*(1-normal(abs(_z_value)))			
			cap svmat _Het	
			cap rename _Het1 _Loop_Heterogeneity	
			cap drop _tr1 _tr2 _tr3
			cap drop _tr4
		}
	}
	cap lab drop _trt
	cap mat drop _DIR _INDIR _varDIR _varINDIR _Loop _IF _seIF
	cap mat drop _OO1 _TR _INDT _DIRtr _INDIRtr _varDIRtr _varINDIRtr
	cap mat drop _OO2 _SQ _INDS	_DIRsq _INDIRsq _varDIRsq _varINDIRsq
	cap mat drop _Het
	cap mat drop _Hettr
	cap mat drop _Hetsq
	
end


mata
void loops()
{
	
	d1=st_matrix("_treat1")
	d2=st_matrix("_treat2")
	nc=rows(d1)
	ntr=0
	nsq=0
	
	OO=(.,.,.,.)
	OOi=(.,.)
	for (c=1; c<=nc; c++){
		for (k=1; k<=nc; k++){
			if (k!=c & d1[k,1]==d1[c,1]){
				O=(d2[c,1],d1[c,1],d1[k,1],d2[k,1])
				Oi=(-1,1)
				OO=OO\O
				OOi=OOi\Oi
			}
			if (k!=c & d1[k,1]==d2[c,1]){
				O=(d1[c,1],d2[c,1],d1[k,1],d2[k,1])
				Oi=(1,1)
				OO=OO\O
				OOi=OOi\Oi
			}				
			if (k!=c & d2[k,1]==d1[c,1]){
				O=(d2[c,1],d1[c,1],d2[k,1],d1[k,1])
				Oi=(-1,-1)
				OO=OO\O
				OOi=OOi\Oi
			}			
			if (k!=c & d2[k,1]==d2[c,1]){
				O=(d1[c,1],d2[c,1],d2[k,1],d1[k,1])
				Oi=(1,-1)
				OO=OO\O
				OOi=OOi\Oi
			}				
		}
	}	
	OO=select(OO, rowmissing(OO):==0)	
	OOi=select(OOi, rowmissing(OOi):==0)
	OOi=(OOi,OO[,1],OO[,4])
	OO=select(OO, OO[,1]:!=OO[,4])
	OOi=select(OOi, OOi[,3]:!=OOi[,4])
	OOi=OOi[,1..2]
	COO=(.,.,.,.,.,.)
	COOi=(.,.,.)	
	TR=(.,.,.)
	for (k=1; k<=rows(OO); k++){
		for (c=1; c<=nc; c++){
			if (d1[c,1]!=. & d1[c,1]==OO[k,4] & d2[c,1]!=OO[k,3] & d2[c,1]!=OO[k,3]){
				CO=(OO[k,],d1[c,1],d2[c,1])
				COO=COO\CO
				COi=(OOi[k,],1)
				COOi=COOi\COi
				T=(OO[k,1],OO[k,2],OO[k,4])
				TR=TR\T
			}	
			if (d2[c,1]!=. & d2[c,1]==OO[k,4] & d1[c,1]!=OO[k,3] & d1[c,1]!=OO[k,3]){
				CO=(OO[k,],d2[c,1],d1[c,1])
				COO=COO\CO
				COi=(OOi[k,],-1)
				COOi=COOi\COi		
				T=(OO[k,1],OO[k,2],OO[k,4])
				TR=TR\T
			}							
		}
	}
	COO=select(COO, rowmissing(COO):==0)	
	COOi=select(COOi, rowmissing(COOi):==0)		
	TR=select(TR, rowmissing(TR):==0)	
	OOi=(COOi,COO[,1],COO[,6])
	TR=(TR,COO[,1],COO[,6])
	OO1=select(COO, COO[,1]:==COO[,6])
	OOi1=select(OOi, OOi[,4]:==OOi[,5])
	TR1=select(TR, TR[,4]:==TR[,5])
	TR2=select(TR, TR[,4]:!=TR[,5])
	OOi2=select(OOi, OOi[,4]:!=OOi[,5])
	INDT=OOi1[,1..3]
	TR=TR1[,1..3]
	OO=select(COO, COO[,1]:!=COO[,6])
	OOi=OOi2[,1..3]
	TR2=TR2[,1..3]
	COO=(.,.,.,.,.,.,.,.)
	COOi=(.,.,.,.)	
	SQ=(.,.,.,.)
	for (k=1; k<=rows(OO); k++){
		for (c=1; c<=nc; c++){
			if (d1[c,1]!=. & d1[c,1]==OO[k,6] & d2[c,1]!=OO[k,5] & d2[c,1]!=OO[k,5]){
				CO=(OO[k,],d1[c,1],d2[c,1])
				COO=COO\CO
				COi=(OOi[k,],1)
				COOi=COOi\COi
				S=(TR2[k,],OO[k,6])
				SQ=SQ\S
			}	
			if (d2[c,1]!=. & d2[c,1]==OO[k,6] & d1[c,1]!=OO[k,5] & d1[c,1]!=OO[k,5]){
				CO=(OO[k,],d2[c,1],d1[c,1])
				COO=COO\CO
				COi=(OOi[k,],-1)
				COOi=COOi\COi
				S=(TR2[k,],OO[k,6])
				SQ=SQ\S
			}							
		}
	}	
	COO=select(COO, rowmissing(COO):==0)	
	COOi=select(COOi, rowmissing(COOi):==0)		
	SQ=select(SQ, rowmissing(SQ):==0)
	OOi=(COOi,COO[,1],COO[,8])
	SQ=(SQ,COO[,1],COO[,8])
	OO2=select(COO, COO[,1]:==COO[,8])
	OOi1=select(OOi, OOi[,5]:==OOi[,6])
	SQ1=select(SQ, SQ[,5]:==SQ[,6])
	INDS=OOi1[,1..4]
	SQ=SQ1[,1..4]
	
	OO1new=(.,.,.,.,.,.)
	for (k=1; k<=rows(OO1); k++){
		min1=OO1[k,1]
		max1=OO1[k,2]
		min2=OO1[k,3]
		max2=OO1[k,4]
		min3=OO1[k,5]
		max3=OO1[k,6]
		if (OO1[k,1]>OO1[k,2]){
			min1=OO1[k,2]
			max1=OO1[k,1]
		}
		if (OO1[k,3]>OO1[k,4]){
			min2=OO1[k,4]
			max2=OO1[k,3]
		}
		if (OO1[k,5]>OO1[k,6]){
			min3=OO1[k,6]
			max3=OO1[k,5]
		}
		OO1i=(min1,max1,min2,max2,min3,max3)
		OO1new=OO1new\OO1i
	}
	OO2new=(.,.,.,.,.,.,.,.)
	for (k=1; k<=rows(OO2); k++){
		min1=OO2[k,1]
		max1=OO2[k,2]
		min2=OO2[k,3]
		max2=OO2[k,4]
		min3=OO2[k,5]
		max3=OO2[k,6]
		min4=OO2[k,7]
		max4=OO2[k,8]
		if (OO2[k,1]>OO2[k,2]){
			min1=OO2[k,2]
			max1=OO2[k,1]
		}
		if (OO2[k,3]>OO2[k,4]){
			min2=OO2[k,4]
			max2=OO2[k,3]
		}
		if (OO2[k,5]>OO2[k,6]){
			min3=OO2[k,6]
			max3=OO2[k,5]
		}
		if (OO2[k,7]>OO2[k,8]){
			min4=OO2[k,8]
			max4=OO2[k,7]
		}
		OO2i=(min1,max1,min2,max2,min3,max3,min4,max4)
		OO2new=OO2new\OO2i
	}
	OO1=select(OO1new, rowmissing(OO1new):==0)
	OO2=select(OO2new, rowmissing(OO2new):==0)	

	T=rowmin(TR)
	TRnew=T
	for (i=1; i<=2; i++){
		for (r=1; r<=rows(TR); r++){
			for (c=1; c<=cols(TR); c++){
				if (TR[r,c]==T[r,1]){
					TR[r,c]=.
				}
			}
		}
		T=rowmin(TR)
		TRnew=(TRnew,T)
	}
	for (r=1; r<=rows(TRnew)-1; r++){
		for (c=r+1; c<=rows(TRnew); c++){
			if (TRnew[c,]==TRnew[r,]){
				TRnew[c,1]=.
				OO1[c,1]=.
				INDT[c,1]=.
			}
		}
	}
	TRnew=select(TRnew, rowmissing(TRnew):==0)
	OO1=select(OO1, rowmissing(OO1):==0)
	INDT=select(INDT, rowmissing(INDT):==0)
	ntr=rows(OO1)
	
	INDQ=J(rows(OO2),1,.)

	for (i=1; i<=rows(OO2); i++){
		INDQ[i,1]=i
	}
	S=rowmin(SQ)
	SQnew=S
	for (i=1; i<=3; i++){
		for (r=1; r<=rows(SQ); r++){
			for (c=1; c<=cols(SQ); c++){
				if (SQ[r,c]==S[r,1]){
					SQ[r,c]=.
				}
			}
		}
		S=rowmin(SQ)
		SQnew=(SQnew,S)
	}
	INDQ=(SQnew,INDQ)
	SQnew=sort(SQnew,(1,2,3,4))
	INDQ=sort(INDQ,(1,2,3,4))
	for (r=1; r<=rows(SQnew)-1; r++){
		for (c=r+1; c<=rows(SQnew); c++){
			if (SQnew[c,]==SQnew[r,]){
				SQnew[c,1]=.
				INDQ[c,1]=.
			}
		}
	}
	SQnew=select(SQnew, rowmissing(SQnew):==0)
	INDQ=select(INDQ, rowmissing(INDQ):==0)
	for (r=1; r<=rows(SQnew); r++){
		for (c=1; c<=rows(TRnew); c++){
			if (SQnew[r,1..3]==TRnew[c,] | (SQnew[r,1],SQnew[r,3..4])==TRnew[c,] | (SQnew[r,1..2],SQnew[r,4])==TRnew[c,] | SQnew[r,2..4]==TRnew[c,]){
				SQnew[r,1]=.
				INDQ[r,1]=.
			}
		}
	}
	SQnew=select(SQnew, rowmissing(SQnew):==0)
	INDQ=select(INDQ, rowmissing(INDQ):==0)
	INDQ=INDQ[,5]
	nsq=rows(SQnew)
	if (nsq>0){
		OO2n=J(rows(INDQ),cols(OO2),.)
		INDSn=J(rows(INDQ),cols(INDS),.)
		for (r=1; r<=rows(INDQ); r++){
			OO2n[r,]=OO2[INDQ[r,1],]
			INDSn[r,]=INDS[INDQ[r,1],]
		}
	}
	st_numscalar("_ntr",ntr)
	st_numscalar("_nsq",nsq)
	if (ntr>0){
		st_matrix("_TR",TRnew)
		st_matrix("_OO1",OO1)
		st_matrix("_INDT",INDT)
	}
	if (nsq>0){
		for (r=1; r<=rows(INDSn); r++){
			if (INDSn[r,1]==1){
				for (c=1; c<=cols(INDSn); c++){
					INDSn[r,c]=-1*INDSn[r,c]
				}
			}
		}
		st_matrix("_SQ",SQnew)
		st_matrix("_OO2",OO2n)
		st_matrix("_INDS",INDSn)
	}
}
end




	
