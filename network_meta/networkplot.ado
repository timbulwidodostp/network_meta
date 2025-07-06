*! version 2.0.1, 24.05.2019
//version 2.0.0, 09.01.2018
//version 1.2, 11.02.2014, Anna Chaimani/Ian White
//version 1.1, 12.12.2013, Anna Chaimani

program networkplot
	syntax varlist(min=2 max=2) [if] [in] , [NODEWeight(string) EDGEWeight(string) NOWeight NODEColor(string) EDGEColor(string) EDGEPattern(string) LABels(string asis) LABSize(string) PLOTREGion(string asis) ASPect(string) EDGEScale(string) NODEScale(string) BYLEVels(string) BYCOLors(string asis) LOCation(name) f9 *]
	local twowayoptions `options'
	
	preserve
	
	if "`bylevels'"!="" & "`bycolors'"==""{
		di as err "Option {it:bylevels} requires option {it:bycolors}"
		exit
	}
	if "`bylevels'"=="" & "`bycolors'"!=""{
		di as err "Option {it:bycolors} requires option {it:bylevels}"
		exit
	}
	if "`noweight'"==""{
		local wperstudies "wperstudies"
	}
	else{
		local wperstudies ""
	}
	if "`labsize'"!=""{
		local labsize `labsize'
	}
	else{
		local labsize ""
	}
	local form:char _dta[network_format]
	if "`form'"!="pairs"{
		di as err "Data not in pairs format, see {helpb network setup} or {helpb network import} for details"
		exit
	} 	
	qui network convert augment
	local dim:char _dta[network_dim]
	qui network convert pairs
	local ntm=`dim'+1
	local ref:char _dta[network_ref]
	local trts:char _dta[network_trtlistnoref]
	local tt1:char _dta[network_t1]
	local tt2:char _dta[network_t2]	
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
	if "`edgeweight'"!=""{
		cap{
			assert `edgeweight'<0
		}
		if _rc==0{
			di as error "Negative weights not allowed"
			exit
		}
	}
	
	if "`nodecolor'"!= ""{
		local nc "`nodecolor'"
	}
	else{
		local nc "blue"
	}
	if `"`plotregion'"'!=""{
		local plotreg `"`plotregion'"'
	}
	else{
		local plotreg "margin(15 15 10 10)"
	}
	tempname asp
	if "`aspect'"!=""{
		scalar `asp'=real("`aspect'")
	}
	else{
		scalar `asp'=1
	}
	if "`edgecolor'"!= ""{
		tokenize `edgecolor'
		if "`1'"!="by"{
			local ec "`edgecolor'"
			local rob ""
		}
		else{
			if "`2'"==""{
				di as err "Variable with study risk of bias levels not specified"
				exit
			}
			else{		
				local rob "rob"
			}
		}
	}
	else{
		local ec "black"
	}	
	if "`edgepattern'"!= ""{
		local ep "`edgepattern'"
	}
	else{
		local ep "solid"
	}	
	tempvar _tnew1 _tnew2 told1 told2
	cap encode `tt1',gen(`told1') lab(_ttrt)
	cap	encode `tt2',gen(`told2') lab(_ttrt)
	cap	gen `_tnew1'=min(`told1',`told2')
	cap	gen `_tnew2'=max(`told1',`told2')
	cap	lab val `_tnew1' _ttrt
	cap	lab val `_tnew2' _ttrt	

* IRW alternative code to buld correct label _treat 
* - needed to make encode work correctly
* - might be able to simplify other code uising this idea

	/*cap lab drop _treat
    qui levelsof `_t1new', local(t1levels)
    qui levelsof `_t2new', local(t2levels)
    local alltreats : list t1levels | t2levels
    local alltreats : list sort alltreats
    local i 0
    foreach trt in `alltreats' {
        local ++i
        label def _treat `i' "`trt'", add
    }
	cap encode `_t2new' if `_use'==1,gen(`_tnew22') lab(_treat)
	cap encode `_t1new' if `_use'==1,gen(`_tnew11') lab(_treat)*/

