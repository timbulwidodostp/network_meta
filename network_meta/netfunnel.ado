*! version 2.0.1, 24.05.2019
//version 2.0.0, 09.01.2018
//version 1.2, 26.02.2015, Anna Chaimani

program netfunnel
	syntax varlist(min=4 max=4) [if] [in] , [FIXED RANDOM XTITle(string asis) BYCOMParison ///
	YTITle(string asis) ADDplot(string) YLABel(string) XLABel(string) SCATteroptions(string asis) ///
	NOCI ORDer(string asis)]
	
	preserve
	
	local form:char _dta[network_format]
	if "`form'"!="pairs"{
		di as err "Data not in pairs format, see {helpb network setup} or {helpb network import} for details"
		exit
	}	
	
	tempvar estnew rankstart use index
	qui gen `rankstart'=_n
	
	qui gen `use'=1 `if' `in'
	qui egen `index'=sum(`use')
	if `index'==0{
		di as err "No studies to plot"
		exit
	}	
	
	tokenize `varlist'
	local est `1'
	local se `2'

	if "`random'"!=""{
		local pe "randomi"
	}
	else{
		local pe "fixedi"	
	}	
	if `"`xtitle'"'!=""{
		local xtitle `"`xtitle'"'
	}
	else{
		local xtitle "Effect size centred at comparison-specific pooled effect ({it:y{sub:iXY}-{&mu}{sub:XY}})"
	}
	if `"`ytitle'"'!=""{
		local ytitle `"`ytitle'"'
	}
	else{
		local ytitle "Standard error of effect size"
	}		
	if `"`scattertoptions'"'!=""{
		local scattertoptions `"`scattertoptions'"'
	}
	else{
		local scattertoptions ""
	}	
	local ttt1:char _dta[network_t1]
	local ttt2:char _dta[network_t2]
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
	lab def _trt 1 "`tr1'"
	forvalues i=2/`ntm'{
		lab def _trt `i' "`tr`i''",add
	}	
	if `"`order'"' != ""{
		tokenize `"`order'"'
		forvalues i=1/`ntm'{
			if "``i''"!=""{
				local s`i' "``i''"
			}
		}
		forvalues i=1/`ntm'{
			forvalues j=1/`ntm'{
				if "`tr`i''"=="`s`j''"{
					local ord`i'=`j'
				}
			}
		}	
	}	
	else{
		forvalues i=1/`ntm'{
			local ord`i'=`i'
		}
	}	
	tempvar tnew1 tnew2 tt1 tt2 told1 told2
	qui encode `ttt1',gen(`told1') lab(_trt)
	qui encode `ttt2',gen(`told2') lab(_trt)
	qui gen `tnew1'=min(`told1',`told2')
	qui gen `tnew2'=max(`told1',`told2')
	lab val `tnew1' _trt
	lab val `tnew2' _trt
	qui replace `est'=-`est' if `tnew1'==`told1'	

	qui gen `tt1'=.
	qui gen `tt2'=.
	forvalues i=1/`ntm'{
		forvalues j=1/`ntm'{	
			qui replace `tt1'=`tnew1' if `tnew1'==`i' &	`tnew2'==`j' & `ord`i''<`ord`j''
			qui replace `tt2'=`tnew2' if `tnew1'==`i' &	`tnew2'==`j' & `ord`i''<`ord`j''
			qui replace `tt1'=`tnew2' if `tnew1'==`i' &	`tnew2'==`j' & `ord`i''>`ord`j''
			qui replace `tt2'=`tnew1' if `tnew1'==`i' &	`tnew2'==`j' & `ord`i''>`ord`j''
		}
	}
	lab val `tt1' _trt
	lab val `tt2' _trt
	qui gen `estnew'=.
	qui replace `estnew'=`est' if `tt1'==`tnew1'
	qui replace `estnew'=-`est' if `tt1'==`tnew2'
	tempvar c nsc
	qui{
		egen `c'=concat(`ttt1' `ttt2'),punct(_)
		cap drop _dc*
		tab `c' if `use'==1,gen(_dc)
		tempname DC
		mkmat _dc*,matrix(`DC')
		local nc=colsof(`DC')
		sort `ttt1' `ttt2',stable
		by `ttt1' `ttt2' `use',sort:gen `nsc'=_N if `use'==1
		
		forvalues j=1/`nc' {
			tempvar sdc`j'
			egen `sdc`j''=sum(_dc`j')
			replace `use'=. if `sdc`j''<2 & _dc`j'==1
		}
	
		forvalues j=1/`nc' {
			tempvar _pooled`j'
			cap metan `estnew' `se' if _dc`j'==1 & `use'==1, `pe' nograph notable nokeep
			gen `_pooled`j''=r(ES) if _dc`j'==1 & `use'==1
		}
		tempvar est_cen
		gen `est_cen'=.
		forvalues j=1/`nc' {
			replace `est_cen'=`estnew'-`_pooled`j'' if _dc`j'==1 & `use'==1
		}
		if "`bycomparison'"!=""{
			local _scat1 `"sc `se' `est_cen' if _dc1==1 & `use'==1"'
			forvalues j=2/`nc' {
				local _scat`j' `"`_scat`=`j'-1'' ||sc `se' `est_cen'  if _dc`j'==1 & `use'==1"'
			}
		}
		else{
			local _scat`nc' `"sc `se' `est_cen'"'
		}
	}
	tempvar _comp _labs
	qui{
		sort `tnew1' `tnew2'
		egen `_comp'=concat(`tt1' `tt2') if `use'==1,punct(" - ") decode
	}
	forvalues j=1/`nc'{
		local ssdc`j'=`sdc`j''
	}
	if "`bycomparison'"!=""{
		forvalues j=1/`nc'{
			if `ssdc`j''>1{
				gsort  -_dc`j'
				tempname leg`j'
				scalar `leg`j''=`_comp' in 1
			}
		}
		if `ssdc1'>1{
			local lableg1 `" 1 "`=`leg1''""'
		}
		else{
			local lableg1 `" "'
		}
		forvalues j=2/`nc' {
			if `ssdc`j''>1{
				local lableg`j' `"`lableg`=`j'-1'' `j' "`=`leg`j'''" "'
			}
			else{
				local lableg`j' `"`lableg`=`j'-1'' "'
			}			
		}
		local legend "order(`lableg`nc'') col(6)"
	}
	else{
		local legend "off"
	}
	tempvar _ymax
	qui egen `_ymax'=max(`se')
	tempname ymax xmax xmin
	scalar `ymax'=`_ymax'
	scalar `ymax'=round(`ymax',0.1)
	scalar `xmax'=`ymax'*1.96
	scalar `xmin'=-`xmax'	
	if "`ylabel'"!=""{
		local ylabel "`ylabel'"
	}
	else{
		local ylabel "0(0.5)`=`ymax''"
	}	
	if "`xlabel'"!=""{
		local xlabel "`xlabel'"
	}
	else{
		local xlabel ""
	}
	if "`noci'"==""{
		local _lines `"function y=abs(x/1.96),range(`=`xmin'' `=`xmax'') legend(`legend') lcol(black) lpat(dash)"'
	}
	else{
		local _lines ""
	}
	cap{
		twoway `_scat`nc'' , yscale(rev) mc(black) xtitle(`xtitle') ytitle(`ytitle') xline(0, lcol(red)) ylab(`ylabel') xlab(`xlabel') `scatteroptions'|| `_lines' || `addplot', caption(Note: Comparisons including only one study have been excluded, justification(left) size(vsmall) margin(medium))
	}
	if _rc!=0{
		di as err "Plot(s) in {it:addplot()} option wrongly specified"
		exit _rc
	}  
	qui drop _dc*
	qui{
		by `_comp',sort:gen `_labs'=`_comp' if _n==1
		gsort -`_labs'
	}
	di as res _newline "Comparisons in the plot*:" _newline
	li `_labs' if `_labs'!="" , separator(0) noheader clean
	di as res _newline "* Note: Comparisons including only one study have been excluded from the graph"
	qui sort `rankstart'
	tempname EC
	qui mkmat `est_cen',mat(`EC')
	restore
	cap drop _ES_CEN
	qui svmat `EC',names(_ES_CEN)
	cap rename _ES_CEN1 _ES_CEN
	cap lab drop _trt
	
end
