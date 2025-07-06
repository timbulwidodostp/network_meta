*! version 2.0.0, 09.01.2018
//version 1.2, 26.02.2015, Anna Chaimani

program mdsrank,eclass
	syntax [varlist] [if] [in] , [NOMVmeta BEST(string) LABels(string asis) NOPLOT SCATteroptions(string)] 		

	preserve
	
	if "`nomvmeta'"==""{
		local form:char _dta[network_format]
		if "`form'"!="augmented"{
			di as err "Data not in augmented format, see {helpb network setup} or {helpb network import} for details"
			exit
		}  
		local ns=e(N)
		if `ns'==.{
			di as err "No results from {cmd:mveta} or {cmd:network meta} command found"
			exit
		}       
		if "`if'"!="" | "`in'"!=""{
			di as text _newline "Note: Options {it:if} and {it:in} may not be combined with option {it:mvmetaresults}"
			exit
		}       
		tempvar se
		di as text _newline " The {cmd:mdsrank} command assumes that the saved results from {cmd:mvmeta} or {cmd:network meta} commands have been derived from the current dataset"		
		cap drop _Comparison _Effect_Size _LCI _UCI _LPrI _UPrI
		cap drop _t1 _t2
		cap intervalplot, keep notab noplot
		local dim:char _dta[network_dim]
		local ntm=`dim'+1
		local ncall=(`ntm'*(`ntm'-1))/2
		qui split _Comparison,par(" vs ") gen(_t)
		local y "_Effect_Size"
		local lci "_LCI"
		local uci "_UCI"
		local t11 "_t1"
		local t22 "_t2"
		qui gen `se'=(`uci'-`lci')/(2*abs(invnorm(0.025)))		
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
 		di as text "{bf:Warning}: After running {it:mdsrank} some results from {it:mvmeta} or {it:network meta} might be lost - to anoid problems in fllowing analyses re-run {it:mvmeta} or {it:network meta}"
	}
	else{
		if "`if'"!= ""{
			qui keep `if'
		}
		if "`in'"!= ""{
			qui keep `in'
		}	
		tokenize "`varlist'"

		local y `1'
		if "`5'"==""{
			local se `2'
			local t11 `3'
			local t22 `4'		
		}
		if "`5'"!=""{
			tempvar se
			local lci `2'
			local uci `3'
			local t11 `4'
			local t22 `5'	
			qui gen `se'=(`uci'-`lci')/(2*abs(invnorm(0.025)))
		}
		tempvar tnew1 tnew2 m1 m2
		cap lab drop _trt
		cap lab drop _ttrt	
		qui levelsof `t11', local(t1levels)
		qui levelsof `t22', local(t2levels)
		local alltreats : list t1levels | t2levels
		local alltreats : list sort alltreats
		local i 0
		foreach trt in `alltreats' {
			local ++i
			label def _ttrt `i' "`trt'", add
			if `"`labels'"' == ""{
				label def _trt `i' "`trt'", add
				local lab`i' "`trt'"
			}
		}
		cap encode `t11',gen(`tnew1') lab(_ttrt)
		cap encode `t22',gen(`tnew2') lab(_ttrt)				
		egen `m1'=max(`tnew1')
		egen `m2'=max(`tnew2')
		local ntm=max(`m1',`m2')
		local dim=`ntm'-1
		local ncall=(`ntm'*(`ntm'-1))/2
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
	
	qui sort `t22' `t11' in 1/`ncall'
	forvalues i=1/`dim'{
		local tr`i'=`t22' in `=1+(`i'-1)*`ntm'-((`i'-1)/2)*`i''
	}
	local tr`ntm'=`t11' in `ncall'
	forvalues i=1/`ntm'{
		local ord`i'=`i'
	}
	forvalues j=1/`ntm'{
		forvalues i=1/`ntm'{
			if `ord`i''==`j'{
				cap drop _`tr`i''
				cap gen _`tr`i''es=.
			}
		}
	}
	forvalues i=1/`ntm'{
		forvalues j=1/`ntm'{
			forvalues k=1/`ncall'{
				if `t11'[`k']=="`tr`i''" & `t22'[`k']=="`tr`j''"{
					local es`i'_`j'=`y'/`se' in `k'
					
				}
			}
			cap replace _`tr`i''es=abs(`es`i'_`j'') in `ord`j''
			cap replace _`tr`j''es=abs(`es`i'_`j'') in `ord`i''		
		}
		cap replace _`tr`i''es=0 if _`tr`i''es==.
	}
	tempname t d
	qui gen Treatment=""
	forvalues i=1/`ntm'{
		qui replace Treatment="`lab`i''" in `i'
	}	
	qui mkmat _`tr1'-_`tr`ntm'' in 1/`ntm',mat(`t') rownames(Treatment)
	qui	mdsmat `t',dim(1) noplot
	ereturn mat T `t'
	mat `d'=e(Y)	
	qui svmat `d',names(Dim)
	if "`best'"=="" | "`best'"=="min"{
		sort Dim
		qui gen Rank=_n
		local _xscale "rev"
	}
	else if "`best'"=="max"{
		gsort -Dim
		qui gen Rank=_n
		local _xscale ""
	}	
	else{
		di as err "Option {it:`best'} in option {it:best} not allowed"
		exit
	}	
	format Dim %9.2f
	li Treatment Dim Rank if Dim!=.,table div noobs separator(0)
	format Dim %8.0g
	if "`noplot'"==""{
		cap{
			sc Rank Dim,xscale(`_xscale') yscale(rev) xtitle(Unique Dimension) mlab(Treatment) mcol(black) mlabcol(black) `scatteroptions'
		}
		if _rc!=0{
			di as err "Option {it:`scatteroptions'} in option {it:scatteroptions} not allowed"
			exit
		}	
	}
end
	
	
	
	
	