* IRW end
	qui{
		if "`wperstudies'"!="" & "`nodeweight'"== ""{
			forvalues i=1/`ntm'{
				tempvar _treat`i' _str`i'
				gen `_treat`i''=1 if `_tnew1'==`i' | `_tnew2'==`i'
				egen `_str`i''=sum(`_treat`i'')
			}
		}
		if "`nodeweight'"!=""{
			tokenize "`nodeweight'"
			if "`1'"=="arm"{
				local _nwvar1 `2'
				local _nwvar2 `3'
				cap{
					assert `_nwvar1'<0 | `_nwvar2'<0
				}
				if _rc==0{
					di as error "Negative weights not allowed"
					exit
				}				
				local _nwfun `4'
			}
			else if "`1'"=="study"{
				local _nwvar1 `2'
				cap{
					assert `_nwvar1'<0
				}
				if _rc==0{
					di as error "Negative weights not allowed"
					exit
				}				
				local _nwvar2 ""
				local _nwfun `3'				
			}
			else{
				di as err "Option {it:nodeweight()} requires as input arm|study for arm-level or study-level characteristics respectively"
				exit
			}
			if "`_nwfun'"=="" | "`_nwfun'"=="sum"{
				forvalues i=1/`ntm'{
					tempvar _treat`i' _str`i'
					gen `_treat`i''=`_nwvar1' if `_tnew1'==`i'
					if "`_nwvar2'"!=""{
						replace `_treat`i''=`_nwvar2' if  `_tnew2'==`i'
					}
					else{
						replace `_treat`i''=`_nwvar1' if  `_tnew2'==`i'
					}
					replace `_treat`i''=0 if `_treat`i''==. & (`_tnew1'==`i' | `_tnew2'==`i')
					egen `_str`i''=sum(`_treat`i'')
				}
			}
			else if "`_nwfun'"=="mean"{
				forvalues i=1/`ntm'{
					tempvar _treat`i' _str`i'
					gen `_treat`i''=`_nwvar1' if `_tnew1'==`i'
					if "`_nwvar2'"!=""{
						replace `_treat`i''=`_nwvar2' if  `_tnew2'==`i'
					}
					else{
						replace `_treat`i''=`_nwvar1' if  `_tnew2'==`i'
					}
					replace `_treat`i''=0 if `_treat`i''==. & (`_tnew1'==`i' | `_tnew2'==`i')
					egen `_str`i''=mean(`_treat`i'')
				}	
			}
			else {
				di as err "Function {it:`_nwfun'} in option {it:nodeweight()} not allowed"
				exit
			}
		}		
		tempname _nscalenew _nscale
		if "`nodescale'"!=""{
			scalar `_nscalenew'=real("`nodescale'")
		}
		else{
			scalar `_nscalenew'=1
		}		
		if "`wperstudies'"!="" | "`nodeweight'"!= ""{
			scalar `_nscale'=1
			forvalues i=1/`ntm'{	
				tempname _weight`i' _nscale`i'
				scalar `_weight`i''=`_str`i''
				if `_weight`i''>20{
					scalar `_nscale`i''=`_weight`i''/15
					scalar `_nscale'=max(`_nscale',`_nscale`i'')
				}
			}
			forvalues i=1/`ntm'{
				scalar `_weight`i''=`_weight`i''/`_nscale'
				scalar `_weight`i''=`_weight`i''*`_nscalenew'
			}
		}
		else{
			forvalues i=1/`ntm'{
				tempname _weight`i'
				scalar `_weight`i''=5		
				scalar `_weight`i''=`_weight`i''*`_nscalenew'
			}
		}
		if "`rob'"!=""{
			tempvar _robnew
			tokenize `edgecolor'
			local _rob `2'
			local _robmeth "`3'"
			cap {
				assert int(`_rob')==`_rob'
			}
			if _rc!=0{
				if "`bylevels'"!=""{
					di as err "Non-numeric {it:groupvar} in option {it:edgecolor()} may not be combined with option {it:bylevels()}"
					exit
				}
				else{
					gen `_robnew'=3 if `_rob'=="H" | `_rob'=="h" | `_rob'=="high" | `_rob'=="HIGH" | `_rob'=="High"
					replace `_robnew'=1 if `_rob'=="L" | `_rob'=="l" | `_rob'=="low" | `_rob'=="LOW" | `_rob'=="Low"
					replace `_robnew'=2 if `_rob'=="U" | `_rob'=="u" | `_rob'=="unclear" | `_rob'=="UNCLEAR" | `_rob'=="Unclear"
					replace `_robnew'=. if `_rob'!="H" & `_rob'!="h" & `_rob'!="high" & `_rob'!="HIGH" & `_rob'!="High" & `_rob'!="L" & `_rob'!="l" & `_rob'!="low" & `_rob'!="LOW" & `_rob'!="Low" & `_rob'!="U" & `_rob'=="u" & `_rob'!="unclear" & `_rob'!="UNCLEAR" & `_rob'!="Unclear"
				}
			}
			else {
				qui gen `_robnew'=`_rob'
				if "`bylevels'"==""{
					replace `_robnew'=. if `_rob'>3 | `_rob'<1
				}
			}		
			if "`_robmeth'"==""{
				local _robmeth "mode"
			}
			if "`_robmeth'"=="mode"{
				tempvar _nrob
				by `_tnew1' `_tnew2' `_robnew',sort:gen `_nrob'=_N
				forvalues i=1/`ntm'{
					forvalues j=`=`i'+1'/`ntm'{
						tempvar _mrob`i'_`j' _smrob`i'_`j' _pmrob`i'_`j'
						egen `_mrob`i'_`j''=max(`_nrob') if `_tnew1'==`i' & `_tnew2'==`j'
						gen `_pmrob`i'_`j''=`_robnew' if `_mrob`i'_`j''==`_nrob'
						egen `_smrob`i'_`j''=max(`_pmrob`i'_`j'')
			
					}
				}
			}
			if "`_robmeth'"=="max"{
				forvalues i=1/`ntm'{
					forvalues j=`=`i'+1'/`ntm'{
						tempvar _maxrob`i'_`j' _smrob`i'_`j'
						egen `_maxrob`i'_`j''=max(`_robnew') if `_robnew'!=. & `_tnew1'==`i' & `_tnew2'==`j'
						egen `_smrob`i'_`j''=max(`_maxrob`i'_`j'')
					}
				}
			}			
			if "`_robmeth'"=="min"{
				forvalues i=1/`ntm'{
					forvalues j=`=`i'+1'/`ntm'{
						tempvar _minrob`i'_`j' _smrob`i'_`j'
						egen `_minrob`i'_`j''=min(`_robnew') if `_robnew'!=. & `_tnew1'==`i' & `_tnew2'==`j'
						egen `_smrob`i'_`j''=max(`_minrob`i'_`j'')
					}
				}
			}			
			if "`_robmeth'"=="mean"{
				forvalues i=1/`ntm'{
					forvalues j=`=`i'+1'/`ntm'{
						tempvar _meanrob`i'_`j' _smrob`i'_`j'
						egen `_meanrob`i'_`j''=mean(`_robnew') if `_robnew'!=. & `_tnew1'==`i' & `_tnew2'==`j'
						replace `_meanrob`i'_`j''=round(`_meanrob`i'_`j'',1)
						egen `_smrob`i'_`j''=max(`_meanrob`i'_`j'')
					}
				}
			}	
			if "`_robmeth'"=="wmean"{
				cap{
					assert "`4'"!=""
				}
				if _rc!=0{
					di as err "Weighting variable for risk of bias assessment not specified in option {it:edgecolor}"
					exit
				}
				else{
					local _weight `4'				
					forvalues i=1/`ntm'{
						forvalues j=`=`i'+1'/`ntm'{
							tempvar _mulrob`i'_`j' _sumw`i'_`j' _wmeanrob`i'_`j' _smrob`i'_`j'
							egen `_mulrob`i'_`j''=sum(`_robnew'*`_weight') if `_robnew'!=. & `_tnew1'==`i' & `_tnew2'==`j'
							egen `_sumw`i'_`j''=sum(`_weight') if `_robnew'!=. & `_tnew1'==`i' & `_tnew2'==`j'
							gen `_wmeanrob`i'_`j''=`_mulrob`i'_`j''/`_sumw`i'_`j''
							replace `_wmeanrob`i'_`j''=round(`_wmeanrob`i'_`j'',1)
							egen `_smrob`i'_`j''=max(`_wmeanrob`i'_`j'')
						}
					}
				}
			}
			tempname _bylev
			if "`bylevels'"!=""{
				scalar `_bylev'=real("`bylevels'")
				tokenize `"`bycolors'"'
				forvalues z=1/`=`_bylev''{
					tempname _bycol`z'
					scalar `_bycol`z''="``z''"
					if "``z''"==""{
						scalar `_bycol`z''="black"
					}
				}
				forvalues i=1/`ntm'{
					forvalues j=`=`i'+1'/`ntm'{
						tempname _ecol`i'_`j'
						scalar `_ecol`i'_`j''=""
						forvalues z=1/`=`_bylev''{
							if `_smrob`i'_`j''==`z'{
								scalar `_ecol`i'_`j''="`=`_bycol`z'''"
							}
						}
					}
				}
			}
			else{
				forvalues i=1/`ntm'{
					forvalues j=`=`i'+1'/`ntm'{
						tempname _ecol`i'_`j'
						scalar `_ecol`i'_`j''=""
						if `_smrob`i'_`j''==1{
							scalar `_ecol`i'_`j''="green"
						}
						if `_smrob`i'_`j''==2{
							scalar `_ecol`i'_`j''="gold"
						}
						if `_smrob`i'_`j''==3{
							scalar `_ecol`i'_`j''="cranberry"
						}
						if `_ecol`i'_`j''==""{
							scalar `_ecol`i'_`j''="black"
						}
					}
				}	
			}	
		}
		sort `_tnew1' `_tnew2'
		forvalues i=1/`ntm'{
			forvalues j=`=`i'+1'/`ntm'{
				tempname _T`i'_`j'
				cap mkmat `_tnew1' `_tnew2' if `_tnew1'==`i' & `_tnew2'==`j',mat(`_T`i'_`j'')
			}
		}		
		if "`wperstudies'"!="" & "`edgeweight'"==""{
			forvalues i=1/`ntm'{
				forvalues j=`=`i'+1'/`ntm'{
					tempvar _com`i'_`j' _scom`i'_`j'
					gen `_com`i'_`j''=1 if `_tnew1'==`i' & `_tnew2'==`j'
					egen `_scom`i'_`j''=sum(`_com`i'_`j'')
				}
			}
		}	
		if "`edgeweight'"!=""{
			tokenize "`edgeweight'"
			local _ewvar `1'
			local _ewfun `2'
			if "`_ewfun'"=="" | "`_ewfun'"=="sum"{
				forvalues i=1/`ntm'{
					forvalues j=`=`i'+1'/`ntm'{
						tempvar _com`i'_`j' _scom`i'_`j'
						gen `_com`i'_`j''=`_ewvar' if `_tnew1'==`i' & `_tnew2'==`j'
						replace `_com`i'_`j''=0 if `_com`i'_`j''==. & `_tnew1'==`i' & `_tnew2'==`j'
						egen `_scom`i'_`j''=sum(`_com`i'_`j'')
					}
				}
			}
			else if "`_ewfun'"=="mean"{
				forvalues i=1/`ntm'{
					forvalues j=`=`i'+1'/`ntm'{
						tempvar _com`i'_`j' _scom`i'_`j'
						gen `_com`i'_`j''=`_ewvar' if `_tnew1'==`i' & `_tnew2'==`j'
						replace `_com`i'_`j''=0 if `_com`i'_`j''==. & `_tnew1'==`i' & `_tnew2'==`j'
						egen `_scom`i'_`j''=mean(`_com`i'_`j'')
					}
				}	
			}
			else {
				di as err "Function {it:`ewfun'} in option {it:edgeweight()} not allowed"
				exit
			}
		}
		tempname _escalenew _escale
		if "`edgescale'"!=""{
			scalar `_escalenew'=real("`edgescale'")
		}
		else{
			scalar `_escalenew'=1
		}
		if "`wperstudies'"!="" | "`edgeweight'"!=""{
			scalar `_escale'=1
			forvalues i=1/`ntm'{
				forvalues j=`=`i'+1'/`ntm'{	
					tempname _weight`i'_`j'
					scalar `_weight`i'_`j''=`_scom`i'_`j''
					if `_weight`i'_`j''>3{
						scalar _escale`i'_`j'=`_weight`i'_`j''/3
						scalar `_escale'=max(`_escale',_escale`i'_`j')
					}
				}
			}
			forvalues i=1/`ntm'{
				forvalues j=`=`i'+1'/`ntm'{
					scalar `_weight`i'_`j''=`_weight`i'_`j''/`_escale'
					scalar `_weight`i'_`j''=`_weight`i'_`j''*`_escalenew'
				}
			}
		}
		else{
			forvalues i=1/`ntm'{
				forvalues j=`=`i'+1'/`ntm'{
					tempname _weight`i'_`j'
					scalar `_weight`i'_`j''=0.3
					scalar `_weight`i'_`j''=`_weight`i'_`j''*`_escalenew'
				}
			}
		}	
		forvalues i=1/`ntm'{
			tempname _y`i' _x`i' _pos`i'
		}
		tempname _ang

* IRW edited: Choose locations for nodes
        local create 1 // Create locations
        if !missing("`location'") {
            cap confirm matrix `location'
            if !_rc local create 0 // Don't create locations
        }
   		else local location _networkplot_location // Default saving location
        if `create' { // IRW: make new location if location either not specified or specified with replace suboption
            scalar `_y1'=0
    		scalar `_x1'=1
    		scalar `_ang'=_pi/(`ntm'/2)
    		scalar `_y2'=sin(`_ang')
    		scalar `_x2'=cos(`_ang')
    		forvalues i=3/`ntm'{
    			scalar `_y`i''=sin((`=`i'-1')*`_ang')
    			scalar `_x`i''=cos((`=`i'-1')*`_ang')
    		}
    		scalar `_pos1'=3
    		forvalues i=2/`ntm'{
    			if `_y`i''>0 & `_x`i''>0 {
    				scalar `_pos`i''=2
    			}
    			if `_y`i''>0 & `_x`i''<0{
    				scalar `_pos`i''=11
    			}			
    			if `_y`i''<0 & `_x`i''<0{
    				scalar `_pos`i''=8
    			}			
    			if `_y`i''<0 & `_x`i''>0{
    				scalar `_pos`i''=5
    			}	
    			if `_y`i''==1 & `_x`i''==0{
    				scalar `_pos`i''=12
    			}	
    			if `_y`i''==0 & `_x`i''==-1{
    				scalar `_pos`i''=9
    			}	
    			if `_y`i''==-1 & `_x`i''==0{
    				scalar `_pos`i''=6
    			}	
            }
            // IRW: next 7 lines store locations in matrix
            matrix `location' = J(`ntm',3,.)
    		forvalues i=1/`ntm'{
           		mat `location'[`i',1]=chop(`_x`i'',1E-8)
        		mat `location'[`i',2]=chop(`_y`i'',1E-8)
        		mat `location'[`i',3]=`_pos`i''
                mat colnames `location' = "x" "y" "labpos"
            }
        }
        else { // IRW: next 5 lines read locations from matrix
    		forvalues i=1/`ntm'{
                scalar `_x`i'' = `location'[`i',1]
                scalar `_y`i'' = `location'[`i',2]
                scalar `_pos`i'' = `location'[`i',3]
            }
        }	
