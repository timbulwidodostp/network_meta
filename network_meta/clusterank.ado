*! version 2.0.1, 24.05.2019
//version 2.0.0, 09.01.2018
//version 1.2, 26.02.2015, Anna Chaimani

program clusterank
	syntax varlist (min=2 max=3) [if] [in], [BEST(string) METHod(string) CLusters(string) SCATteroptions(string) DENdrogram]
	
	preserve
	
	if "`if'"!= ""{
		qui keep `if'
	}
	if "`in'"!= ""{
		qui keep `in'
	}
	tempname _nallobs
	scalar `_nallobs'=_N
	
	tokenize `varlist'
	local y1 `1'
	local y2 `2'
	local t `3'
	
	qui keep if `1'!=. & `2'!=.
	
	if "`3'"==""{
		tempvar t
		gen `t'=_n
	}
	
	cap set matsize 800
	cap set matsize 11000
	if "`method'"!=""{
		tokenize `method'
		local linkage `1'
		local measure `2'
	}
	else{
		foreach link in singlelinkage averagelinkage completelinkage waveragelinkage medianlinkage centroidlinkage wardslinkage {
			foreach meas in  Euclidean L2squared L1 Linf Canberra  {
				qui cluster `link' `y1' `y2', measure(`meas')
				mat dis _A`link'_`meas'=`y1' `y2',`meas'
				sort  _clus_1_hgt
				cap cluster gen _gr=groups(1/`=`=_N'-1')
				mat _D`link'_`meas'=J(`=_N',`=_N',0)		
				
	/*cophenetic matrix*/
				
				forvalues i=1/`=_N'{
					cap{
						by _gr`=_N-`i'',sort:gen _cl`i'= _clus_1_id if _N>1
					}
				}
				sort  _clus_1_hgt
				forvalues i=1/`=_N-1'{
					tempname `link'_`meas'_`i'
					scalar ``link'_`meas'_`i''=_clus_1_hgt in `i'
				}
				qui cluster drop _all
				forvalues i=1/`=_N-1'{
					tempname _C`link'_`meas'_`i'
					mat `_C`link'_`meas'_`i''=0
					cap mkmat _cl`i' _gr`=_N-`i'' if _cl`i'!=.,mat(`_C`link'_`meas'_`i'')
				}
				cap drop _cl* _gr*
			}
		}	
		foreach link in singlelinkage averagelinkage completelinkage waveragelinkage medianlinkage centroidlinkage wardslinkage {
			foreach meas in  Euclidean L2squared L1 Linf Canberra  {	
				forvalues i=1/`=_N-1'{
					forvalues j=1/`=_N'{
						forvalues k=1/`=_N'{
							if `_C`link'_`meas'_`i''[`j',1]!=`k' continue
							forvalues z=1/`=_N'{
								if `_C`link'_`meas'_`i''[`j',2]!=`_C`link'_`meas'_`i''[`z',2] continue
								forvalues l=1/`=_N'{
									if  (`l'==`k' | _D`link'_`meas'[`l',`k']!=0 | `_C`link'_`meas'_`i''[`z',1]!=`l') continue
									mat _D`link'_`meas'[`l',`k']=`i'
									mat _D`link'_`meas'[`k',`l']=`i'
								}
							}
						}
					}
				}
			}
		}
		foreach link in singlelinkage averagelinkage completelinkage waveragelinkage medianlinkage centroidlinkage wardslinkage {
			foreach meas in  Euclidean L2squared L1 Linf Canberra  {
				forvalues i=1/`=_N-1'{
					forvalues j=1/`=_N'{
						forvalues k=1/`=_N'{
							if _D`link'_`meas'[`j',`k']!=`i' continue
							mat _D`link'_`meas'[`j',`k']=``link'_`meas'_`i''
							mat _D`link'_`meas'[`k',`j']=``link'_`meas'_`i''
						}
					}
				}
			}
		}
		foreach link in singlelinkage averagelinkage completelinkage waveragelinkage medianlinkage centroidlinkage wardslinkage {
			foreach meas in  Euclidean L2squared L1 Linf Canberra  {		
				forvalues j=1/`=_N'{
					forvalues k=`j'/`=_N'{
						mat _A`link'_`meas'[`j',`k']=.
						mat _D`link'_`meas'[`j',`k']=.
					}
					mat _B`link'_`meas'=vec(_A`link'_`meas')
					mat _E`link'_`meas'=vec(_D`link'_`meas')
				}
			}
		}
		foreach link in singlelinkage averagelinkage completelinkage waveragelinkage medianlinkage centroidlinkage wardslinkage {
			foreach meas in  Euclidean L2squared L1 Linf Canberra  {		
				cap mat drop _A`link'_`meas'
				cap mat drop _D`link'_`meas'
			}
		}
		tempname _best nobs
		scalar `_best'=0
		scalar `nobs'=`=`=_N'^2'
		qui set obs `=`nobs''
		foreach link in singlelinkage averagelinkage completelinkage waveragelinkage medianlinkage centroidlinkage wardslinkage {
			foreach meas in  Euclidean L2squared L1 Linf Canberra  {			
				
				/*cophenetic correlation coefficient*/
				
				foreach mat in B E{
					qui svmat _`mat'`link'_`meas'
					cap mat drop _`mat'`link'_`meas'
					qui egen _m`mat'`link'_`meas'=mean(_`mat'`link'_`meas'1)
					qui gen _`mat'`link'_`meas'2=_`mat'`link'_`meas'1-_m`mat'`link'_`meas'
					qui gen _`mat'`link'_`meas'22=(_`mat'`link'_`meas'1-_m`mat'`link'_`meas')^2
					qui egen _s`mat'`link'_`meas'=sum(_`mat'`link'_`meas'22)
				}
				qui gen _BE`link'_`meas'=_E`link'_`meas'2*_B`link'_`meas'2
				qui egen _nom`link'_`meas'=sum(_BE`link'_`meas')
				qui gen _denom`link'_`meas'=sqrt(_sB`link'_`meas'*_sE`link'_`meas')
				qui gen _cophc`link'_`meas'=_nom`link'_`meas'/_denom`link'_`meas'
				tempname c_`link'_`meas'
				scalar `c_`link'_`meas''=_cophc`link'_`meas'
				scalar `_best'=max(`_best',`c_`link'_`meas'')
				if `_best'!=`c_`link'_`meas'' continue
				local linkage "`link'"
				local measure "`meas'"
			}
		}
		di as res _newline " Best linkage method: {it:`linkage'}"
		di as res " Best distance metric: {it:`measure'}"
		di as res _newline " Cophenetic Correlation Coefficient c = `=string(round(`=`_best'',0.01),"%9.2f")'"
	}
	tempname nclus
	if "`clusters'"!=""{
		scalar `nclus'=int(real("`clusters'"))
		qui cluster `linkage' `y1' `y2',measure(`measure')
		qui cluster gen _gr=groups(`=`nclus'')
	}
	else{
	
		/*clustering gain*/
		
		qui{
			egen _po_1=mean(`y1')
			egen _po_2=mean(`y2')
			mkmat _po_1 _po_2 in 1,mat(_po)
			
			cluster `linkage' `y1' `y2',measure(`measure')
			cluster gen _gr=groups(1/`=`=`_nallobs''-1')
			forvalues i=1/`=`=`_nallobs''-1'{
				by _gr`i',sort:egen _po_1_`i'=mean(`y1')
				by _gr`i',sort:replace _po_1_`i'=. if _n>1
				by _gr`i',sort:egen _po_2_`i'=mean(`y2')
				by _gr`i',sort:replace _po_2_`i'=. if _n>1
				mkmat _po_1_`i' _po_2_`i',nomissing mat(_po_`i')

			}
			forvalues i=1/`=`=`_nallobs''-1'{
				by _gr`i',sort:gen _nn`i'=_N
				by _gr`i',sort:replace _nn`i'=. if _n>1
				mkmat _nn`i',nomissing mat(_NN`i')
			}
			forvalues i=1/`=`=`_nallobs''-1'{
				mat _dist`i'=J(`i',1,0)
				mat _gain`i'=J(`i',1,0)
				forvalues j=1/`i'{
					mat _dist`i'[`j',1]=(_po_`i'[`j',1]-_po[1,1])^2+(_po_`i'[`j',2]-_po[1,2])^2
					mat _gain`i'[`j',1]=(_NN`i'[`j',1]-1)*_dist`i'[`j',1]
				}
				svmat _gain`i'
				egen _sgain`i'=sum(_gain`i')
			}
			tempname _maxgain
			scalar `_maxgain'=_sgain1
			forvalues i=2/`=`=`_nallobs''-1'{
				scalar `_maxgain'=max(`_maxgain',_sgain`i')
			}
		}
		forvalues i=1/`=`=`_nallobs''-1'{
			cap{
				assert `_maxgain'==_sgain`i'
			}
			if _rc==0{
				qui keep _gr`i' _clus_1* `t' `y1' `y2'
				scalar `nclus'=`i'
				di as res _newline " ** Maximum value of clustering gain = `=string(round(`=`_maxgain'',0.01),"%9.2f")'"
				di as res " ** Optimal number of clusters =  `i'"
			}
		}
		qui drop if _n>`=`_nallobs''
	}
	if "`dendrogram'"!=""{
		cluster rename _clus_1 hierarchical
		cluster dendrogram hierarchical,lab(`t')
	}
	else{
		if "`best'"=="" | "`best'"=="max"{
			local yscale ""
			local xscale ""
			local ylabel ""
		}
		else if "`best'"=="min"{
			local ylabel ""
			local yscale "reverse"
			local xscale "reverse"	 
		}
		else{
			di as err "Option {it:`best'} in option {it:best} not allowed"
			exit
		}
		
		local _scat1 `"sc `y2' `y1' if _gr==1"'
		forvalues i=2/`=`nclus''{
			local _scat`i' `" `_scat`=`i'-1'',mlab(`t') `scatteroptions' || sc `y2' `y1' if _gr==`i'"'
		}
		cap{
			twoway `_scat`=`nclus''',`scatteroptions' yscale(`yscale') xscale(`xscale') legend(off) mlab(`t')
		}
		if _rc!=0{
			di as err "Option {it:`scatteroptions'} in option {it:scatteroptions} not allowed"
			exit
		}		
	}
end
