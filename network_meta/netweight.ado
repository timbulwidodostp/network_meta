*! version 2.0.1, 24.05.2019
//version 2.0.0, 25.10.2017
//version 1.2.1, 08.08.2016, Anna Chaimani

program netweight,eclass
	syntax varlist(min=4 max=4) [if] [in] , [FIXED RANDOM TAU2(string) ///
	BARgraph(string) ORDER BYLEVels(string) BYCOLors(string asis) NOPLot ///
	NOTABle SCale(string) NOVALues ASPect(string) COLor(string)  ///
	SYMBol(string) NOSTudies TITle(string asis) NOYmatrix NOVmatrix ///
	NOXmatrix NOHmatrix DECimals(string) EXPort(string asis) REFerence(string) ///
	TREATEXclude(string) BAROPTions(string asis) TEXTsize(string) THREShold(string)]	
	
	preserve
	
	if "`if'"!= ""{
		qui keep `if'
	}
	if "`in'"!= ""{
		qui keep `in'
	}
	
	if "`bylevels'"!="" & "`bycolors'"==""{
		di as err "Option {it:bylevels} requires option {it:bycolors}"
		exit
	}
	if "`bylevels'"=="" & "`bycolors'"!=""{
		di as err "Option {it:bycolors} requires option {it:bylevels}"
		exit
	}	
	if "`textsize'"!=""{
		local textsize `textsize'
	}
	if "`textsize'"==""{
		local textsize "vsmall"
	}
	if "`bargraph'"!=""{
		tokenize `bargraph'
		if "`1'"!="by"{
			di as err "Option {it:bargraph()} wrongly specified"
			exit
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
	
	local form:char _dta[network_format]
	if "`form'"!="pairs"{
		di as err "Data not in pairs format, see {helpb network setup} or {helpb network import} for details"
		exit
	}
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
	lab def _trt 1 "`tr1'"
	forvalues i=2/`ntm'{
		lab def _trt `i' "`tr`i''",add
	}
	cap set matsize 800
	cap set matsize 11000
	
	tokenize `varlist'
	local est `1'
	local se `2'
	
	if "`fixed'"!=""{
		local pe "fixedi"
	}
	else{
		local pe "randomi"	
	}	
	if "`threshold'"!=""{
		local threshold=real("`threshold'")
	}
	if "`tau2'"!=""{
		local nettau2=real("`tau2'")
		if `nettau2'==. & `nettau2'<0{
			di _newline
			di as text " Negative or missing value not allowed in option {it:tau2()}"
			exit
		}	
		if "`random'"!="" {
			di as err "Option {it:random} may not be combined with option {it:tau2(`tau2')}" 
			exit
		}	
		if "`fixed'"!="" {
			di as err "Option {it:fixed} may not be combined with option {it:tau2(`tau2')}" 
			exit
		}	
	}
	if "`scale'" != "" { 
		local scale=real("`scale'") 
	}
	else{
		local scale=1
	}	
	if "`aspect'"!=""{
		local asp=real("`aspect'")
	}
	else{
		local asp=1
	}	
	if "`decimals'"!=""{
		local dec=real("`decimals'")
	}
	else{
		local dec=2
	}	
	if "`color'"!=""{
		local col "`color'"
	}
	else{
		local col "gs11"	
	}	
	if "`symbol'"!=""{
		local symb "`symbol'"
	}
	else{
		local symb "square"	
	}	
	
	/*get the pooled estimates for all direct comparisons*/
	tempvar nsc c tnew1 tnew2 told1 told2 tbind1 tbind2
	qui{
		encode `t1',gen(`told1') lab(_trt)
		encode `t2',gen(`told2') lab(_trt)
		gen `tnew1'=min(`told1',`told2')
		gen `tnew2'=max(`told1',`told2')
		lab val `tnew1' _trt
		lab val `tnew2' _trt
		replace `est'=-`est' if `tnew1'==`told1'	
		gen `tbind1'=string(`tnew1',"%02.0f")
		gen `tbind2'=string(`tnew2',"%02.0f")
		egen `c'=concat(`tbind1' `tbind2'),punct(_)
		cap drop _dc*
		tab `c',gen(_dc)
		tempname DC
		mkmat _dc*,matrix(`DC')
		local nc=colsof(`DC')
		sort `tnew1' `tnew2',stable
		by `tnew1' `tnew2',sort:gen `nsc'=_N
		forvalues i=1/`dim'{
			forvalues j=`=`i'+1'/`ntm'{
				tempvar ns`i'_`j'
				gen `ns`i'_`j''=`nsc' if `tnew1'==`i' & `tnew2'==`j'
			}
		}
	}
	if "`tau2'"!=""{
		tempvar wgt senew
		qui gen `wgt'=1/((`se'^2)+`nettau2')
		qui gen `senew'=sqrt((`se'^2)+`nettau2')
		forvalues j=1/`nc' {
			cap metan `est' `senew' if _dc`j'==1, wgt(`wgt') nograph notable nokeep
			local pooled`j'=r(ES)
			local var`j'=(r(seES))^2
		}	
	}
	else{
		forvalues j=1/`nc' {
			cap metan `est' `se' if _dc`j'==1, `pe' nograph notable nokeep
			local pooled`j'=r(ES)
			local var`j'=(r(seES))^2
		}
	}
	
	/*get all the indirect comparisons*/
	
	tempvar tt1 tt2 indt1 indt2
	local ncall=`ntm'*(`ntm'-1)/2
	if _N<`ncall'{
		qui set obs `ncall'
	}
	qui{
		gen `indt1'=""
		gen `indt2'=""
		forvalues i=1/`dim'{
			forvalues j=`=`i'+1'/`ntm'{
				tempvar com`i'_`j' scom`i'_`j'
				gen `com`i'_`j''=1 if `tnew1'==`i' & `tnew2'==`j'
				egen `scom`i'_`j''=sum(`com`i'_`j'')
				local ccd`i'_`j'=`scom`i'_`j''
			}
		}	
		forvalues i=1/`dim'{
			forvalues j=`=`i'+1'/`ntm'{	
				if `ccd`i'_`j''==0{
					replace `indt1'="`tr`i''" in 1
					replace `indt2'="`tr`j''" in 1
					sort `indt1',stable
				}
			}
		}
		encode `indt1',gen(`tt1') lab(_trt)
		encode `indt2',gen(`tt2') lab(_trt)
	}
	tempvar labs compind comp
	qui{
		sort `tnew1' `tnew2',stable
		egen `comp'=concat(`tnew1' `tnew2') if `tnew1'!=.,punct("-") decode
		by `tnew1' `tnew2',sort:gen `labs'=`comp' if _n==1 
		forvalues i=1/`dim'{
			forvalues j=`=`i'+1'/`ntm'{		
				replace `nsc'=`ns`i'_`j'' if `tnew1'==`i' & `tnew2'==`j' & `labs'!=""
			}
		}		
		sort `tt1' `tt2',stable
		egen `compind'=concat(`indt1' `indt2') if `indt1'!="" & `indt2'!="",punct("-")		
	}
	qui gsort -`labs'
	qui sort `tnew1' `tnew2' in 1/`nc',stable
	forvalues i=1/`nc'{
		local obs=`i'
		local dir`i'=`labs' in `obs'
		local numst`i'=`nsc' in `obs'
	}
	forvalues c=1/`nc'{
		forvalues i=1/`dim'{
			forvalues j=`=`i'+1'/`ntm'{
				if "`dir`c''"=="`tr`i''-`tr`j''"{
					local dir`c'="`tr`i''_`tr`j''"
					local labnewdir`c'="`tr`i''-`tr`j''"
				}
			}
		}
	}
	qui gsort -`labs'
	qui sort `tnew1' `tnew2' in 1/`nc',stable
	if "`notable'"==""{
		di as res _newline "Direct comparisons and number of included studies:" _newline
		li `labs' `nsc' if `labs'!="" , separator(0) noheader clean 	
	}
	forvalues i=1/`nc'{
		local lab`i'=`labs' in `i'
	}
	qui sort `tt1' `tt2',stable
	local indir1=""
	local indir1=`compind' in 1	
	forvalues i=2/`=`ncall'-`nc''{
		local indir`i'=""
		local indir`i'=`compind' in `i'
	}	
	if "`notable'"==""{
		qui gsort -`compind'
		cap qui sort `tt1' `tt2' in 1/`=`ncall'-`nc'',stable
		di as res _newline "Indirect comparisons:" _newline
		li `compind' if `compind'!="" , separator(0) noheader clean 	
	}
	forvalues i=`=`nc'+1'/`ncall'{
		local lab`i'=`compind' in `=`i'-`nc''
	}	
	local rowlab1="`lab1'"
	forvalues i=2/`ncall'{
		local rowlab`i'="`rowlab`=`i'-1'' `lab`i''"
	}	
	
	/*get the Y and V matrices*/
	
	tempname Y V VV
	mat `Y'=J(`nc',1,0)
	mat `V'=J(`nc',`nc',0)
	mat `VV'=J(`ncall',`ncall',0)
	forvalues i=1/`nc'{
		mat `Y'[`i',1]=`pooled`i''
		mat `V'[`i',`i']=`var`i''
		mat `VV'[`i',`i']=`var`i''
	}
	forvalues i=`=`nc'+1'/`ncall'{
		mat `VV'[`i',`i']=10000
	}
	mat rownames `Y'=`rowlab`nc''
	mat colnames `Y'="y"
	if "`notable'"=="" & "`noymatrix'"==""{
		di as res _newline "Direct relative effects:"
		mat li `Y', format(%9.`dec'f) noh
		if `"`export'"'!=""{
			qui putexcel set `"`export'"',sheet(Y,replace) modify
			qui putexcel A1=mat(`Y'),names
		}
	}
	ereturn mat y `Y'
	mat rownames `V'=`rowlab`nc''
	mat colnames `V'=`rowlab`nc''
	if "`notable'"=="" & "`novmatrix'"==""{
		di as res _newline "Variances of direct relative effects:"
		mat li `V', nohalf format(%9.`dec'f) noh
		if `"`export'"'!=""{
			qui putexcel set `"`export'"',sheet(V,replace) modify
			qui putexcel A1=mat(`V'),names
		}
	}
		
	/*get the basic contrasts and design matrix*/
	qui{
		tempvar treat1 treat2 dir basic less basic_new con
		sort `tnew1' `tnew2',stable
		by `tnew1' `tnew2',sort: replace `tnew1'=. if _n>1
		mkmat `tnew1' `tnew2' if `tnew1'!=.,mat(_DIR)
		sort `tt1' `tt2',stable
		cap mkmat `tt1' `tt2' if `tt1'!=. ,mat(_IND)
		mat _C=_DIR
		cap mat _C=_DIR\_IND
		sort `tnew1' `tnew2',stable
		svmat _C,names(_treat)
		cap mat drop _DIR _IND _C
		gen `treat1'=_treat1
		gen `treat2'=_treat2
		gen `dir'=1 if _n<=`nc'
		forvalues i=1/`nc'{	
			replace _dc`i'=.
			local treat1`i'=`treat1' in `i'
			local treat2`i'=`treat2' in `i'
			rename _dc`i' _cc`treat1`i''_`treat2`i''
		}
		tempvar rank dirr1 dirr2
		gen `rank'=_n
		gen `dirr1'=_n if `dir'==1
		gen `dirr2'=_n if `dir'==1
		mkmat `treat1' `treat2'  in 1,mat(_bb1)
		mat _BB=_bb1
		cap mat drop _bb1
		forvalues i=2/`nc'{
			mkmat `treat1' `treat2' in `i',mat(_bb`i')
			mat _BB=_BB,_bb`i'
			cap mat drop _bb`i'
		}
		mkmat `dirr1' `dirr2' in 1,mat(_dd1)
		mat _DD=_dd1
		cap mat drop _dd1
		forvalues i=2/`nc'{
			mkmat `dirr1' `dirr2' in `i',mat(_dd`i')
			mat _DD=_DD,_dd`i'
			cap mat drop _dd`i'
		}
		mat _BD=_BB\_DD
		mat _BD=_BD'
		cap set obs `=2*`nc''
		svmat _BD
		mat drop _BD _BB _DD
		sort _BD1 _BD2,stable
		by _BD1,sort:replace _BD1=. if _n>1
		sort _BD2 _BD1,stable
		replace _BD2=. if _BD1==.
		by _BD2,sort:replace _BD2=. if _n>1
		mkmat _BD2 if _BD2!=.,mat(_BD2)
		gen `basic'=.
		sort `dir' `treat1' `treat2',stable
		forvalues i=1/`=rowsof(_BD2)'{
			replace `basic'=1 in `=_BD2[`i',1]'
		}
		
		/*check whether defined basic contrasts are connected*/
		sort `basic' `dir',stable
		forvalues i=1/`dim'{
			mat B`i'=.
			forvalues t=1/`dim'{
				mat B`t'all`i'=.
			}
			cap mkmat `treat1' `treat2' if `basic'==1 & `treat1'==`i',mat(B`i')
			mat B1all`i'=J(1,`=`=rowsof(B`i')'+1',.)
			mat B1all`i'[1,1]=B`i'[1,1]
			forvalues j=2/`=colsof(B1all`i')'{
				mat B1all`i'[1,`j']=B`i'[`=`j'-1',2]
			}
			mat drop B`i'
		}
		forvalues i=1/`=`ntm'-2'{
			forvalues j=2/`=`ntm'-1'{
				if `i'==`j' continue
				forvalues x=1/`=colsof(B1all`i')'{
					forvalues y=1/`=colsof(B1all`j')'{
						if B1all`i'[1,`x']!=B1all`j'[1,`y'] | B1all`i'[1,`x']==. continue
						if B1all`i'[1,`x']==B1all`j'[1,`y'] {
							cap mat B2all`i'=(B1all`i',B1all`j')
							mat B1all`j'=.
							mat B1all`i'=.
						}
					}
				}
			}
		}
		forvalues i=1/`=`ntm'-1'{
			if matmissing(B1all`i')!=1 & matmissing(B2all`i')==1{
				mat B2all`i'=B1all`i'
				mat drop B1all`i'
			}
			else if matmissing(B1all`i')==1{
				mat drop B1all`i'
			}
		}
		forvalues i=1/`=`ntm'-1'{
			cap mat drop Ball`i'
			cap mat Ball`i'=B2all`i'
		}
		forvalues t=3/`=`ntm'-1'{
			forvalues i=1/`=`ntm'-2'{
				forvalues j=2/`=`ntm'-1'{
					if `i'==`j' continue
					forvalues x=1/`=colsof(B`=`t'-1'all`i')'{
						forvalues y=1/`=colsof(B`=`t'-1'all`j')'{
							if B`=`t'-1'all`i'[1,`x']!=B`=`t'-1'all`j'[1,`y'] | B`=`t'-1'all`i'[1,`x']==. continue
							if B`=`t'-1'all`i'[1,`x']==B`=`t'-1'all`j'[1,`y'] {
								cap mat B`t'all`i'=(B`=`t'-1'all`i',B`=`t'-1'all`j')
								mat B`=`t'-1'all`j'=.
								mat B`=`t'-1'all`i'=.
							}
						}
					}
				}
			}
			forvalues i=1/`=`ntm'-1'{
				if matmissing(B`=`t'-1'all`i')!=1 & matmissing(B`t'all`i')==1{
					mat B`t'all`i'=B`=`t'-1'all`i'
					mat drop B`=`t'-1'all`i'
				}
				else if matmissing(B`=`t'-1'all`i')==1{
					mat drop B`=`t'-1'all`i'
				}
			}
			local B`t'=0
			forvalues i=1/`=`ntm'-1'{
				cap{
					assert colsof(B`t'all`i')==colsof(Ball`i')
				}
				if matmissing(B`t'all`i')!=1{
					local B`t'=`B`t''+_rc
				}
			}
			forvalues i=1/`=`ntm'-1'{
				cap mat drop Ball`i'
				cap{
					assert matmissing(B`t'all`i')!=1
				}
				if _rc==0{
					mat Ball`i'=B`t'all`i'
				}
			}
			if `B`t''==0 continue,break
		}
		forvalues t=1/`=`ntm'-1'{
			forvalues i=1/`=`ntm'-1'{
				cap mat drop B`t'all`i'
			}
		}
		mat drop _BD2
		egen `less'=sum(`basic')
		local lv=`less' in 1
		forvalues i=`=`lv'+1'/`nc'{
			mkmat `treat1' `treat2' in `i',mat(D`i')
		}
		gen `basic_new'=.
		gen `con'=""
		forvalues i=1/`=`ntm'-2'{
			cap{
				assert matmissing(Ball`i')!=1 
			}
			if _rc!=0 continue
			forvalues j=2/`=`ntm'-1'{
				cap{
					assert matmissing(Ball`j')!=1 
				}
				if _rc!=0 continue
				if `i'==`j' continue
				forvalues z=`=`lv'+1'/`=`ntm'-1'{
					forvalues x=1/`=colsof(Ball`i')'{
						forvalues y=1/`=colsof(Ball`j')'{
							if (Ball`i'[1,`x']==D`z'[1,1] & Ball`j'[1,`y']==D`z'[1,2]) | (Ball`i'[1,`x']==D`z'[1,2] & Ball`j'[1,`y']==D`z'[1,1]) {
								local con`z'="c`i'_`j'"
								replace `basic_new'=1 in `z'
								replace `con'="`con`z''" in `z'
							}
						}
					}
				}
			}
		}
		by `basic_new' `con',sort: replace `basic_new'=. if _n>1
		replace `basic'=`basic_new' if `basic'==.
		
		sort `basic' `dir',stable
		replace `basic'=1 if _n<`ntm'
		forvalues i=`=`lv'+1'/`nc'{
			mat drop D`i'
		}
		forvalues i=1/`=`ntm'-1'{
			cap mat drop Ball`i'
		}
		order _cc*, alpha
		forvalues i=1/`ntm'{
			forvalues j=`=`i'+1'/`ntm'{
				cap replace _cc`i'_`j'=1 if `treat1'==`i' & `treat2'==`j' & `basic'==1
			}
		}

		forvalues i=1/`ntm'{
			forvalues j=`=`i'+1'/`ntm'{
				local nb`i'_`j'=0	
				tempvar dr`i'_`j'
				gen `dr`i'_`j''=1 if `treat1'==`i' & `treat2'==`j' & `basic'==.
			}
		}
		forvalues i=1/`ntm'{
			forvalues j=`=`i'+1'/`ntm'{	
				sort `dr`i'_`j'',stable
				local nb`i'_`j'=`dr`i'_`j'' in 1
				if `nb`i'_`j''==1{
					cap drop _cc`i'_`j'
				}
			}
		}
		sort `rank',stable	
		
		mkmat `treat1' if `basic'==1,mat(_basic1)
		mkmat `treat2' if `basic'==1,mat(_basic2)
		mkmat `treat1' if `dir'==1,mat(_dir1)
		mkmat `treat2' if `dir'==1,mat(_dir2)		
		mkmat `treat1' if _n<=`ncall',mat(_treat1)
		mkmat `treat2' if _n<=`ncall',mat(_treat2)
		scalar _ntm=`ntm'
		scalar _ncall=`ncall'
		scalar _nc=`nc'
		cap drop _BD1 _BD2
	}
	if `ntm'>20{
		di as text _newline "Constructing the design matrix..."
	}
	mata desmat()

	tempname X
	mat `X'=_X
	qui{
		forvalues i=1/`dim'{
			forvalues j=`=`i'+1'/`ntm'{
				cap tostring _cc`i'_`j',replace
				cap replace _cc`i'_`j'="`i'_`j'"
				cap rename _cc`i'_`j' _cc`i'_`j'_
				cap split _cc`i'_`j'_,par(_)
				cap destring _cc`i'_`j'_1 _cc`i'_`j'_2,replace	
				cap label values _cc`i'_`j'_1 _trt
				cap label values _cc`i'_`j'_2 _trt
				if `i'<10 & `j'<10{
					cap egen _bc0`i'_0`j'=concat(_cc`i'_`j'_1 _cc`i'_`j'_2),punct("-") decode
				}
				if `i'<10 & `j'>=10{
					cap egen _bc0`i'_`j'=concat(_cc`i'_`j'_1 _cc`i'_`j'_2),punct("-") decode
				}	
				if `i'>=10 & `j'>10{
					cap egen _bc`i'_`j'=concat(_cc`i'_`j'_1 _cc`i'_`j'_2),punct("-") decode
				}				
			}
		}
	}
	order _bc*,alpha
	mat rownames `X'=`rowlab`ncall''
	local colblab=""
	foreach var of varlist _bc*{
		local blab`var'=`var' in 1
		local colblab="`colblab' `blab`var''"
	}
	mat colnames `X'=`colblab'
	if "`notable'"=="" & "`noxmatrix'"==""{
		di as res _newline "Basic contrasts:" _newline
		li _bc* in 1, separator(0) noheader clean noobs
		di as res _newline "Design matrix:"			
		mat li `X', noh
		if `"`export'"'!=""{
			qui putexcel set `"`export'"',sheet(X,replace) modify
			qui putexcel A1=mat(`X'),names
		}
	}
	//qui mat drop _basic1 _basic2

	/*get the hat matrix*/
	
	tempname H
	mat `H'=`X'*inv((`X''*inv(`VV')*`X'))*`X''*inv(`VV')
	mat `H'=`H'[1..`ncall',1..`nc']
	mat rownames `H'=`rowlab`ncall''
	mat colnames `H'=`rowlab`nc''
	if "`notable'"=="" & "`nohmatrix'"==""{
		di as res _newline "Hat matrix:"
		mat li `H',  format(%9.`dec'f) noh
		if `"`export'"'!=""{
			qui putexcel set `"`export'"',sheet(H,replace) modify
			qui putexcel A1=mat(`H'),names
		}
	}
	ereturn mat v `V'
	ereturn mat x `X'
	
	mat _H=`H'
	
	if `ntm'>20{
		di as text _newline "Constructing the contribution matrix..."
	}
	
	mata allpaths()
	
	scalar drop _ntm
	scalar drop _nc
	scalar drop _ncall

	qui{
		tempvar matsum total
		tempname P C
		mat `P'=_PH
		svmat `P', names(_P)
		forvalues i=1/`nc'{
			egen _C`i'=sum(_P`i')
		}
		egen `total'=rowtotal(_C*)
		forvalues i=1/`nc'{
			replace _C`i'=((_C`i'/`total')*100)
		}
		mkmat _C* in 1,mat(`C') rowprefix(comp)
		matrix rownames `C'=network
	}
	ereturn mat h `H'
	mat rownames `P'=`rowlab`ncall''
	mat colnames `P'=`rowlab`nc''
	mat colnames `C'=`rowlab`nc''
	if "`notable'"==""{
		di as res _newline "Percentage contribution of each direct comparison in each pairwise summary effect:"
		mat li `P',  format(%9.`dec'f) noh
		if `"`export'"'!=""{
			qui putexcel set `"`export'"',sheet(P,replace) modify
			qui putexcel A1=mat(`P'),names
			qui putexcel set `"`export'"',sheet(C,replace) modify
			qui putexcel A1=mat(`C'),names
		}
	}
	
	if "`notable'"==""{
		di as res _newline "Percentage contribution of each direct comparison in the entire network:"
		mat li `C',  format(%9.2f) noh
	}
	local plot=`ncall'*`nc'

	if "`bargraph'"!=""{
		cap set obs `=`ncall'+1'
		cap drop `tnew1' `tnew2'
		encode `t1',gen(`tnew1') lab(_trt)
		encode `t2',gen(`tnew2') lab(_trt)
		qui gen _ccomp=""
		forvalues i=1/`nc'{
			qui replace _ccomp="`dir`i''" in `i'			
		}
		forvalues i=1/`dim'{
			forvalues j=`=`i'+1'/`ntm'{
				qui replace _ccomp="`tr`i''-`tr`j''" if _ccomp=="`tr`i''_`tr`j''"
			}
		}		
		forvalues i=1/`=`ncall'-`nc''{
			cap qui replace _ccomp="`indir`i''" in `=`nc'+`i''
		}
		qui replace _ccomp="Entire network" in `=`ncall'+1'
		forvalues i=1/`nc'{
			cap rename _P`i' _dir_`dir`i''
			cap label var _dir_`dir`i'' "`labnewdir`i''"
		}
		forvalues i=1/`nc'{
			cap replace _dir_`dir`i''=_C`i' in `=`ncall'+1'
		}	
		qui gen _rank=_n
		qui gen _tit="RoB of network estimates" in 1/`=`ncall'+1'
	
		tempvar robnew
		tokenize `bargraph'
		qui{
			if "`rob'"!=""{
				local rob `2'
				local robmeth "`3'"
				cap {
					assert int(`rob')==`rob'
				}
				if _rc!=0{
					if "`bylevels'"!=""{
						di as err "Non-numeric {it:groupvar} in option {it:bargraph()} may not be combined with option {it:bylevels()}"
						ereturn mat p `P'
						ereturn mat c `C'	
						exit
					}
					else{
						gen `robnew'=3 if `rob'=="H" | `rob'=="h" | `rob'=="high" | `rob'=="HIGH" | `rob'=="High"
						replace `robnew'=1 if `rob'=="L" | `rob'=="l" | `rob'=="low" | `rob'=="LOW" | `rob'=="Low"
						replace `robnew'=2 if `rob'=="U" | `rob'=="u" | `rob'=="unclear" | `rob'=="UNCLEAR" | `rob'=="Unclear"
						replace `robnew'=. if `rob'!="H" & `rob'!="h" & `rob'!="high" & `rob'!="HIGH" & `rob'!="High" & `rob'!="L" & `rob'!="l" & `rob'!="low" & `rob'!="LOW" & `rob'!="Low" & `rob'!="U" & `rob'=="u" & `rob'!="unclear"  & `rob'!="UNCLEAR" & `rob'!="Unclear"
					}
				}
				else {
					gen `robnew'=`rob'
					if "`bylevels'"==""{
						replace `robnew'=. if `rob'>3 | `rob'<1
					}
				}		
				if "`robmeth'"==""{
					local robmeth "mode"
				}		
				if "`robmeth'"=="mode"{
					tempvar nrob 
					by `tnew1' `tnew2' `robnew',sort:gen `nrob'=_N
					forvalues i=1/`ntm'{
						forvalues j=`=`i'+1'/`ntm'{
							tempvar mrob`i'_`j' smrob`i'_`j' pmrob`i'_`j'
							egen `mrob`i'_`j''=max(`nrob') if `tnew1'==`i' & `tnew2'==`j' 
							gen `pmrob`i'_`j''=`robnew' if `mrob`i'_`j''==`nrob'
							egen `smrob`i'_`j''=max(`pmrob`i'_`j'')
				
						}
					}
				}
				if "`robmeth'"=="max"{
					forvalues i=1/`ntm'{
						forvalues j=`=`i'+1'/`ntm'{
							tempvar maxrob`i'_`j' smrob`i'_`j'
							egen `maxrob`i'_`j''=max(`robnew') if `robnew'!=. & `tnew1'==`i' & `tnew2'==`j' 
							egen `smrob`i'_`j''=max(`maxrob`i'_`j'')
						}
					}
				}			
				if "`robmeth'"=="min"{
					forvalues i=1/`ntm'{
						forvalues j=`=`i'+1'/`ntm'{
							tempvar minrob`i'_`j' smrob`i'_`j'
							egen `minrob`i'_`j''=min(`robnew') if `robnew'!=. & `tnew1'==`i' & `tnew2'==`j' 
							egen `smrob`i'_`j''=max(`minrob`i'_`j'')
						}
					}
				}			
				if "`robmeth'"=="mean"{
					forvalues i=1/`ntm'{
						forvalues j=`=`i'+1'/`ntm'{
							tempvar meanrob`i'_`j' smrob`i'_`j'
							egen `meanrob`i'_`j''=mean(`robnew') if `robnew'!=. & `tnew1'==`i' & `tnew2'==`j' 
							replace `meanrob`i'_`j''=round(`meanrob`i'_`j'',1)
							egen `smrob`i'_`j''=max(`meanrob`i'_`j'')
						}
					}
				}	
				if "`robmeth'"=="wmean"{
					cap{
						assert "`4'"!=""
					}
					if _rc!=0{
						di as err "Weighting variable for risk of bias assessment not specified in option {it:edgecolor}"
						ereturn mat p `P'
						ereturn mat c `C'					
						exit
					}
					else{
						local weight `4'				
						forvalues i=1/`ntm'{
							forvalues j=`=`i'+1'/`ntm'{
								tempvar mulrob`i'_`j' sumw`i'_`j' wmeanrob`i'_`j' smrob`i'_`j'
								egen `mulrob`i'_`j''=sum(`robnew'*`weight')  if `robnew'!=. & `tnew1'==`i' & `tnew2'==`j'  
								egen `sumw`i'_`j''=sum(`weight') if `robnew'!=. & `tnew1'==`i' & `tnew2'==`j' 
								gen `wmeanrob`i'_`j''=`mulrob`i'_`j''/`sumw`i'_`j''
								replace `wmeanrob`i'_`j''=round(`wmeanrob`i'_`j'',1)
								egen `smrob`i'_`j''=max(`wmeanrob`i'_`j'')
							}
						}
					}
				}
				if "`bylevels'"!=""{
					local bylev=real("`bylevels'")
					tokenize `"`bycolors'"'
					forvalues z=1/`bylev'{
						local bycol`z'="``z''"
						if "``z''"==""{
							local bycol`z'="black"
						}
					}
					forvalues i=1/`ntm'{
						forvalues j=`=`i'+1'/`ntm'{
							local ecol`i'_`j'=""
							forvalues z=1/`bylev'{
								if `smrob`i'_`j''==`z'{
									local ecol`i'_`j'="`bycol`z''"
								}
							}
						}
					}
				}
				else{
					forvalues i=1/`ntm'{
						forvalues j=`=`i'+1'/`ntm'{
							local ecol`i'_`j'=""
							if `smrob`i'_`j''==1{
								local ecol`i'_`j'="green"
							}
							if `smrob`i'_`j''==2{
								local ecol`i'_`j'="gold"
							}
							if `smrob`i'_`j''==3{
								local ecol`i'_`j'="cranberry"
							}
							if "`ecol`i'_`j''"==""{
								local ecol`i'_`j'="white"
							}
						}
					}	
				}	
			}
		}
		tempvar labcol
		qui gen `labcol'=""
		forvalues i=1/`ntm'{
			forvalues j=`=`i'+1'/`ntm'{
				qui replace `labcol'="`ecol`i'_`j''" if `tnew1'==`i' & `tnew2'==`j' & `labs'!=""
			}
		}
		qui gsort -`labs'
		qui sort `labs' in 1/`nc'
		forvalues i=1/`nc'{
			tempname coldir`i'
			local coldir`i'=`labcol' in `i'
		}
		local order "order"
		if "`order'"!=""{
			forvalues i=1/`nc'{
				cap rename  _dir_`dir`i'' _dir_`coldir`i''_`dir`i''
				cap label var _dir_`coldir`i''_`dir`i'' "`labnewdir`i''"
			}		
			order _dir_*,alpha
			cap egen _col_cranberry=rowtotal(_dir_cranberry*)
			cap gen _col_cranberry=0
			cap egen _col_gold=rowtotal(_dir_gold*)
			cap gen _col_gold=0		
			cap egen _col_green=rowtotal(_dir_green*)
			cap gen _col_green=0			
			
			forvalues i=1/`nc'{
				forvalues j=`=`i'+1'/`nc'{
					if "`coldir`i''"<"`coldir`j''"{
						tempname coldir`i'_new coldir`j'_new
						local coldir`i'_new="`coldir`i''"
						local coldir`j'_new="`coldir`j''"
						local coldir`i'="`coldir`i'_new'"
						local coldir`j'="`coldir`j'_new'"
					}
					if "`coldir`i''">"`coldir`j''"{
						local coldir`i'_new="`coldir`j''"
						local coldir`j'_new="`coldir`i''"
						local coldir`i'="`coldir`i'_new'"
						local coldir`j'="`coldir`j'_new'"
					}
				}
			}		
		}
		forvalues i=1/`nc'{
			local barcol`i' `"bar(`i',color(`coldir`i''))"'
		}
		local colors1 "`barcol1'"
		forvalues i=2/`nc'{
			local colors`i' "`colors`=`i'-1'' `barcol`i''"
		}
		qui split _ccomp,gen (_tuse) parse(-)
		if "`reference'"!=""{
			local reference `reference'
			qui replace _ccomp="" if _tuse1!="`reference'" & _tuse2!="`reference'"
		}
		if "`treatexclude'"!=""{
			tokenize `treatexclude'
			forvalues i=1/`ntm'{
				qui replace _ccomp="" if _tuse1=="``i''" | _tuse2=="``i''"
			}
		}
		
		qui sort _rank
		if `ntm'<=10{
			graph hbar (asis) _dir_*  ,over( _ccomp, sort(_rank)) over(_tit, label(angle(90))) stack  `colors`nc'' ytitle("Percentage contribution of direct comparisons") yline(`threshold') `baroptions' legend(cols(5) subtitle("RoB of direct estimates"))	 
		}
		else{
			graph hbar (asis) _col_*  ,over( _ccomp, sort(_rank)) over(_tit  label(angle(90))) stack  bar(1,color(cranberry)) bar(2,color(gold)) bar(3,color(green))  ytitle("Percentage contribution of direct comparisons") yline(`threshold') `baroptions' legend(off)
		}
		if `"`export'"'!=""{
			qui putexcel set `"`export'"',sheet(rob,replace) modify
			qui putexcel A1="Direct comparisons"
			forvalues i=1/`nc'{
				qui putexcel A`=`i'+1'="`labnewdir`i''"
				if "`coldir`i''"=="cranberry"{
					qui putexcel B`=`i'+1'="",fpattern(solid,red)
				}
				if "`coldir`i''"=="gold"{
					qui putexcel B`=`i'+1'="",fpattern(solid,yellow)
				}
				if "`coldir`i''"=="green"{
					qui putexcel B`=`i'+1'="",fpattern(solid,green)
				}
			}
			qui graph export "_NETWEIGHTrob.png",replace
			qui putexcel D1 = picture(_NETWEIGHTrob.png)
		}
		
		if _rc!=0{
			ereturn mat p `P'
			ereturn mat c `C'	
		}
	}
	if "`noplot'"=="" & "`bargraph'"=="" & `ntm'>10{
		di as text _newline "The contribution matrix can be presented graphically only for networks with up to 10 treatments" _newline
	}
	if "`noplot'"=="" & "`bargraph'"=="" & `ntm'<=10{
		forvalues i=1/`nc'{
			forvalues j=1/`dim'{
				forvalues k=`=`j'+1'/`ntm'{		
					if "`dir`i''"=="`tr`j''_`tr`k''"{
						local dir`i'="`tr`j''-`tr`k''"
					}
				}
			}
		}	
		qui{
			cap set obs `plot'
			tempvar comba combb PVS CVS combc
			gen `comba'=.
			gen `combb'=.
			gen `combc'=.
			forvalues j=1/`ncall'{
				tempname st`j' end`j'
				local st`j'=`j'*`nc'-(`nc'-1)
				local end`j'=`j'*`nc'
				replace `comba'=`j' in `st`j''/`end`j''
			}
			forvalues j=1/`ncall'{
				forvalues i=1/`nc'{
					replace `combb'=_n-(`j'-1)*`nc' if `comba'==`j'
				}
			}
			replace `combb'=2*`combb'
			cap replace `comba'=`comba'+1 in 1/`=`nc'*`nc''
			cap replace `comba'=`comba'+3 in `=`nc'*`nc'+1'/`plot'
			forvalues j=1/`ncall'{
				mat _P`j'=`P'[`j',1..`nc']
				mat _PV`j'=vec(_P`j')
				mat drop _P`j'
			}
			forvalues j=2/`ncall'{
				mat _PV`j'=_PV`=`j'-1'\_PV`j'
			}
			mat _CV=vec(`C')
			svmat _CV
			mat drop _CV
			rename _CV1 _CV
			svmat _PV`ncall'
			rename _PV`ncall'1 _PV
			format _PV %9.`dec'f
			format _CV %9.`dec'f
			forvalues j=1/`ncall'{
				mat drop _PV`j'
			}
			forvalues i=1/`=_N'{
				tempname w`i'
				local w`i'=_PV in `i'
				local w`i'=(`w`i''/10)*`scale'
			}
			gen `PVS'=string(_PV,"%9.1f")
			gen `CVS'=string(_CV,"%9.1f")
			forvalues i=1/`nc'{
				tempname wn`i'
				local wn`i'=_CV in `i'
				local wn`i'=(`wn`i''/10)*`scale'
			}			
			replace `PVS'="" if `PVS'=="0.0"
			local xtitle `"||scatteri -3 `=`nc'+1' "{bf:Direct comparisons in the network}", mlabpos(0) msymb(i) mlabsize(`textsize') mlabcol(black)"'
			local ytitle `"||scatteri `=(`ncall'+3)/2' -7.5 "{bf:Network meta-analysis estimates}", mlabpos(0) msymb(i) mlabsize(`textsize') mlabcol(black)  mlabangle(90) "'
			local labmix `"||scatteri 1 -4 "Mixed estimates", mlabpos(0) msymb(i) mlabsize(`textsize') mlabcol(black)"'
			local labind `"||scatteri `=`nc'+3' -4 "Indirect estimates", mlabpos(0) msymb(i) mlabsize(`textsize') mlabcol(black)"'
			local labnet `"||scatteri `=`ncall'+5' -8 "{bf:Entire network}", mlabpos(3) msymb(i) mlabsize(`textsize') mlabcol(black)"'
			if "`nostudies'"==""{
				local labst `"||scatteri `=`ncall'+7' -8 "{bf:Included studies}", mlabpos(3) msymb(i) mlabsize(`textsize') mlabcol(black) || pci `=`ncall'+6' `=`nc'*2+1' `=`ncall'+6' -8, lwidth(thin) lcol(black)"'
				local labst1 `"||scatteri `=`ncall'+7' 2 "`numst1'", mlabpos(0) msymb(i) mlabsize(`textsize') mlabcol(black)"'
				forvalues i=2/`nc'{
					local labst`i' `"`labst`=`i'-1'' ||scatteri `=`ncall'+7' `=`i'*2' "`numst`i''", mlabpos(0) msymb(i) mlabsize(`textsize') mlabcol(black)"'
				}	
				local dst=7.2
			}
			else{
				local labst `""'
				local labst`nc' `""'
				local dst=5
			}	
			local labx1 `"||scatteri -1 2 "`dir1'", mlabpos(0) msymb(i) mlabsize(`textsize') mlabcol(black)"'		
			forvalues i=2/`nc'{
				local labx`i' `"`labx`=`i'-1'' ||scatteri -1 `=`i'*2' "`dir`i''", mlabpos(0) msymb(i) mlabsize(`textsize') mlabcol(black)"'
			}
			local laby1 `"||scatteri 2 -1 "`dir1'", mlabpos(9) msymb(i) mlabsize(`textsize') mlabcol(black)"'
			forvalues i=2/`nc'{
				local laby`i' `"`laby`=`i'-1'' ||scatteri `=`i'+1' -1 "`dir`i''", mlabpos(9) msymb(i) mlabsize(`textsize') mlabcol(black)"'
			}
			local labyy1 `"||scatteri `=`nc'+4' -1 "`indir1'", mlabpos(9) msymb(i) mlabsize(`textsize') mlabcol(black)"'
			forvalues i=2/`=`ncall'-`nc''{
				local labyy`i' `"`labyy`=`i'-1'' ||scatteri `=`nc'+`i'+3' -1 "`indir`i''", mlabpos(9) msymb(i) mlabsize(`textsize') mlabcol(black)"'
			}	

			capture{
				if "`novalues'"==""{
					local square1 `"|| sc  `comba' `combb' in 1, mlab(`PVS') mlabpos(0) msymb(`symb') mcol(`col') mlabcol(black) msize(`w1') mlabsize(`textsize')"'
					forvalues i=2/`=_N'{
						local square`i' `"`square`=`i'-1'' || sc  `comba' `combb' in `i', mlab(`PVS') mlabpos(0) msymb(`symb') mcol(`col') mlabcol(black) msize(`w`i'') mlabsize(`textsize')||"'
					}
					replace `combc'=`comba'+`ncall'+3
					local squarenet1 `"|| sc  `combc' `combb' in 1, mlab(`CVS') mlabpos(0) msymb(`symb') mcol(`col') mlabcol(black) msize(`wn1') mlabsize(`textsize')"'
					forvalues i=2/`nc'{
						local squarenet`i' `"`squarenet`=`i'-1'' || sc  `combc' `combb' in `i', mlab(`CVS') mlabpos(0) msymb(`symb') mcol(`col') mlabcol(black) msize(`wn`i'') mlabsize(`textsize')||"'
					}
				}
				else{
					local square1 `"|| sc  `comba' `combb' in 1, mlabpos(0) msymb(`symb') mcol(`col') mlabcol(black) msize(`w1') mlabsize(`textsize')"'
					forvalues i=2/`=_N'{
						local square`i' `"`square`=`i'-1'' || sc  `comba' `combb' in `i', mlabpos(0) msymb(`symb') mcol(`col') mlabcol(black) msize(`w`i'') mlabsize(`textsize')||"'
					}
					replace `combc'=`comba'+`ncall'+3
					local squarenet1 `"|| sc  `combc' `combb' in 1, mlabpos(0) msymb(`symb') mcol(`col') mlabcol(black) msize(`wn1') mlabsize(`textsize')"'
					forvalues i=2/`nc'{
						local squarenet`i' `"`squarenet`=`i'-1'' || sc  `combc' `combb' in `i', mlabpos(0) msymb(`symb') mcol(`col') mlabcol(black) msize(`wn`i'') mlabsize(`textsize')||"'
					}				
				}		
				local lines `"||pci `=`ncall'+`dst'' 0 -1.5 0, lwidth(thin) lcolor(black)|| pci 0 `=`nc'*2+2' 0 -8, lwidth(thin) lcol(black) || pci `=`nc'+2' `=`nc'*2+1' `=`nc'+2' -4, lwidth(thin) lcol(black) lpattern(dash) || pci `=`ncall'+4' `=`nc'*2+1' `=`ncall'+4' -8, lwidth(thin) lcol(black)"'
				twoway `xtitle' || `ytitle' || `lines' || `labmix' || `labind' || `labnet' || `labst' || `squarenet`nc'' || `labst`nc'' || `square`=_N'' ,yscale(rev) legend(off) ylab(-1(1)`ncall',nogrid) xlab(-1(1)`nc') yscale(off) title(`"`title'"') xscale(off) aspect(`asp') || `labx`nc'' || `laby`nc'' || `labyy`=`ncall'-`nc'''
			}
			if _rc!=0{
				di as err "Insufficient memory for the contribution plot - Please, maximize memory number of variables and try again (ses {helpb memory} and {helpb maxvar})"
			}
		}
	}
	ereturn mat p `P'
	ereturn mat c `C'	
	lab drop _trt
	mat drop _PH _H _dir1 _dir2 _treat1 _treat2 _X
	
end


mata
void desmat()
{

	t1=st_matrix("_treat1")
	t2=st_matrix("_treat2")
	T=(t1,t2)
	b1=st_matrix("_basic1")
	b2=st_matrix("_basic2")
	nt=st_numscalar("_ntm")
	dim=nt-1
	ncall=st_numscalar("_ncall")
	X=J(ncall,dim,0)
	for (t1=1; t1<=dim; t1++){
		for (t2=t1+1; t2<=nt; t2++){
			for (c=1; c<=ncall; c++){
				if (T[c,]==(t1,t2)){
					a=c
				}
			}	
			for (c=1; c<=dim; c++){
				if (t1==b1[c,1] & t2==b2[c,1]){
					X[a,c]=1
				}
			} 
			IS=rowsum(abs(X[a,]))
			B1=b1
			B2=b2
			if (IS==0){
				OO=(.,.,.,.)
				OOi=(.,.)
				for (c=1; c<=dim; c++){
					for (k=1; k<=dim; k++){
						if (k!=c & b1[k,1]==b1[c,1]){
							O=(b2[c,1],b1[c,1],b1[k,1],b2[k,1])
							Oi=(-c,k)
							OO=OO\O
							OOi=OOi\Oi
						}
						if (k!=c & b1[k,1]==b2[c,1]){
							O=(b1[c,1],b2[c,1],b1[k,1],b2[k,1])
							Oi=(c,k)
							OO=OO\O
							OOi=OOi\Oi
						}				
						if (k!=c & b2[k,1]==b1[c,1]){
							O=(b2[c,1],b1[c,1],b2[k,1],b1[k,1])
							Oi=(-c,-k)
							OO=OO\O
							OOi=OOi\Oi
						}			
						if (k!=c & b2[k,1]==b2[c,1]){
							O=(b1[c,1],b2[c,1],b2[k,1],b1[k,1])
							Oi=(c,-k)
							OO=OO\O
							OOi=OOi\Oi
						}				
					}
				}
				OO=select(OO, rowmissing(OO):==0)	
				OOi=select(OOi, rowmissing(OOi):==0)
				OOi=(OOi,OO[,1])
				OO=select(OO, OO[,1]:==t1)	
				OOi=select(OOi, OOi[,cols(OOi)]:==t1)
				OOi=OOi[,1..cols(OOi)-1]
				for (r=1; r<=rows(OO); r++){
					if (t2==OO[r,cols(OO)]){
						for (k=1; k<=cols(OOi); k++){
							X[a,abs(OOi[r,k])]=sign(OOi[r,k])
						}
					}
				}
				IS=rowsum(abs(X[a,]))
				for (i=2; i<=dim; i++){
					if (IS==0){
						COO=J(1,cols(OO)+2,.)
						COOi=J(1,cols(OOi)+1,.)
						for (k=1; k<=rows(OO); k++){
							for (c=1; c<=rows(B1); c++){
								if (B1[c,1]==OO[k,cols(OO)] & B2[c,1]!=OO[k,cols(OO)-1]){
									CO=(OO[k,],B1[c,1],B2[c,1])
									COO=COO\CO
									COi=(OOi[k,],c)
									COOi=COOi\COi
								}	
								if (B2[c,1]==OO[k,cols(OO)] & B1[c,1]!=OO[k,cols(OO)-1]){
									CO=(OO[k,],B2[c,1],B1[c,1])
									COO=COO\CO
									COi=(OOi[k,],-c)
									COOi=COOi\COi									
								}							
							}
						}
						COO=select(COO, rowmissing(COO):==0)	
						COOi=select(COOi, rowmissing(COOi):==0)		
						for (r=1; r<=rows(COO); r++){
							if (t2==COO[r,cols(COO)]){
								for (k=1; k<=cols(COOi); k++){
									X[a,abs(COOi[r,k])]=sign(COOi[r,k])
								}
							}			
						}
						OO=select(COO, rowmissing(COO):==0)
						OOi=select(COOi, rowmissing(COOi):==0)
					}
					IS=rowsum(abs(X[a,]))
				}
			}	
		}
	}
	st_matrix("_X",X)
}
end
	
mata
void allpaths()
{

	d1=st_matrix("_dir1")
	d2=st_matrix("_dir2")
	t1=st_matrix("_treat1")
	t2=st_matrix("_treat2")
	T=(t1,t2)
	H=st_matrix("_H")
	for (r=1; r<=rows(H); r++){
		for (c=1; c<=cols(H); c++){
			if (abs(H[r,c])<0.0001){
				H[r,c]=0	
			}
		}
	}	
	nt=st_numscalar("_ntm")
	dim=nt-1
	nc=st_numscalar("_nc")
	ncall=st_numscalar("_ncall")
	PH=J(ncall,nc,0)
	for (c=1; c<=nc; c++){
		PH[c,c]=H[c,c]*100
		H[c,c]=0
	}	
	sh=rowsum(H)
	for (t1=1; t1<=dim; t1++){
		for (t2=t1+1; t2<=nt; t2++){
			for (c=1; c<=ncall; c++){
				if (T[c,]==(t1,t2)){
					a=c
				}
			}
			Ds=sign(H[a,])
			DS=Ds'
			D1=d1
			D2=d2	
			OO=(.,.,.,.)
			OOi=(.,.)
			for (c=1; c<=nc; c++){
				for (k=1; k<=nc; k++){
					if (k!=c & d1[k,1]==d1[c,1] & DS[c,1]==-1 & DS[k,1]==1){
						O=(d2[c,1],d1[c,1],d1[k,1],d2[k,1])
						Oi=(-c,k)
						OO=OO\O
						OOi=OOi\Oi
					}
					if (k!=c & d1[k,1]==d2[c,1] & DS[c,1]==1 & DS[k,1]==1){
						O=(d1[c,1],d2[c,1],d1[k,1],d2[k,1])
						Oi=(c,k)
						OO=OO\O
						OOi=OOi\Oi
					}				
					if (k!=c & d2[k,1]==d1[c,1] & DS[c,1]==-1 & DS[k,1]==-1){
						O=(d2[c,1],d1[c,1],d2[k,1],d1[k,1])
						Oi=(-c,-k)
						OO=OO\O
						OOi=OOi\Oi
					}			
					if (k!=c & d2[k,1]==d2[c,1] & DS[c,1]==1 & DS[k,1]==-1){
						O=(d1[c,1],d2[c,1],d2[k,1],d1[k,1])
						Oi=(c,-k)
						OO=OO\O
						OOi=OOi\Oi
					}				
				}
			}	
			OO=select(OO, rowmissing(OO):==0)	
			OOi=select(OOi, rowmissing(OOi):==0)
			OOi=(OOi,OO[,1],OO[,cols(OO)])			
			NMO=select(OO, OO[,1]:==t1)
			NMOi=select(OOi, OOi[,cols(OOi)-1]:==t1)
			NMOi1=select(NMOi, NMOi[,cols(NMOi)]:==t2)
			NMO2=select(NMO, NMO[,cols(NMO)]:!=t2)
			NMOi2=select(NMOi, NMOi[,cols(NMOi)]:!=t2)
			NMOi1=NMOi1[,1..cols(NMOi1)-2]
			NMOi2=NMOi2[,1..cols(NMOi2)-2]
			NMH=J(rows(NMOi1),cols(NMOi1),.)
			for (r=1; r<=rows(NMH); r++){
				for (c=1; c<=cols(NMH); c++){
					if (sign(NMOi1[r,c])==sign(H[a,abs(NMOi1[r,c])])){
						NMH[r,c]=abs(H[a,abs(NMOi1[r,c])])
					
					}
				}
			}
			for (r=1; r<=rows(NMH); r++){
				for (c=1; c<=cols(NMH); c++){
					if (NMH[r,c]==.){
						NMOi1[r,c]=.
					}								
				}
			}
			NMH=select(NMH, rowmissing(NMH):==0)
			NMOi1=select(NMOi1, rowmissing(NMOi1):==0)				
			NMHm=rowmin(NMH)
			NMH=(NMH,NMHm)
			NMOi1=(NMOi1,NMHm)
			NMH=sort(NMH,-cols(NMH))
			NMOi1=sort(NMOi1,-cols(NMOi1))
			NMH=NMH[,1..cols(NMH)-1]
			NMOi1=NMOi1[,1..cols(NMOi1)-1]
			for (r=1; r<=rows(NMH); r++){
				for (c=1; c<=cols(NMH); c++){
					if (sign(NMOi1[r,c])==sign(H[a,abs(NMOi1[r,c])])){
						NMH[r,c]=abs(H[a,abs(NMOi1[r,c])])
					}
					else{
						NMH[r,c]=.
					}
				}
				if (rowmissing(NMH[r,]):==0){
					NMHm=rowmin(NMH[r,])
					for (c=1; c<=cols(NMH); c++){
						PH[a,abs(NMOi1[r,c])]=PH[a,abs(NMOi1[r,c])]+NMHm*100/2
						H[a,abs(NMOi1[r,c])]=H[a,abs(NMOi1[r,c])]-sign(NMOi1[r,c])*NMHm
						if (abs(H[a,abs(NMOi1[r,c])])<0.00001){
							H[a,abs(NMOi1[r,c])]=0	
						}
					}
				}					
			}	
			sh=rowsum(abs(H[a,]))
			for (i=2; i<=dim; i++){
				if (sh>0){
					for (r=1; r<=rows(NMOi2); r++){
						for (c=1; c<=cols(NMOi2); c++){			
							if (H[a,abs(NMOi2[r,c])]==0){
								D1[abs(NMOi2[r,c]),1]=.
								D2[abs(NMOi2[r,c]),1]=.
								DS[abs(NMOi2[r,c]),1]=.
								NMOi2[r,c]=.
								NMO2[r,1]=.						
							}
						}
					}
					NMO=select(NMO2, rowmissing(NMO2):==0)
					NMOi=select(NMOi2, rowmissing(NMOi2):==0)
					COO=J(1,cols(NMO)+2,.)
					COOi=J(1,cols(NMOi)+1,.)
					for (k=1; k<=rows(NMO); k++){
						for (c=1; c<=rows(D1); c++){
							if (D1[c,1]!=. & D1[c,1]==NMO[k,cols(NMO)] & D2[c,1]!=NMO[k,cols(NMO)-1] & D2[c,1]!=NMO[k,3] & DS[c,1]==1){
								CO=(NMO[k,],D1[c,1],D2[c,1])
								COO=COO\CO
								COi=(NMOi[k,],c)
								COOi=COOi\COi
							}	
							if (D2[c,1]!=. & D2[c,1]==NMO[k,cols(NMO)] & D1[c,1]!=NMO[k,cols(NMO)-1] & D1[c,1]!=NMO[k,3] & DS[c,1]==-1){
								CO=(NMO[k,],D2[c,1],D1[c,1])
								COO=COO\CO
								COi=(NMOi[k,],-c)
								COOi=COOi\COi								
							}							
						}
					}
					COOi=(COOi,COO[,1],COO[,cols(COO)])					
					NMO=select(COO, COO[,1]:==t1)					
					NMOi=select(COOi, COOi[,cols(COOi)-1]:==t1)
					NMOi1=select(NMOi, NMOi[,cols(NMOi)]:==t2)
					NMO2=select(NMO, NMO[,cols(NMO)]:!=t2)
					NMOi2=select(NMOi, NMOi[,cols(NMOi)]:!=t2)
					NMOi1=NMOi1[,1..cols(NMOi1)-2]
					NMOi2=NMOi2[,1..cols(NMOi2)-2]	
					NMH=J(rows(NMOi1),cols(NMOi1),.)				
					for (r=1; r<=rows(NMH); r++){
						for (c=1; c<=cols(NMH); c++){
							if (sign(NMOi1[r,c])==sign(H[a,abs(NMOi1[r,c])])){
								NMH[r,c]=abs(H[a,abs(NMOi1[r,c])])							
							}
						}
					}	
					for (r=1; r<=rows(NMH); r++){
						for (c=1; c<=cols(NMH); c++){
								if (NMH[r,c]==.){
									NMOi1[r,c]=.
								}								
						}
					}					
					NMH=select(NMH, rowmissing(NMH):==0)
					NMOi1=select(NMOi1, rowmissing(NMOi1):==0)					
					NMHm=rowmin(NMH)
					NMH=(NMH,NMHm)
					NMOi1=(NMOi1,NMHm)
					NMH=sort(NMH,-cols(NMH))
					NMOi1=sort(NMOi1,-cols(NMOi1))
					NMH=NMH[,1..cols(NMH)-1]
					NMOi1=NMOi1[,1..cols(NMOi1)-1]
					for (r=1; r<=rows(NMH); r++){
						for (c=1; c<=cols(NMH); c++){
							if (sign(NMOi1[r,c])==sign(H[a,abs(NMOi1[r,c])])){
								NMH[r,c]=abs(H[a,abs(NMOi1[r,c])])
							}
							else{
								NMH[r,c]=.
							}
						}
						if (rowmissing(NMH[r,]):==0){
							NMHm=rowmin(NMH[r,])
							for (c=1; c<=cols(NMH); c++){
								PH[a,abs(NMOi1[r,c])]=PH[a,abs(NMOi1[r,c])]+NMHm*100/(i+1)
								H[a,abs(NMOi1[r,c])]=H[a,abs(NMOi1[r,c])]-sign(NMOi1[r,c])*NMHm
								if (abs(H[a,abs(NMOi1[r,c])])<0.00001){
									H[a,abs(NMOi1[r,c])]=0	
								}
							}
						}
					}	
				}
				sh=rowsum(abs(H[a,]))
			}
		}
	}
	st_matrix("_PH",PH)
}
end




