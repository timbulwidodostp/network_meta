*! version 2.0.0, 09.01.2018
//version 1.2.1, 26.06.2015, Anna Chaimani
 
program intervalplot
	syntax [varlist] [if] [in] , [NOMVmeta PREDictions EFORM LABels(string asis) FCICOLor(string) ///
	SCICOLor(string) FCIPATtern(string) SCIPATtern(string) NOVALues NULL(string) NULLOPTions(string asis) ///
	SYMBol(string) SCISYMBol(string) XTITLE(string) XLABel(string) Range(string) LABTitle(string) VALUESTitle(string) ///
	SYMBOLSize(string) TEXTSize(string) LWidth(string) MARgin(string asis) TITle(string asis) IMPute(string) ///
	REFerence(string) KEEP NOTABle NOPLot REVerse]
          
	preserve
	       
	if "`reference'"!="" & "`nomvmeta'"!=""{
		di as err "Option {it:reference()} may not be combined with option {it:nomvmeta}"
		exit
	}           
	if "`range'"!="" & "`xlabel'"==""{
		di as err "Option {it:range} requires option {it:xlabel()}"
		exit
	}               
	if "`predictions'"!="" & "`nomvmeta'"!=""{
		di as err "Option {it:predictions} may not be combined with option {it:nomvmeta}"
		exit
	}                     
          
	if "`eform'"!=""{
		local logscale "logscale"
	}
	else{
		local logscale ""
	}       
	if "`impute'"!=""{
		local imp=`impute'
	}
	else{
		local imp=1000
	}       
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
		local separate "separate"
		tempname _T
		mat `_T'=e(Sigma)               
		di as text _newline " The {cmd:intervalplot} command assumes that the saved results from {cmd:mvmeta} or {cmd:network meta} commands have been derived from the current dataset"
		if "`predictions'"!=""{
			if `_T'[1,1]!=`_T'[2,2]{
				di as err _newline " Option {it:predictions} requires a common heterogeneity parameter across all comparisons"
				exit
			}
		}
		local dim:char _dta[network_dim]
		local Slet:char _dta[network_S]
		local y:char _dta[network_y]
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
		qui{
			tempvar tnew1 tnew2 nsc
			tempname ncomp
			cap drop t1 t2
			network convert pairs
			local t1:char _dta[network_t1]
			local t2:char _dta[network_t2]
			encode `t1',gen(`tnew1') lab(_ttrt)
			encode `t2',gen(`tnew2') lab(_ttrt)
			by `t1' `t2',sort: gen `nsc'=_N
			by `t1' `t2',sort: replace `tnew1'=. if _n>1
			by `t1' `t2',sort: replace `tnew1'=. if `nsc'<=1
			mat `ncomp'=.
			cap mkmat `tnew1' if `tnew1'!=.,mat(`ncomp')
			local nmet=`=colsof(`ncomp')'
			local df=0
			local df=`ns'-`nmet'-1
			if `df'<1{
				local df=1
			}                       
		}
		if "`reference'"==""{
			local ncall=`ntm'*`dim'/2
		}
		else{
			local ncall=`dim'
		}
		cap set obs `=`ncall'+2*`dim'+1'
		if "`reference'"!=""{
			local ref `reference'
			forvalues i=1/`ntm'{
				if "`ref'"=="`lab`i''"{
					local indref=`i'
				}
			}
			if "`indref'"==""{
				di as err "The specified reference treatment does not exist in the dataset"
				exit
			}
			forvalues i=1/`ntm'{
				if "`ref'"!="`lab`i''"{
					if "`reverse'"==""{
						local y`i'_`indref'="`lab`i'' vs `ref'"
					}
					if "`reverse'"!=""{
						local y`indref'_`i'="`ref' vs `lab`i''"
					}
				}
			}
		}
		else{
			forvalues i=1/`=`ntm'-1'{
				forvalues j=`=`i'+1'/`ntm'{
					if "`reverse'"==""{
						local y`j'_`i'="`lab`j'' vs `lab`i''"
					}
					if "`reverse'"!=""{
						local y`i'_`j'="`lab`i'' vs `lab`j''"
					}                                       
				}
			}       
		}
		tempvar yvars
		qui gen `yvars'=""
		if "`reference'"!=""{
			forvalues i=1/`ntm'{
				if "`reverse'"==""{
					qui replace `yvars' in `i'="`y`i'_`indref''"
				}
				else{
					qui replace `yvars' in `i'="`y`indref'_`i''"
				}
			}
		}
		else{
			forvalues i=1/`=`ntm'-1'{
				forvalues j=`=`i'+1'/`ntm'{             
					local z=(`j'-1)+(`i'-1)*`ntm'-((`i'-1)/2)*`i'
					if "`reverse'"==""{
						qui replace `yvars' in `z'="`y`j'_`i''"
					}
					if "`reverse'"!=""{
						qui replace `yvars' in `z'="`y`i'_`j''"
					}                                       
				}
			}
		}       
		local tausq=`_T'[1,1]           
		mat _Y=vec(e(b))
		mat _Y=_Y[1..`dim',1]
		mat _V=vec(vecdiag(e(V)))
		mat _V=_V[1..`dim',1]
		forvalues i=2/`ntm'{
			local es`i'_1=_Y[`=`i'-1',1]
			local se`i'_1=sqrt(_V[`=`i'-1',1])
		}
		forvalues i=2/`=`ntm'-1'{
			forvalues j=`=`i'+1'/`ntm'{
				qui lincom [`y'_`tr`j'']_cons-[`y'_`tr`i'']_cons
				local es`j'_`i'=r(estimate)
				local se`j'_`i'=r(se)
			}
		}
		qui gen Effect_Size=.
		tempvar SE
		qui gen `SE'=.
		forvalues i=1/`ntm'{
			forvalues j=1/`ntm'{                    
				cap replace Effect_Size=`es`j'_`i'' if `yvars'=="`y`j'_`i''" & `yvars'!=""
				cap replace `SE'=`se`j'_`i'' if `yvars'=="`y`j'_`i''" & `yvars'!=""
				cap replace Effect_Size=-`es`j'_`i'' if `yvars'=="`y`i'_`j''" & `yvars'!=""
				cap replace `SE'=`se`j'_`i'' if `yvars'=="`y`i'_`j''" & `yvars'!=""
			}
		}      

		qui gen UCI=Effect_Size+abs(invnorm(0.025))*`SE'
		qui gen LCI=Effect_Size-abs(invnorm(0.025))*`SE'
		mat drop _Y 
		mat drop _V             
		if "`predictions'"!=""{
			qui gen UPrI=Effect_Size+abs(invttail(`df',0.025))*sqrt(`tausq'+`SE'^2)
			qui gen LPrI=Effect_Size-abs(invttail(`df',0.025))*sqrt(`tausq'+`SE'^2)
		}
		else{
			qui gen UPrI=UCI
			qui gen LPrI=LCI
		}       
		if "`reference'"!=""{
			cap sort Effect_Size            
		}               
		local mean1 Effect_Size
		local lci1 LCI
		local uci1 UCI
		local lci2 LPrI
		local uci2 UPrI
		local comb=1            
		tempvar comparator yvars11 yyvar
		if "`reference'"==""{
			local nplobs=(`ntm'-1)+(`ntm'-2)*`ntm'-((`ntm'-2)/2)*(`ntm'-1)
		}
		else{
			local nplobs=`ncall'
		}
		qui split `yvars' if `yvars'!="",gen(_yvars)
		forvalues i=0/`=`=_N'-2'{
			local z=`=_N'-`i'
			if "`reverse'"==""{
				qui replace _yvars3 in `z'="" if _yvars3[`z']==_yvars3[`=`z'-1']
				qui replace _yvars2="" if _yvars3==""
			}
			else{
				qui replace _yvars1 in `z'="" if _yvars1[`z']==_yvars1[`=`z'-1']
				qui replace _yvars2="" if _yvars1==""
			}
		}
		if "`reverse'"==""{
			qui replace _yvars3 in `dim'="" if _yvars3[`dim']==_yvars3[1]
			qui replace _yvars2="" if _yvars3==""
		}
		else{
			qui replace _yvars1 in `dim'="" if _yvars1[`dim']==_yvars1[1]
			qui replace _yvars2="" if _yvars1==""
		}               
		tempvar yyvar comparator
		if "`reverse'"==""{
			qui egen `comparator'=concat(_yvars2 _yvars3), punct(" ")
			qui egen `yyvar'=concat(_yvars1 `comparator' ), punct("          ")
			format `yyvar' %-10s
		}
		else{
			qui egen `comparator'=concat(_yvars1 _yvars2), punct(" ")
			qui egen `yyvar'=concat(`comparator' _yvars3), punct("          ")              
		}
		local labels `yyvar'
		tempname _labtitle _valtitle
		if "`labtitle'"!=""{
			scalar `_labtitle'="`labtitle'"
		}
		else{
			local labtitle "Comparison"
			scalar `_labtitle'="Comparison"
		}
		if "`valuestitle'"!=""{
			scalar `_valtitle'="`valuestitle'"
		}
		else{
			if "`predictions'"!=""{
				local valuestitle "ES (95%CI) (95%PrI)"
				scalar `_valtitle'="ES (95%CI) (95%PrI)"
			}
			else{
				local valuestitle "ES (95%CI)"
				scalar `_valtitle'="ES (95%CI)"
			}
		}
		if `"`margin'"'!=""{
			local margin=`"`margin'"'
		}
		else{
			local margin="30 50 2 2"
		}       
		if "`eform'"!=""{
			if "`logscale'"==""{
				foreach var in `mean1' `lci1' `uci1' `lci2' `uci2'{
					qui replace `var'=exp(`var')
				}
			}
		}                       
	}
	else{
		qui count `if' `in'
		local ncall=r(N)		
		if "`if'"!= ""{
			qui keep `if'
		}
		if "`in'"!= ""{
			qui keep `in'
		}		
		tokenize `varlist'
		if "`4'"!="" & "`5'"==""{
			local predictions "predictions"
			tempvar lci1 uci1 lci2 uci2
			local mean1 `1'
			local se1 `2'
			qui gen `lci1'=`mean1'-`se1'*invnorm(0.975)
			qui gen `uci1'=`mean1'+`se1'*invnorm(0.975)
			local mean2 `3'
			local se2 `4'
			qui gen `lci2'=`mean2'-`se2'*invnorm(0.975)
			qui gen `uci2'=`mean2'+`se2'*invnorm(0.975)
			if "`eform'"!=""{
				if "`logscale'"==""{
					foreach var in `mean1' `lci1' `uci1' `mean2' `lci2' `uci2'{
						qui replace `var'=exp(`var')
					}
				}
			}
			cap{
				assert `se1'>0
			}
			if _rc!=0{
				di as err "Negative value of standard error found" 
				exit
			}       
			cap{
				assert `se2'>0
			}
			if _rc!=0{
				di as err "Negative value of standard error found" 
				exit
			}               
		}
		if "`6'"!=""{
			local predictions "predictions"
			local mean1 `1'
			local lci1 `2'
			local uci1 `3'
			local mean2 `4'
			local lci2 `5'
			local uci2 `6'
			if "`eform'"!=""{
				if "`logscale'"==""{
					foreach var in `mean1' `lci1' `uci1' `mean2' `lci2' `uci2'{
						qui replace `var'=exp(`var')
					}
				}
			}
			cap{
				assert `lci1'<=`mean1' & `mean1'<=`uci1'
			}
			if _rc!=0{
				di as err "Confidence interval values wrongly specified found"
				exit 
			}       
			cap{
				assert `lci2'<=`mean2' & `mean2'<=`uci2'
			}
			if _rc!=0{
				di as err "Confidence interval values wrongly specified found"
				exit
			}               
		}
		if "`5'"!="" & "`6'"==""{
			local predictions "predictions"
			local comb=1
			local mean1 `1'
			local lci1 `2'
			local uci1 `3'  
			local lci2 `4'
			local uci2 `5'
			if "`eform'"!=""{
				if "`logscale'"==""{
					foreach var in `mean1' `lci1' `uci1' `mean2' `lci2' `uci2'{
						qui replace `var'=exp(`var')
					}
				}
			}               
			cap{
				assert `lci1'<=`mean1' & `mean1'<=`uci1' & `lci2'<=`mean1' & `mean1'<=`uci2'
			}
			if _rc!=0{
				di as err "Confidence interval values wrongly specified found"
				exit
			}                       
		}
		if "`4'"==""{
			local comb=1
			tempvar lci1 uci1 lci2 uci2
			cap{
				assert `2'<`1' & `3'>`1'
			}
			if _rc!=0{                      
				local mean1 `1'
				local se1 `2'
				qui gen `lci1'=`mean1'-`se1'*invnorm(0.975)
				qui gen `uci1'=`mean1'+`se1'*invnorm(0.975)     
				if "`3'"!=""{
					local predictions "predictions"
					local se2 `3'
					qui gen `lci2'=`mean1'-`se2'*invnorm(0.975)
					qui gen `uci2'=`mean1'+`se2'*invnorm(0.975)     
				}
				else{
					local predictions ""
					qui gen `lci2'=`lci1'
					qui gen `uci2'=`uci1'
				}  
				cap{
					assert `se1'>=0
				}
				if _rc!=0{
					di as err "Negative value of standard error found" 
					exit
				}       
				if "`3'"!=""{
					cap{
						assert `se2'>0
					}
					if _rc!=0{
						di as err "Negative value of standard error found" 
						exit
					}       
				}
			}
			else{
				local predictions ""
				local mean1 `1'
				local lci1 `2'
				local uci1 `3'  
				local lci2 `2'
				local uci2 `3'          
			}
			if "`eform'"!=""{
				if "`logscale'"==""{
					foreach var in `mean1' `lci1' `uci1' `mean2' `lci2' `uci2'{
						qui replace `var'=exp(`var')
					}
				}
			}                       
		}
	} 
	if `"`nulloptions'"'!=""{
		local noptions `"`nulloptions'"'
	}
	else{
		local noptions `"lcolor(blue) lwidth(thin)"'
	}       
	tempname _null

	if "`null'"!=""{
		scalar `_null'=real("`null'")
		if "`logscale'"!=""{
			scalar `_null'=log(real("`null'"))
		}
		local _xline "xline(`=`_null'',`noptions')"
	}
	else{
		local _xline ""
		scalar `_null'=.
	}
	if "`reference'"!=""{
		local nplobs=`dim'
	}
	tempname _min _max _nulll rankback
	qui gen `rankback'=_n
	if "`range'"!=""{
		tokenize `range'
		scalar `_min'="`1'"
		scalar `_max'="`2'"
		if "`logscale'"!=""{
			scalar `_min'=log(real(`_min'))
			scalar `_max'=log(real(`_max'))
			scalar `_nulll'=exp(`_null')
		}
		else{
			scalar `_min'=real(`_min')
			scalar `_max'=real(`_max')
			scalar `_nulll'=""
		}
	}
	tempname _lab14 _lab13 _minl _maxl _lab14l _lab13l
	else{
		tempvar _min1 _min2 _max1 _max2 
		qui egen `_min1'=min(`lci1')
		qui egen `_min2'=min(`lci2')
		qui egen `_max1'=max(`uci1')
		qui egen `_max2'=max(`uci2')                    
		scalar `_min'=round(min(`_min1',`_min2'),0.1)
		scalar `_max'=round(max(`_max1',`_max2'),0.1)
		scalar `_lab14'=round(`=`_min'+(`_max'-`_min')/4',0.1)
		scalar `_lab13'=round(`=`_max'-(`_max'-`_min')/4',0.1)  
		if "`logscale'"!=""{
			scalar `_minl'=string(round(exp(`=`_min''),0.1),"%9.1g")
			scalar `_maxl'=string(round(exp(`=`_max''),0.1),"%9.1g")
			scalar `_lab14l'=string(round(exp(`=`_lab14''),0.1),"%9.1g")
			scalar `_lab13l'=string(round(exp(`=`_lab13''),0.1),"%9.1g")
			scalar `_nulll'=exp(`_null')
		}
		else{
			scalar `_minl'=string(`_min',"%9.1g")
			scalar `_maxl'=string(`_max',"%9.1g")
			scalar `_lab14l'=string(`_lab14',"%9.1g")
			scalar `_lab13l'=string(`_lab13',"%9.1g")
			scalar `_nulll'=""
		}
	}
	tempname _lab _xmin _val _xmax
	scalar `_lab'=`_min'-((`_min'+`_max')/5)
	scalar `_xmin'=`_lab'-((`_min'+`_max')/5)
	scalar `_val'=`_max'+((`_min'+`_max')/5)
	scalar `_xmax'=`_val'+(`_min'+`_max')
	if "`xtitle'"!=""{
		local _xtitle "xtitle(`xtitle')"
	}
	else{
		local _xtitle ""
	}
	qui sort `rankback'
	tempname _ticks
	if "`xlabel'"!=""{
		if "`logscale'"!=""{
			scalar `_ticks'=wordcount("`xlabel'")
			tokenize `xlabel'
			forvalues i=1/`=`_ticks''{
				cap{
					assert real("``i''")>0
				}
				if _rc!=0{
					di as err "Specified values in option {it:xlabel} out of range"         
					exit _rc
				}
			}                       
			tempname _t1
			scalar `_t1'=log(real("`1'"))
			local _xlab1 `" `=`_t1'' "`1'" "'                       
			forvalues i=2/`=`_ticks''{
				tempname _t`i'
				scalar `_t`i''=log(real("``i''"))
				local _xlab`i' `"`_xlab`=`i'-1'' `=`_t`i''' "``i''""'
			}
			local _xlab `"`_xlab`=`_ticks''' `=`_null'' "`=`_nulll''""'
		}
		else{
			local _xlab `xlabel'
		}
	}
	else if "`null'"!=""{
		local _xlab `"`=`_min'' "`=`_minl''" `=`_lab14'' "`=`_lab14l''" `=`_null'' "`=`_nulll''" `=`_lab13'' "`=`_lab13l''" `=`_max'' "`=`_maxl''""'
	}
	else{
		local _xlab `"`=`_min'' "`=`_minl''" `=`_lab14'' "`=`_lab14l''" `=`_lab13'' "`=`_lab13l''" `=`_max'' "`=`_maxl''""'
	}       
	tempname _fcicolor _scicolor _fcipattern _scipattern _symbolsize _textsize _lwidth
	if "`fcicolor'"!=""{
		scalar `_fcicolor'="`fcicolor'"
	}
	else{
		scalar `_fcicolor'="black"
	}
	if "`scicolor'"!=""{
		scalar `_scicolor'="`scicolor'"
	}
	else{
		scalar `_scicolor'="cranberry"
	}
	if "`fcipattern'"!=""{
		scalar `_fcipattern'="`fcipattern'"
	}
	else{
		scalar `_fcipattern'="solid"
	}
	if "`scipattern'"!=""{
		scalar `_scipattern'="`scipattern'"
	}
	else{
		scalar `_scipattern'="solid"
	}       
	if "`symbolsize'"!=""{
		scalar `_symbolsize'="`symbolsize'"
	}
	else{
		scalar `_symbolsize'="small"
	}       
	if "`textsize'"!=""{
		scalar `_textsize'="`textsize'"
	}
	else{
		scalar `_textsize'="small"
	}       
	if "`lwidth'"!=""{
		scalar `_lwidth'="`lwidth'"
	}
	else{
		scalar `_lwidth'="thin"
	}       
	if `"`margin'"'!=""{
		local margin=`"`margin'"'
	}
	else{
		local margin="15 15 2 2"
	}       
	if "`separate'"=="" & "`nomvmeta'"!=""{
		local nplobs=`ncall'
	}    

	forvalues i=1/`nplobs'{
		tempname _lci1_`i' _uci1_`i' _lci2_`i' _uci2_`i' _pos1_`i' _pos2_`i' _mean1_`i' _mean2_`i'
		scalar `_lci1_`i''=`lci1' in `i'
		scalar `_uci1_`i''=`uci1' in `i'
		scalar `_lci2_`i''=`lci2' in `i'
		scalar `_uci2_`i''=`uci2' in `i'
		scalar `_pos1_`i''=2*(`nplobs'-`i')
		scalar `_pos2_`i''=`_pos1_`i''-1
		scalar `_mean1_`i''=`mean1' in `i'
	}
	if `comb'==0{
		forvalues i=1/`nplobs'{
			scalar `_mean2_`i''=`mean2' in `i'
		}
	}
	forvalues i=1/`nplobs'{
		tempname _symbol_`i' _scisymbol_`i'
		tempname _lci1n_`i' _lci2n_`i' _uci1n_`i' _uci2n_`i'
	}
	if "`range'"!=""{
		forvalues i=1/`nplobs'{
			if `_mean1_`i''<`_min' | `_mean1_`i''>`_max'{
				scalar `_symbol_`i''="i"
			}
			else if "`symbol'"!=""{
				scalar `_symbol_`i''="`symbol'"
			}
			else{
				scalar `_symbol_`i''="diamond"
			}                       
			if `_comb'==0{
				if `_mean2_`i''<`_min' | `_mean2_`i''>`_max'{
					scalar `_scisymbol_`i''="i"
				}
				else if "`scisymbol'"!=""{
					scalar `_scisymbol_`i''="`scisymbol'"
				}       
				else{
					scalar `_scisymbol_`i''="circle"
				}                                       
			}
			if `_lci1_`i''!=.{
				scalar `_lci1n_`i''=max(`_lci1_`i'',`_min')
				scalar `_lci2n_`i''=max(`_lci2_`i'',`_min')
				scalar `_uci1n_`i''=min(`_uci1_`i'',`_max')
				scalar `_uci2n_`i''=min(`_uci2_`i'',`_max')
			}
			else{
				scalar `_lci1n_`i''=`_lci1_`i''
				scalar `_lci2n_`i''=`_lci2_`i''
				scalar `_uci1n_`i''=`_uci1_`i''
				scalar `_uci2n_`i''=`_uci2_`i''
			}
		}
		if `_lci1n_1'>`_lci1_1'{
			local _ci1_1 `"pcarrowi `=`_pos1_1'' `=`_uci1n_1'' `=`_pos1_1'' `=`_lci1n_1'' ,msize(`=`_symbolsize'') barbsize(`=`_symbolsize'') mcolor(`=`_fcicolor'') mlwidth(`=`_lwidth'') lcolor(`=`_fcicolor'') lwidth(`=`_lwidth'') lpattern(`=`_fcipattern'') mlcolor(`=`_fcicolor'')||pci `=`=`_pos1_1''+`nplobs'/95' `=`_uci1n_1'' `=`=`_pos1_1''-`nplobs'/95' `=`_uci1n_1'',lcolor(`=`_fcicolor'') lwidth(medthin)||"'
		}
		if `_lci2n_1'>`_lci2_1'{
			if `comb'==0{
				local _ci2_1 `"pcarrowi `=`_pos2_1'' `=`_uci2n_1'' `=`_pos2_1'' `=`_lci2n_1'' , msize(`=`_symbolsize'') barbsize(`=`_symbolsize'') mcolor(`=`_scicolor'') mlwidth(`=`_lwidth'') lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'') mlcolor(`=`_scicolor'')||"'
			}
			else{
				local _ci2_1 `"pcarrowi `=`_pos1_1'' `=`_uci2n_1'' `=`_pos1_1'' `=`_lci2n_1'' ,msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_scicolor'') lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'') mlcolor(`=`_scicolor'')||"'
			}
		}
		if `_uci1n_1'<`_uci1_1'{
			local _ci1_1 `"pcarrowi `=`_pos1_1'' `=`_lci1n_1'' `=`_pos1_1'' `=`_uci1n_1'',msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_fcicolor'') lcolor(`=`_fcicolor'') lwidth(`=`_lwidth'') lpattern(`=`_fcipattern'') mlcolor(`=`_fcicolor'')||pci `=`=`_pos1_1''+`nplobs'/95' `=`_lci1n_1'' `=`=`_pos1_1''-`nplobs'/95' `=`_lci1n_1'',lcolor(`=`_fcicolor'') lwidth(medthin)||"'
		}
		if `_uci2n_1'<`_uci2_1'{
			if `comb'==0{
				local _ci2_1 `"pcarrowi `=`_pos2_1'' `=`_lci2n_1'' `=`_pos2_1'' `=`_uci2n_1'' ,msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_scicolor'') lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'') mlcolor(`=`_scicolor'')||"'
			}
			else{
				local _ci2_1 `"pcarrowi `=`_pos1_1'' `=`_lci2n_1'' `=`_pos1_1'' `=`_uci2n_1'' ,msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_scicolor'') lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'') mlcolor(`=`_scicolor'')||"'
			}
		}
		if `_lci1n_1'>`_lci1_1' & `_uci1n_1'<`_uci1_1'{
			local _ci1_1 `"pcarrowi `=`_pos1_1'' `=`_uci1n_1'' `=`_pos1_1'' `=`_lci1n_1'' ,msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_fcicolor'') lcolor(`=`_fcicolor'') lwidth(`=`_lwidth'') lpattern(`=`_fcipattern'') mlcolor(`=`_fcicolor'')|| pcarrowi `=`_pos1_1'' `=`_lci1n_1'' `=`_pos1_1'' `=`_uci1n_1'',msize(`=`_symbolsize'') barbsize(`=`_symbolsize'') mcolor(`=`_fcicolor'') mlwidth(`=`_lwidth'') lcolor(`=`_fcicolor'') lwidth(`=`_lwidth'') lpattern(blank) mlcolor(`=`_fcicolor'')||"'
		}
		if `_lci2n_1'>`_lci2_1' & `_uci2n_1'<`_uci2_1'{
			if `comb'==0{
				local _ci2_1 `"pcarrowi `=`_pos2_1'' `=`_uci2n_1'' `=`_pos2_1'' `=`_lci2n_1'' ,msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_scicolor'') lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'') mlcolor(`=`_scicolor'')|| pcarrowi `=`_pos2_1'' `=`_lci2n_1'' `=`_pos2_1'' `=`_uci2n_1'',msize(`=`_symbolsize'') barbsize(`=`_symbolsize'') mcolor(`=`_scicolor'') mlwidth(`=`_lwidth'') lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(blank) mlcolor(`=`_scicolor'')||"'
			}
			else{
				local _ci2_1 `"pcarrowi `=`_pos1_1'' `=`_uci2n_1'' `=`_pos1_1'' `=`_lci2n_1'' ,msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_scicolor'') lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'') mlcolor(`=`_scicolor'')|| pcarrowi `=`_pos1_1'' `=`_lci2n_1'' `=`_pos1_1'' `=`_uci2n_1'',msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_scicolor'') lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(blank) mlcolor(`=`_scicolor'')||"'
			}
		}
		if `_lci1n_1'<=`_lci1_1' & `_uci1n_1'>=`_uci1_1'{
			local _ci1_1 `"pci `=`_pos1_1'' `=`_lci1n_1'' `=`_pos1_1'' `=`_uci1n_1'',lcolor(`=`_fcicolor'') lwidth(`=`_lwidth'') lpattern(`=`_fcipattern'')||pci `=`=`_pos1_1''+`nplobs'/95' `=`_lci1n_1'' `=`=`_pos1_1''-`nplobs'/95' `=`_lci1n_1'',lcolor(`=`_fcicolor'') lwidth(medthin)||pci `=`=`_pos1_1''+`nplobs'/95' `=`_uci1n_1'' `=`=`_pos1_1''-`nplobs'/95' `=`_uci1n_1'',lcolor(`=`_fcicolor'') lwidth(medthin)||"'
		}
		if `_lci2n_1'<=`_lci2_1' & `_uci2n_1'>=`_uci2_1'{
			if `comb'==0{
				local _ci2_1 `"pci `=`_pos2_1'' `=`_lci2n_1'' `=`_pos2_1'' `=`_uci2n_1'',lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'') mlcolor(`=`_scicolor'')||"'
			}
			else{
				local _ci2_1 `"pci `=`_pos1_1'' `=`_lci2n_1'' `=`_pos1_1'' `=`_uci2n_1'',lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'') mlcolor(`=`_scicolor'')||"'
			}
		}
		forvalues i=2/`nplobs'{
			if `_lci1n_`i''>`_lci1_`i''{
				local _ci1_`i' `" `_ci1_`=`i'-1'' || pcarrowi `=`_pos1_`i''' `=`_uci1n_`i''' `=`_pos1_`i''' `=`_lci1n_`i''' ,msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_fcicolor'') lcolor(`=`_fcicolor'') lwidth(`=`_lwidth'') lpattern(`=`_fcipattern'') mlcolor(`=`_fcicolor'')||pci `=`=`_pos1_`i'''+`nplobs'/95' `=`_uci1n_`i''' `=`=`_pos1_`i'''-`nplobs'/95' `=`_uci1n_`i''',lcolor(`=`_fcicolor'') lwidth(medthin)||"'
			}
			if `_lci2n_`i''>`_lci2_`i''{
				if `comb'==0{
					local _ci2_`i' `" `_ci2_`=`i'-1'' || pcarrowi `=`_pos2_`i''' `=`_uci2n_`i''' `=`_pos2_`i''' `=`_lci2n_`i''' ,msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_scicolor'') lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'') mlcolor(`=`_scicolor'')||"'
				}
				else{
					local _ci2_`i' `" `_ci2_`=`i'-1'' || pcarrowi `=`_pos1_`i''' `=`_uci2n_`i''' `=`_pos1_`i''' `=`_lci2n_`i''' ,msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_scicolor'') lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'') mlcolor(`=`_scicolor'')||"'
				}
			}
			if `_uci1n_`i''<`_uci1_`i''{
				local _ci1_`i' `" `_ci1_`=`i'-1'' || pcarrowi `=`_pos1_`i''' `=`_lci1n_`i''' `=`_pos1_`i''' `=`_uci1n_`i''',msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_fcicolor'') lcolor(`=`_fcicolor'') lwidth(`=`_lwidth'') lpattern(`=`_fcipattern'') mlcolor(`=`_fcicolor'')||pci `=`=`_pos1_`i'''+`nplobs'/95' `=`_lci1n_`i''' `=`=`_pos1_`i'''-`nplobs'/95' `=`_lci1n_`i''',lcolor(`=`_fcicolor'') lwidth(medthin)||"'
			}
			if `_uci2n_`i''<`_uci2_`i''{
				if `comb'==0{
					local _ci2_`i' `" `_ci2_`=`i'-1'' || pcarrowi `=`_pos2_`i''' `=`_lci2n_`i''' `=`_pos2_`i''' `=`_uci2n_`i''' ,msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_scicolor'') lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'') mlcolor(`=`_scicolor'')||"'
				}
				else{
					local _ci2_`i' `" `_ci2_`=`i'-1'' || pcarrowi `=`_pos1_`i''' `=`_lci2n_`i''' `=`_pos1_`i''' `=`_uci2n_`i''' ,msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_scicolor'') lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'') mlcolor(`=`_scicolor'')||"'
				}
			}
			if `_lci1n_`i''>`_lci1_`i'' & `_uci1n_`i''<`_uci1_`i''{
				local _ci1_`i' `" `_ci1_`=`i'-1'' || pcarrowi `=`_pos1_`i''' `=`_uci1n_`i''' `=`_pos1_`i''' `=`_lci1n_`i''' ,msize(`=`_symbolsize'') barbsize(`=`_symbolsize'') mcolor(`=`_fcicolor'') lcolor(`=`_fcicolor'') lwidth(`=`_lwidth'') mlwidth(`=`_lwidth'') lpattern(`=`_fcipattern'') mlcolor(`=`_fcicolor'')|| pcarrowi `=`_pos1_`i''' `=`_lci1n_`i''' `=`_pos1_`i''' `=`_uci1n_`i''',msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_fcicolor'') lcolor(`=`_fcicolor'') lwidth(`=`_lwidth'') lpattern(blank) mlcolor(`=`_fcicolor'')||"'
			}
			if `_lci2n_`i''>`_lci2_`i'' & `_uci2n_`i''<`_uci2_`i''{
				if `comb'==0{
					local _ci2_`i' `" `_ci2_`=`i'-1'' || pcarrowi `=`_pos2_`i''' `=`_uci2n_`i''' `=`_pos2_`i''' `=`_lci2n_`i''' ,msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_scicolor'') lcolor(`=`_scicolor'') mlwidth(`=`_lwidth'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'') mlcolor(`=`_scicolor'')|| pcarrowi `=`_pos2_`i''' `=`_lci2n_`i''' `=`_pos2_`i''' `=`_uci2n_`i''',msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_scicolor'') lcolor(`=`_scicolor'') lpattern(blank) lwidth(`=`_lwidth'') mlcolor(`=`_scicolor'')||"'
				}
				else{
					local _ci2_`i' `" `_ci2_`=`i'-1'' || pcarrowi `=`_pos1_`i''' `=`_uci2n_`i''' `=`_pos1_`i''' `=`_lci2n_`i''' ,msize(`=`_symbolsize'') mlwidth(`=`_lwidth'') barbsize(`=`_symbolsize'') mcolor(`=`_scicolor'') lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'') mlcolor(`=`_scicolor'')|| pcarrowi `=`_pos1_`i''' `=`_lci2n_`i''' `=`_pos1_`i''' `=`_uci2n_`i''',msize(`=`_symbolsize'') barbsize(`=`_symbolsize'') mcolor(`=`_scicolor'') lcolor(`=`_scicolor'') mlwidth(`=`_lwidth'') lwidth(`=`_lwidth'') lpattern(blank) mlcolor(`=`_scicolor'')||"'
				}
			}
			if `_lci1n_`i''<=`_lci1_`i'' & `_uci1n_`i''>=`_uci1_`i''{       
				local _ci1_`i' `" `_ci1_`=`i'-1'' || pci `=`_pos1_`i''' `=`_lci1n_`i''' `=`_pos1_`i''' `=`_uci1n_`i''',lcolor(`=`_fcicolor'') lwidth(`=`_lwidth'') lpattern(`=`_fcipattern'')||pci `=`=`_pos1_`i'''+`nplobs'/95' `=`_lci1n_`i''' `=`=`_pos1_`i'''-`nplobs'/95' `=`_lci1n_`i''',lcolor(`=`_fcicolor'') lwidth(medthin)||pci `=`=`_pos1_`i'''+`nplobs'/95' `=`_uci1n_`i''' `=`=`_pos1_`i'''-`nplobs'/95' `=`_uci1n_`i''',lcolor(`=`_fcicolor'') lwidth(medthin)||"'
			}
			if `_lci2n_`i''<=`_lci2_`i'' & `_uci2n_`i''>=`_uci2_`i''{
				if `comb'==0{
					local _ci2_`i' `" `_ci2_`=`i'-1'' || pci `=`_pos2_`i''' `=`_lci2n_`i''' `=`_pos2_`i''' `=`_uci2n_`i''',lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'')||"'
				}
				else{
					local _ci2_`i' `" `_ci2_`=`i'-1'' || pci `=`_pos1_`i''' `=`_lci2n_`i''' `=`_pos1_`i''' `=`_uci2n_`i''',lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'')||"'       
				}
			}
		}
	}
	else{
		forvalues i=1/`nplobs'{
			if "`symbol'"!=""{
				scalar `_symbol_`i''="`symbol'"
			}
			else{
				scalar `_symbol_`i''="diamond"
			}       
			if `comb'==0{
				if "`scisymbol'"!=""{
					scalar `_scisymbol_`i''="`scisymbol'"
				}       
				else{
					scalar `_scisymbol_`i''="circle"
				}
			}
			scalar `_lci1n_`i''=`_lci1_`i''
			scalar `_lci2n_`i''=`_lci2_`i''
			scalar `_uci1n_`i''=`_uci1_`i''
			scalar `_uci2n_`i''=`_uci2_`i'' 
		}
		local _ci1_1 `"pci `=`_pos1_1'' `=`_lci1n_1'' `=`_pos1_1'' `=`_uci1n_1'',lcolor(`=`_fcicolor'') lwidth(`=`_lwidth'') lpattern(`=`_fcipattern'')||pci `=`=`_pos1_1''+`nplobs'/95' `=`_lci1n_1'' `=`=`_pos1_1''-`nplobs'/95' `=`_lci1n_1'',lcolor(`=`_fcicolor'') lwidth(medthin)||pci `=`=`_pos1_1''+`nplobs'/95' `=`_uci1n_1'' `=`=`_pos1_1''-`nplobs'/95' `=`_uci1n_1'',lcolor(`=`_fcicolor'') lwidth(medthin)||"'
		forvalues i=2/`nplobs'{
			local _ci1_`i' `" `_ci1_`=`i'-1'' ||pci `=`_pos1_`i''' `=`_lci1n_`i''' `=`_pos1_`i''' `=`_uci1n_`i''',lcolor(`=`_fcicolor'') lwidth(`=`_lwidth'') lpattern(`=`_fcipattern'')||pci `=`=`_pos1_`i'''+`nplobs'/95' `=`_lci1n_`i''' `=`=`_pos1_`i'''-`nplobs'/95' `=`_lci1n_`i''',lcolor(`=`_fcicolor'') lwidth(medthin)||pci `=`=`_pos1_`i'''+`nplobs'/95' `=`_uci1n_`i''' `=`=`_pos1_`i'''-`nplobs'/95' `=`_uci1n_`i''',lcolor(`=`_fcicolor'') lwidth(medthin)||"'
		}
		if `comb'==0{
			local _ci2_1 `"pci `=`_pos2_1'' `=`_lci2n_1'' `=`_pos2_1'' `=`_uci2n_1'',lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'')||"'
			forvalues i=2/`nplobs'{
				local _ci2_`i' `" `_ci2_`=`i'-1'' ||pci `=`_pos2_`i''' `=`_lci2n_`i''' `=`_pos2_`i''' `=`_uci2n_`i''',lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'')||"'
			}
		}
		else{
			local _ci2_1 `"pci `=`_pos1_1'' `=`_lci2n_1'' `=`_pos1_1'' `=`_uci2n_1'',lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'')||"'     
			forvalues i=2/`nplobs'{
				local _ci2_`i' `" `_ci2_`=`i'-1'' ||pci `=`_pos1_`i''' `=`_lci2n_`i''' `=`_pos1_`i''' `=`_uci2n_`i''',lcolor(`=`_scicolor'') lwidth(`=`_lwidth'') lpattern(`=`_scipattern'')||"'        
			}
		}
	}
	if `"`labels'"'!=""{
		forvalues i=1/`nplobs'{
			scalar _lab_`i'=`labels' in `i'
			if `comb'==0{
				scalar _poslab_`i'=(`_pos1_`i''+`_pos2_`i'')/2
			}
			else{
				scalar _poslab_`i'=`_pos1_`i''
			}
		}
		if "`separate'"!=""{
			local _cilab_1 `"scatteri `=_poslab_1' `=`=`_lab''-1.5' "`=_lab_1'",mlabpos(3) msymbol(i) mlabcol(black) mlabsize(`=`_textsize'')||"'
			forvalues i=2/`nplobs'{
				local _cilab_`i' `" `_cilab_`=`i'-1'' ||scatteri `=_poslab_`i'' `=`=`_lab''-1.5' "`=_lab_`i''",mlabpos(3) msymbol(i) mlabsize(`=`_textsize'') mlabcol(black)||"'
			}
		}
		else{
			local _cilab_1 `"scatteri `=_poslab_1' `=`=`_lab''-0.5' "`=_lab_1'",mlabpos(9) msymbol(i) mlabcol(black) mlabsize(`=`_textsize'')||"'
			forvalues i=2/`nplobs'{
				local _cilab_`i' `" `_cilab_`=`i'-1'' ||scatteri `=_poslab_`i'' `=`=`_lab''-0.5' "`=_lab_`i''",mlabpos(9) msymbol(i) mlabsize(`=`_textsize'') mlabcol(black)||"'
			}               
		}
	}
	else{
		local _cilab_`nplobs' `""'
	}
	local _cimean1_1 `"scatteri `=`_pos1_1'' `=`_mean1_1'',mcolor(`=`_fcicolor'') msize(`=`_symbolsize'') msymbol(`=`_symbol_1'')||"'
	forvalues i=2/`nplobs'{
		local _cimean1_`i' `" `_cimean1_`=`i'-1'' ||scatteri `=`_pos1_`i''' `=`_mean1_`i''',mcolor(`=`_fcicolor'') msize(`=`_symbolsize'') msymbol(`=`_symbol_`i''')||"'
	}
	if `comb'==0{
		local _cimean2_1 `"scatteri `=`_pos2_1'' `=`_mean2_1'',mcolor(`=`_scicolor'') msize(`=`_symbolsize'') msymbol(`=`_scisymbol_1'')||"'
		forvalues i=2/`nplobs'{
			local _cimean2_`i' `" `_cimean2_`=`i'-1'' || scatteri `=`_pos2_`i''' `=`_mean2_`i''',mcolor(`=`_scicolor'') msize(`=`_symbolsize'') msymbol(`=`_scisymbol_`i''')||"'
		}
	}
	else{
		local _cimean2_`nplobs' `""'
	}
	if "`labtitle'"!=""{
		if `"`labels'"'==""{
			di as err "Option {it:labtitle} requires option {it:labels}"
			exit
		}
		else{
			scalar `_labtitle'="`labtitle'"
			scalar _poslabtitle=2*`nplobs'+0.5
			local _cilabtit `"scatteri `=_poslabtitle' `=`=`_lab''-0.5' "{bf:`=`_labtitle''}",mlabpos(9) msymbol(i) mlabsize(`=`_textsize'') mlabcol(black)||"'
		}
	}
	else{
		local _cilabtit `""'
	}
	if "`novalues'"==""{
		tempvar _smean1 _slci1 _slci2 _suci1 _suci2
		if "`logscale'"!=""{
			qui gen `_smean1'=rtrim(string(round(exp(`mean1'),0.01),"%9.2f")) 
			qui gen `_slci1'=rtrim(string(round(exp(`lci1'),0.01),"%9.2f"))
			qui gen `_slci2'=rtrim(string(round(exp(`lci2'),0.01),"%9.2f"))
			qui gen `_suci1'=rtrim(string(round(exp(`uci1'),0.01),"%9.2f"))
			qui gen `_suci2'=rtrim(string(round(exp(`uci2'),0.01),"%9.2f"))
			if `comb'==0{
				tempvar _smean2
				qui gen `_smean2'=rtrim(string(round(exp(`mean2'),0.01),"%9.2f")) 
			}               
		}
		else{
			qui gen `_smean1'=rtrim(string(round(`mean1',0.01),"%9.2f")) 
			qui gen `_slci1'=rtrim(string(round(`lci1',0.01),"%9.2f"))
			qui gen `_slci2'=rtrim(string(round(`lci2',0.01),"%9.2f"))
			qui gen `_suci1'=rtrim(string(round(`uci1',0.01),"%9.2f"))
			qui gen `_suci2'=rtrim(string(round(`uci2',0.01),"%9.2f"))
			if `comb'==0{
				tempvar _smean2
				qui gen `_smean2'=rtrim(string(round(`mean2',0.01),"%9.2f")) 
			}
		}
		tempvar _c1 _c2 _a _b _cc1 _cc2 _values1 _values2 _values
		qui egen `_cc1'=concat(`_slci1' `_suci1'),punct(,)
		qui egen `_cc2'=concat(`_slci2' `_suci2'),punct(,)
		qui gen `_a'="("
		qui gen `_b'=")"
		qui egen `_c1'=concat(`_a' `_cc1' `_b')
		qui egen `_c2'=concat(`_a' `_cc2' `_b')
		qui egen `_values1'=concat(`_smean1' `_c1'),punct(" ")
		qui replace `_values1'=rtrim(`_values1')
		if `comb'==0{
			qui egen `_values2'=concat(`_smean2' `_c2'),punct(" ")
			qui replace `_values2'=rtrim(`_values2')
		}
		else{
			if "`predictions'"!=""{
				qui gen `_values2'=`_c2'
			}
			else{
				qui gen `_values2'=""
			}
			qui egen `_values'=concat(`_values1' `_values2'),punct("  ")
			qui replace `_values'="" if `mean1'==.
			qui replace `_values'=rtrim(`_values')
		}
		if `comb'==0{
			forvalues i=1/`nplobs'{
				scalar _values1_`i'=`_values1' in `i'
				scalar _values2_`i'=`_values2' in `i'
			}
			local _cival1_1 `"scatteri `=`_pos1_1'' `=`_val'' "`=_values1_1'",mlabpos(3) msymbol(i) mlabcol(black) mlabsize(`=`_textsize'')||"'
			local _cival2_1 `"scatteri `=`_pos2_1'' `=`_val'' "`=_values2_1'",mlabpos(3) msymbol(i) mlabcol(black) mlabsize(`=`_textsize'')||"'
			forvalues i=2/`nplobs'{
				local  _cival1_`i' `" `_cival1_`=`i'-1'' ||scatteri `=`_pos1_`i''' `=`_val'' "`=_values1_`i''",mlabpos(3) msymbol(i) mlabcol(black) mlabsize(`=`_textsize'')||"'
				local  _cival2_`i' `" `_cival2_`=`i'-1'' ||scatteri `=`_pos2_`i''' `=`_val'' "`=_values2_`i''",mlabpos(3) msymbol(i) mlabcol(black) mlabsize(`=`_textsize'')||"'
			}
		}
		else{
			forvalues i=1/`nplobs'{
				scalar _values_`i'=`_values' in `i'
			}
			local  _cival1_1 `"scatteri `=`_pos1_1'' `=`_val'' "`=_values_1'",mlabpos(3) msymbol(i) mlabcol(black) mlabsize(`=`_textsize'')||"'
			forvalues i=2/`nplobs'{
				local  _cival1_`i' `" `_cival1_`=`i'-1'' ||scatteri `=`_pos1_`i''' `=`_val'' "`=_values_`i''",mlabpos(3) msymbol(i) mlabcol(black) mlabsize(`=`_textsize'')||"'
				local  _cival2_`nplobs' `""'
			}
		}       
	}
	else{
		local  _cival1_`nplobs' `""'
		local  _cival2_`nplobs' `""'
	}
	tempname _posvaltitle _valtitle
	if "`valuestitle'"!=""{
		if "`novalues'"!=""{
			di as err "Option {it:valuestitle} may not be combined with option {it:novalues}"
			exit
		}
		else{
			scalar `_valtitle'="`valuestitle'"
			scalar `_posvaltitle'=2*`nplobs'+0.5
			local _civaltit `"scatteri `=`_posvaltitle'' `=`_val'' "{bf:`=`_valtitle''}",mlabpos(3) msymbol(i) mlabcol(black) mlabsize(`=`_textsize'')||"'
		}
	}
	else{
		local _civaltit `""'
	}
	local _note "Heterogeneity variance = `=round(`tausq',0.01)'"
	if "`reference'"!="" & "`nomvmeta'"==""{
		cap gen Comparison=`yvars11'
	}
	if "`notable'"=="" | "`keep'"!=""{
		cap gen Comparison=`yvars'
	}
	if "`notable'"==""{
		if  "`reference'"=="" & "`nomvmeta'"==""{
			li Comparison Effect_Size LCI UCI LPrI UPrI if Comparison!="",table div noobs separator(0) abbreviate(20)
		}       
		if "`reference'"!=""{   
			di as text _newline " * Reference treatment = `ref' "
			li Comparison Effect_Size LCI UCI LPrI UPrI if Comparison!="",table div noobs separator(0) abbreviate(20)
		}
	}
	if "`nomvmeta'"==""{
		if "`reference'"=="" & `ntm'>10 & "`noplot'"==""{
			di as err "For networks with more than 10 interventions a reference treatment should be specified in option {it:reference()} to obtain the graph"
			exit
		}
	}
	if "`noplot'"==""{
		cap{
			twoway `_ci2_`nplobs'' || `_ci1_`nplobs'' || `_cilab_`nplobs'' || `_cimean1_`nplobs'' || `_cimean2_`nplobs'' || `_cival1_`nplobs'' || `_cival2_`nplobs'' || `_civaltit' || `_cilabtit', yscale(off) legend(off) xscale(range(`=`_xmin'' `=`_xmax'')) xlabel(`_xlab') ylab(-1(1)`=`_pos1_1'') `_xline' `_xtitle' ylabels(, nogrid)  plotregion(margin(`margin')) title(`"`title'"') note(`"`_note'"')
		}
		if _rc!=0{
			di as err "Plot options wrongly specified"
			exit
		}
	}

	if "`keep'"!=""{
		qui{		
			tempname es es2 lci uci lpri upri
			split Comparison ,pars(" vs ")
			mkmat Effect_Size if Effect_Size!=., mat(`es') rownames(Comparison1)
			mkmat Effect_Size if Effect_Size!=., mat(`es2') rownames(Comparison2)
			mkmat LCI if Effect_Size!=.,mat(`lci')
			mkmat UCI if Effect_Size!=.,mat(`uci')
			cap mkmat LPrI if Effect_Size!=., mat(`lpri')
			cap mkmat UPrI if Effect_Size!=., mat(`upri')
			restore 
			cap drop Comparison Comparison1 Comparison2
			cap drop Effect_Size
			cap drop LCI UCI
			cap drop LPrI UPrI			
			cap set obs `ncall'
			cap drop _Comparison _Effect_Size _LCI _UCI
			cap drop _LPrI _UPrI
			local rownames1 : rowfullnames `es'
			local rownames2 : rowfullnames `es2'
			local c1 : word count `rownames1'
			local c2 : word count `rownames2'
			gen _Comparison1=""
			gen _Comparison2=""
			forvalues i = 1/`c1' {
				replace _Comparison1 = "`:word `i' of `rownames1''" in `i'                        
			}
			forvalues i = 1/`c2' {
				replace _Comparison2 = "`:word `i' of `rownames2''" in `i'                        
			}
			egen _Comparison=concat(_Comparison1 _Comparison2) if _Comparison1!="", punct(" vs ")
			drop _Comparison1 _Comparison2
			svmat `es',names(_Effect_Size)
			rename _Effect_Size1 _Effect_Size
			svmat `lci',names(_LCI)
			rename _LCI1 _LCI
			svmat `uci',names(_UCI)
			rename _UCI1 _UCI
			cap svmat `lpri',names(_LPrI)
			cap rename _LPrI1 _LPrI
			cap svmat `upri',names(_UPrI)   
			cap rename _UPrI _UPrI1
		}	
	}
end
