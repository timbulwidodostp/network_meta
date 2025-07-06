*! version 2.0.1, 24.05.2019
//version 2.0.0, 13.12.2017
//version 1.2, 26.02.2015, Anna Chaimani

program netleague
	syntax [varlist] [if] [in], [NOMVmeta LABels(string asis) EXPort(string asis) SORT(string asis) NOKEEP EFORM] 
	
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
			di as err "Options {it:if} and {it:in} may not be combined with option {it:mvmetaresults}"
			exit
		}       
		di as text _newline " The {cmd:netleague} command assumes that the saved results from {cmd:mvmeta} or {cmd:network meta} commands have been derived from the current dataset"		
		cap drop _Comparison _Effect_Size _LCI _UCI _LPrI _UPrI
		cap drop _t1 _t2
		qui intervalplot,keep notab noplot
		local dim:char _dta[network_dim]
		local ntm=`dim'+1
		local ncall=(`ntm'*(`ntm'-1))/2
		qui split _Comparison,par(" vs ") gen(_t)
		local y "_Effect_Size"
		local lci "_LCI"
		local uci "_UCI"
		local tt1 "_t1"
		local tt2 "_t2"
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
	else{
		if "`if'"!= ""{
			qui keep `if'
		}
		if "`in'"!= ""{
			qui keep `in'
		}			
		tokenize `varlist'

		local y `1'
		if "`5'"==""{
			tempvar lci uci
			local se `2'
			local tt1 `3'
			local tt2 `4'
			qui gen `lci'=`y'-abs(invnorm(0.025))*`se'
			qui gen `uci'=`y'+abs(invnorm(0.025))*`se'			
		}
		if "`5'"!=""{
			local lci `2'
			local uci `3'
			local tt1 `4'
			local tt2 `5'		
		}
		tempvar tnew1 tnew2 m1 m2
		cap lab drop _trt
		cap lab drop _ttrt	
		qui levelsof `tt1', local(t1levels)
		qui levelsof `tt2', local(t2levels)
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
		cap encode `tt1',gen(`tnew1') lab(_ttrt)
		cap encode `tt2',gen(`tnew2') lab(_ttrt)
		cap gen `tnew1'=`tt1'
		cap gen `tnew2'=`tt2'
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
		qui sort `tnew1' `tnew2' in 1/`ncall'
		local indt1=`tnew1' in 1
		local indt2=`tnew2' in 1
		if `indt1'<`indt2'{
			local tr1=`tt1' in 1
			forvalues i=2/`ntm'{
				local tr`i'=`tt2' in `=`i'-1'
			}
		}
		if `indt1'>`indt2'{
			qui sort `tnew2' `tnew1' in 1/`ncall'
			forvalues i=1/`dim'{
				local tr`i'=`tt2' in `=1+(`i'-1)*`ntm'-((`i'-1)/2)*`i''
			}
			local tr`ntm'=`tt1' in `ncall'
		}
	}
	forvalues i=1/`ntm'{
		local ord`i'=`i'
		cap drop _`tr`i''
	}
	if `"`sort'"' != ""{
		tokenize `"`sort'"'
		forvalues i=1/`ntm'{
			if "``i''"!=""{
				local s`i' "``i''"
			}
		}
		forvalues i=1/`ntm'{
			forvalues j=1/`ntm'{
				if "`lab`i''"=="`s`j''"{
					local ord`i'=`j'
				}
			}
		}	
	}
	forvalues j=1/`ntm'{
		forvalues i=1/`ntm'{
			if `ord`i''==`j'{
				cap gen _`tr`i''_es=.
				cap gen _`tr`i''_lci=.
				cap gen _`tr`i''_uci=.
			}
		}
	}
	tempvar ynew lcinew ucinew
	if "`eform'"!=""{
		qui gen `ynew'=exp(`y')
		qui gen `lcinew'=exp(`lci')
		qui gen `ucinew'=exp(`uci')
	}			
	else{
		qui gen `ynew'=`y'
		qui gen `lcinew'=`lci'
		qui gen `ucinew'=`uci'			
	}	
	forvalues i=1/`ntm'{
		forvalues j=1/`ntm'{
			forvalues k=1/`ncall'{
				if `tt1'[`k']=="`tr`i''" & `tt2'[`k']=="`tr`j''"{
					local es`i'_`j'=`ynew' in `k'
					local lci`i'_`j'=`lcinew' in `k'
					local uci`i'_`j'=`ucinew' in `k'					
				}
			}
			cap replace _`tr`i''_es=`es`i'_`j'' in `ord`j''
			cap replace _`tr`i''_lci=`lci`i'_`j'' in `ord`j''
			cap replace _`tr`i''_uci=`uci`i'_`j'' in `ord`j''
			if "`eform'"!=""{
				cap replace _`tr`j''_es=1/`es`i'_`j'' in `ord`i''
				cap replace _`tr`j''_lci=1/`uci`i'_`j'' in `ord`i''
				cap replace _`tr`j''_uci=1/`lci`i'_`j'' in `ord`i''			
			}
			else{
				cap replace _`tr`j''_es=-`es`i'_`j'' in `ord`i''
				cap replace _`tr`j''_lci=-`uci`i'_`j'' in `ord`i''
				cap replace _`tr`j''_uci=-`lci`i'_`j'' in `ord`i''		
			}
		}
	}
	foreach var of varlist _*_es _*_lci _*_uci{
		qui gen `var's=string(`var',"%9.2f")
	}
	tempvar par
	cap gen `par'=")"		
	forvalues j=1/`ntm'{
		forvalues i=1/`ntm'{
			if `ord`i''==`j'{	
				cap egen _`tr`i''_new1=concat(_`tr`i''_ess _`tr`i''_lcis) if _`tr`i''_es!=., punct(" (")
				cap egen _`tr`i''_new2=concat(_`tr`i''_new1 _`tr`i''_ucis) if _`tr`i''_es!=., punct(",")
				cap egen _`tr`i''_new3=concat(_`tr`i''_new2 `par') if _`tr`i''_es!=.
				cap drop _`tr`i''_es* _`tr`i''_lci* _`tr`i''_uci* _`tr`i''_new1 _`tr`i''_new2
				cap rename _`tr`i''_new3 _`tr`i''
				cap replace _`tr`i''="`lab`i''" in `j'
			}
		}
	}
	if "`nomvmeta'"==""{
		qui drop _Comparison `y' `lci' `uci' `tt1' `tt2'
		qui drop _LPrI _UPrI
	}	
	forvalues i=1/`ntm'{
		if `ord`i''==1{			
			local keep1 `" "_`tr`i''" "'
		}
	}
	forvalues i=1/`ntm'{
		if `ord`i''==`ntm'{			
			local keep2 `" "_`tr`i''" "'
		}
	}
	tempname kp1 kp2
	scalar `kp1'=`keep1'
	scalar `kp2'=`keep2'
	/*forvalues j=2/`ntm'{
		forvalues i=1/`ntm'{
			if `ord`i''==`j'{	
				local export`j' `" `export`=`j'-1'' " _`tr`i''" "'
			}
		}
	}*/
	if `"`export'"'!=""{
		qui export excel `=`kp1''-`=`kp2'' using `export' , replace
	}
	if "`nokeep'"==""{
		tempfile _DF
		qui keep `=`kp1''-`=`kp2''
		qui save `_DF'
		restore
		forvalues i=1/`ntm'{
			cap drop _`tr`i''
		}
		qui merge 1:1 _n using `_DF',nogen
		di as text _newline " {it:The league table has been stored at the end of the dataset}"
	}
	
end

	
	
	
	
	