* IRW: end of choosing locations for nodes
   		local _node1 `"||scatteri `=`_y1'' `=`_x1'' "`lab1'""'
		forvalues i=2/`ntm'{
			local _node`i' `"`_node`=`i'-1'',mlabpos(`=`_pos`=`i'-1''') mcolor(`nc') mlabcolor(black) mlabsize(`labsize') msize(`=`_weight`=`i'-1''')||scatteri `=`_y`i''' `=`_x`i''' "`lab`i''""'
		}
		if "`rob'"==""{
			forvalues i=1/`ntm'{
				forvalues j=`=`i'+1'/`ntm'{	
					cap{
						assert colsof(`_T`i'_`j'')==2
					}
					if _rc==0{
						local _comp`i'_`j' `"pci `=`_y`i''' `=`_x`i''' `=`_y`j''' `=`_x`j''', lcolor(`ec') lpattern(`ep') lwidth(`=`_weight`i'_`j''')||"'
					}
				}
			}
		}
		else{
			forvalues i=1/`ntm'{
				forvalues j=`=`i'+1'/`ntm'{	
					cap{
						assert colsof(`_T`i'_`j'')==2
					}
					if _rc==0{
						local _comp`i'_`j' `"pci `=`_y`i''' `=`_x`i''' `=`_y`j''' `=`_x`j''', lcolor(`=`_ecol`i'_`j''') lpattern(`ep') lwidth(`=`_weight`i'_`j''')||"'
					}
				}
			}
		}
		forvalues i=1/`ntm'{
			local _comp`i'`=`i'+1' `"`_comp`i'_`=`i'+1''"'
			forvalues j=`=`i'+2'/`ntm'{
				local _comp`i'`j' `"`_comp`i'`=`j'-1''|| `_comp`i'_`j''"'
			}
		}
		forvalues i=2/`ntm'{
			local _comp`i'`ntm' `"`_comp`=`i'-1'`ntm''||`_comp`i'`ntm''"'
		}
	}
        * IRW next change is needed to enable f9 option 
        local command twoway `_comp`ntm'`ntm'' ||`_node`ntm'', mcolor(`nc') mlabcolor(black) mlabsize(`labsize') aspect(`=`asp'') legend(off) xscale(off) yscale(off) msize(`=`_weight`ntm''') mlabpos(`=`_pos`ntm''') ylabels(, nogrid) plotregion(`plotreg') `twowayoptions'
        `command'

    if !mi("`f9'") { // IRW
        global F9 `command'
        di as text "Graph command stored in F9"
    }
	
end

