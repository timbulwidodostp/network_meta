*! version 0.10  Ian White   22aug2008

/********************************************************************* 
version 0.10    22aug2008
    varcheck rewritten to cope with Stephen K's very strange example in Stata 9
    coef, or, nohr identified as separate options to be included in replay for hard
    new pause option
    decided not to capture augmented analysis as I've never had problems
version 0.9     8aug2008
    gives error when usevars() contains variables not in xvarlist
    bug fixed when usevars() is just one variable (PP was missed)
    new esave - adds selected e() to dataset
    (similarly undocumented rsave, for Stephen K)
    nodetails also suppresses augmentation details
    noauglist suppresses listing of augmenting observations 
    ppcmd allows alternative command (e.g. plogit) as alternative to augmentation
    ppfix(all) uses augmentation/ppcmd unconditionally
    hard captures results of first model fit & augments if error
    works with blogit (but augmentation doesn't)
    remove eqnames for any command, not just clogit
    augment() renamed augwt()
    nocons included as explicit option thus getting #parms right in _augment and disabling useconstant
    new output variables _ppfixed and _ppremains 
version 0.8    17mar2008
    _getcovcorr replaced with varcheck (_getcovcorr's check option isn't in Stata 9)
version 0.7.1  18dec2007   
    much improved augmentation 
        checks for missing variables and zero variances
        early event for any st command
    zerovar, missvar dropped and replaced with error and missing value
version 0.7  11dec2007   
    bugs fixed: single covariate -> perfect prediction always detected
                uselist default wrong
    much improved augmentation 
        checks for missing variables and zero variances
        early event for any st command
    zerovar, missvar dropped and replaced with error and missing value
version 0.6  19oct2007   
    uses augmented procedure (option augment() instead of hessadd())
version 0.5  18oct2007   
    attempts to detect when Stata has used a generalised inverse for V: 
        if detected, it augments the Hessian by `hessadd'*var(X) before inverting (version 10 only)
    missing beta's are replaced by zero with variance `zerovar', covariance 0
    NOTE: OK if there are no events in any category*study,
        but fails if there are no individuals in the reference category 
        (because a new reference category is chosen)
version 0.4  24sep2007   
    enable weights
version 0.3   5jul2007   
    rename use, cons as usevars, useconstant; 
    rename outputs as bvar1, Vvar1var2 etc. not b1, V11 etc.; 
    rename singular option as zerovar and improve warning message
version 0.2  28jun2007   
    handle clogit row/colnames: e(b), e(V) labelled y:x1, y:x2 etc. instead of x1, x2 etc.;
    append option; 
    if/in bug removed

Ideas: make it a prefix command?
    would still need to use weights, strata from main command
    
PROBLEMS:
    augmentation ignores a weight that has been stset
*********************************************************************/

prog def mvmeta_make
version 9
syntax anything [if] [in] [fweight aweight pweight iweight], by(varname) SAVing(string) [replace append NAMEs(namelist min=2 max=2) keepmat USEVars(varlist) USEConstant noDETails PPFix(string) PPCmd(string) AUGwt(real 0.01) noAUGList hard STrata(passthru) esave(string) rsave(string) noCONstant coef or nohr pause *]

*********************** PARSING ***********************

gettoken regcmd varlist : anything, parse(" ")
if substr("`regcmd'",1,2)=="st" local xvarlist `varlist'
else gettoken yvar xvarlist : varlist
if "`regcmd'"=="blogit" {
    gettoken nvar xvarlist : xvarlist
    local yvar `yvar' `nvar'
}

marksample touse

if "`weight'"!="" local wtexp [`weight'`exp']

cap confirm string var `by'
if _rc==0 { // Find max string length of `by'-values, for postfile
    local maxlength 0
    qui levelsof `by'
    foreach level in `r(levels)' {
        local maxlength=max(`maxlength',length("`level'"))
    }
    local str str`maxlength'
}

if "`names'"!="" {
   tokenize "`names'"
   local y `1'
   local S `2'
}
else {
   local y y
   local S S
}

if "`keepmat'"=="keepmat" {
   local ymat `y'
   local Smat `S'
}
else {
   tempname ymat Smat
}

if "`details'"=="nodetails" local qui qui
tempname onevalue post

if "`hard'"=="hard" local hardcap capture

if "`ppfix'"=="" local ppfix check
if "`ppfix'"!="none" & "`ppfix'"!="check" & "`ppfix'"!="all" {
    di as error "Please specify ppfix(none|check|all)"
    exit 198
}
if "`ppcmd'"!="" {
    gettoken ppcmd1 ppcmd2 : ppcmd, parse(",")
    local ppcmd2=substr("`ppcmd2'",2,.)
}
if "`ppcmd'"=="" & `augwt'<=0 {
    local ppfix none
}

if "`append'"=="append" & "`replace'"=="replace" {
    di as error "Can't have append and replace"
    exit 198
}

local eformopts `coef' `or' `hr'

*********************** SORT OUT USEVARS ***********************

if "`usevars'"=="" {
   local usevars `xvarlist'
}
* check `usevars' are within `xvarlist'
foreach usevar of varlist `usevars' {
    local ok 0
    foreach xvar of varlist `xvarlist' {
        if "`usevar'"=="`xvar'" local ok 1
    }
    if `ok'==0 {
        di as error "`usevar' found in usevars() but not in xvarlist"
        exit 498
    }
}
* check for duplicates in `usevars' and assign `var`i'' locals
local p 0
foreach var of varlist `usevars' {
   local bad 0
   forvalues i=1/`p' { 
      if "`var'"=="`var`i''" local bad 1
   }
   if `bad'==0 {
      local ++p
      local var`p' `var'
      local usevars2 `usevars2' `var'
   }
}

if "`useconstant'" == "useconstant" {
    cap assert "`constant'"!="noconstant"
    if _rc {
        di as error "Can't have both useconstant and noconstant options"
        exit 198
    }
    local ++p
    local var`p' _cons
    local usevars2 `usevars2' _cons
}
di as text "Using coefficients: `usevars2'"

*********************** SET UP POSTFILE ***********************

forvalues j = 1 / `p' {
   local bvars `bvars' `y'`var`j''
   forvalues k = `j' / `p' {
      local Svars `Svars' `S'`var`j''`var`k''
   }
}
foreach e in `esave' {
    local evars `evars' _e_`e'
}
foreach r in `rsave' {
    local rvars `rvars' _r_`r'
}
if "`append'"=="append" {
    cap confirm file `saving'
    if _rc confirm file `saving'.dta
    tempfile postfile
}
else local postfile `saving'
postfile `post' `str' `by' `bvars' `Svars' `evars' `rvars' _ppfixed _ppremains using `postfile', `replace'

*********************** ANALYSIS ***********************

local i 0
qui levelsof `by' if `touse'
foreach level in `r(levels)' {
    if "`str'"!="" local level `""`level'""'
    `qui' di _newline(3)
    di as text `"-> `by'==`level'"'
    local ++i
    local pptofix 0
    local fix fix
    forvalues pass=0/1 {
        local ppfound 0
        if "`ppfix'"=="all" {
            * always adjust for perfect prediction: bypass initial model fit
            local fix avoid
            local pptofix 1
        }
        *  DO THE MAIN REGRESSION
        local regrc 0
        if `pptofix'==0 {                 // WITHOUT FIXING PP
            `hardcap' `qui' `anything' if `by'==`level' & `touse' `wtexp', `strata' `constant' `eformopts' `options'
            if "`hard'"=="hard" {
                local regrc = _rc
                if `regrc' {
                    di as error "`regcmd' has returned error code `regrc': this may indicate perfect prediction"
                    local ppfound 1
                }
                else if "`details'"!="nodetails" {
                    cap `regcmd', `eformopts' `options'
                    if !_rc `regcmd', `eformopts' `options'
                    else {
                        cap `regcmd', `eformopts'
                        if !_rc `regcmd', `eformopts'
                        else {
                            cap `regcmd'
                            if !_rc `regcmd'
                            else di "Can't redisplay `regcmd' results"
                        }
                    }
                }
            }
        }
        else if `pptofix'==1 {            // WITH FIXING PP
            if "`ppcmd'"!="" {
                di as error "Attempting to `fix' perfect prediction by using `ppcmd'"
               `qui' `ppcmd1' `yvar' `xvarlist' if `by'==`level' & `touse' `wtexp', `strata' `constant' `eformopts' `options' `ppcmd2'
            }
            else {
                if "`regcmd'"=="cox" | substr("`regcmd'",1,2)=="st" local st st
                di as error "Attempting to `fix' perfect prediction by augmenting with `augwt' observations per parameter" 
                if "`st'"=="st" di as error "   (counting baseline hazard as 1 parameter)"
                tempvar wtvar augvar
                local list = cond("`auglist'"!="noauglist","list","")
                `qui' _augment `varlist' if `by'==`level' & `touse' `wtexp', `list' `st' timesweight(`augwt') wtvar(`wtvar') augvar(`augvar') `strata' `constant'
                if "`st'"=="st" {
                    qui stset _t _d if _st [iw=`wtvar'], time0(_t0)
                    local wtexp2
                }
                else local wtexp2 [iw=`wtvar']
                `qui' di as text _newline "Analysis after augmentation:"
                `qui' `anything' if (`by'==`level' & `touse')|`augvar' `wtexp2', `strata' `constant' `eformopts' `options'
                qui drop if `augvar'
                drop `augvar' `wtvar'
                if "`st'"=="st" qui stset _t _d if _st, time0(_t0)
            }
        }
        if `regrc'==0 {
            mat `ymat'`i'=e(b)
            mat `Smat'`i'=e(V)
            * remove any eqnames (e.g. clogit, plogit) 
            mat coleq `ymat'`i' = :
            mat coleq `Smat'`i' = :
            mat roweq `Smat'`i' = :
         
            *  CHECK FOR PERFECT PREDICTION:
            cap varcheck `Smat'`i', check(pd)
            if _rc {
                `qui' di 
                di as error `"Warning: perfect prediction or inestimable parameter"' 
                di as error `"   (V matrix is not positive definite)"'
                `qui' mat l `Smat'`i', title(V)
                local ppfound 1
            }
            else {
               local missing 0
               forvalues j = 1 / `p' {
                  cap mat `onevalue' = `ymat'`i'[1,"`var`j''"]
                  if _rc local missing 1
               }
               if `missing' {
                   `qui' di 
                   di as error `"Warning: perfect prediction or inestimable parameter"' 
                   di as error `"   (one or more parameters have been dropped)"' 
                   local ppfound 1
               }
            }
        }
        
        * OPTIONALLY PREPARE FOR 2ND PASS
        if "`regcmd'"=="blogit" & `ppfound' & "`ppcmd'"=="" {
            di as error "Sorry, augmentation is not available with blogit as it doesn't allow weights"
            continue, break
        }
        if "`ppfix'"=="all" | `pass'==1 {
            if `ppfound' di as error "Perfect prediction has not been `fix'ed"
            else di as text "Perfect prediction has been `fix'ed"
        }
        if "`ppfix'"=="none" & `ppfound'==1 di as error "Warning: Perfect prediction fixing disabled"
        if "`ppfix'"=="all" | "`ppfix'"=="none" | `ppfound'==0 continue, break
        if `pass'==0 local pptofix `ppfound'
    }

    * POST THE RESULTS:   
    local blist
    local Slist
    forvalues j = 1 / `p' {
       cap mat `onevalue' = `ymat'`i'[1,"`var`j''"]
       if _rc {
         di as error `"Warning: missing `y'`var`j''"'
         local bvalue .
       }
       else {
          local bvalue = `onevalue'[1,1]
       }
       local blist `blist' (`bvalue')
       forvalues k = `j' / `p' {
          cap mat `onevalue' = `Smat'`i'["`var`j''","`var`k''"]
          if _rc {
             di as error `"Warning: missing `S'`var`j''`var`k''"'
             local Svalue .
          }
          else {
             local Svalue = `onevalue'[1,1]
          }
          if `j'==`k' & `Svalue' == 0 {
             di as error `"Warning: missing `S'`var`j''`var`k''"'
             local Svalue .
          }
          local Slist `Slist' (`Svalue')
       }
    }
    local elist
    foreach e in `esave' {
        local elist `elist' (e(`e'))
    }
    local rlist
    foreach r in `rsave' {
        local rlist `rlist' (r(`r'))
    }
    post `post' (`level') `blist' `Slist' `elist' `rlist' (`pptofix') (`ppfound') 
    `pause'
}
postclose `post'

preserve
use `saving', clear
if "`append'"=="append" append using `postfile'
label var _ppfixed "Perfect prediction fixed?"
label var _ppremains "Perfect prediction remains in this result?"
save `saving', replace

end

******************************************************************************************

program define _augment
version 9
syntax varlist [if] [in] [fweight aweight pweight iweight], [TOTALweight(real 0) TIMESweight(real 0) noPREServe list wtvar(string) augvar(string) noequal st strata(varlist) noconstant]

if "`wtvar'"=="" local wtvar _weight
if "`augvar'"=="" local augvar _augment
confirm new var `wtvar' `augvar'

tempvar augment wt
if "`weight'"!="" gen `wt' `exp'
else gen `wt' = 1

marksample touse

// Sort out some locals
if "`st'"=="" {
    gettoken y xlist: varlist
    qui levelsof `y' if `touse', local(ylevels)
    qui tab `y' if `touse' [iw=`wt']
    local nylevels = r(r)
    local totw = r(N)
}
else {
    st_is 2 analysis
    qui replace `touse'=0 if _st==0
    local xlist `varlist'
    local y _t
    local nylevels 2
    summ `wt' if _st & `touse', meanonly
    local totw = r(sum)
    local stvars _t _d
    summ _t if _st & `touse', meanonly
    local tmin = r(min)/2
    local tmax = r(max)+r(min)/2
    local ylevels `tmin' `tmax'
}
local Nold = _N

// Count x's
local nx = wordcount("`xlist'")

// Set total weight of added observations
if `totalweight'>0 & `timesweight'>0 {
    di as error "Can't specify totalweight() and timesweight()"
    exit 498
}
if `totalweight' == 0 local totalweight = `nx' + ("`constant'"!="noconstant")
if `timesweight'>0 local totalweight = `totalweight' * `timesweight'

// Number of added observations
local Nadd = `nx'*2*`nylevels'
local Nnew = `Nold'+`Nadd'
di as text "Adding " as result `Nadd' as text " pseudo-observations "_c
if "`strata'"!="" di as text "per stratum " _c
di as text "with total weight " as result `totalweight'

qui {
   set obs `Nnew'
   gen `augment' = _n>`Nold'
   local thisobs `Nold'
   foreach x of var `xlist' {
      sum `x' [iw=`wt'] if `touse' & !`augment'
      local mean = r(mean)
      local sd = r(sd)*sqrt((r(N)-1)/r(N))
      if r(sd)==0 {
         * No variation in this cohort: use SD across all cohorts
         sum `x' [iw=`wt'] if !`augment'
         local mean = r(mean)
         local sd = r(sd)*sqrt((r(N)-1)/r(N))
      }
      replace `x' = `mean' if `augment'
      foreach yval in `ylevels' {
         if "`equal'"=="noequal" {
            summ `wt' if `y'==`yval' & `touse' & !`augment', meanonly
            local py = r(sum)/`totw'
         }
         else local py = 1/`nylevels'
         foreach xnewstd in -1 1 {
            local ++thisobs
            replace `x' = `mean'+(`xnewstd')*`sd' in `thisobs'
            replace `y' = `yval' in `thisobs'
            replace `wt'= `totalweight' * `py' / (2*`nx') in `thisobs'
         }
      }
   }
   if "`st'"=="st" {
      replace _d=1 if `y'==`tmin' & `augment'
      replace _d=0 if `y'==`tmax' & `augment'
      replace _t0=0 if `augment'
      replace _st=1 if `augment'
   }
}

// Handle strata
if "`strata'"!="" {
    qui {
       foreach stratvar of varlist `strata' {
           levelsof `stratvar' if `touse' & !`augment', local(stratlevels)
           local nlevels = wordcount(`"`stratlevels'"')
           forvalues i=2/`nlevels' {
               local Noldplus1=_N+1
               expand 2 if `augment' & missing(`stratvar')
               local thislevel = word(`"`stratlevels'"',`i')
               replace `stratvar'=`thislevel' in `Noldplus1'/l
           }
           local thislevel = word(`"`stratlevels'"',1)
           replace `stratvar'=`thislevel' if `augment' & missing(`stratvar')
           replace `wt'=`wt'/`nlevels' if `augment' 
       }
    }
}

rename `wt' `wtvar'
rename `augment' `augvar'

if "`list'"=="list" {
    di as txt _newline "Listing of added records:"
    char `wtvar'[varname] weight
    label var `wtvar' "Weight"
    char `augvar'[varname] augment
    label var `augvar' "Augmented?"
    list `stvars' `strata' `varlist' `wtvar' if `augvar', sep(4) subvarname
}

end


prog def varcheck
syntax anything, [check(string)]
local dim = rowsof(`anything')
if colsof(`anything') != `dim' {
    di as error "`anything' is not a square matrix"
    exit 498
}
* Check for missing values, adapted to cope with the following special case
* In Stata 9, I have come across a matrix M of values 1.#QNAN that returns matmissing(M)=0 but matmissing(M+M)=1
tempname anything1
mat `anything1'=`anything'+`anything'
if matmissing(`anything1') {
    di as error "`anything' has missing values"
    exit 498
}
if `dim' == 1 {
    * 1x1 matrix
    local mineigen = `anything'[1,1]
}
else {
    * larger matrix
    forvalues r=1/`dim' {
        if `anything'[`r',`r']<=0 exit 498 
            // Variance not positive
        forvalues s=1/`dim' {
            if (`anything'[`r',`s'])^2>`anything'[`r',`r']*`anything'[`s',`s'] exit 498 
                // Correlation outside [-1,1]
        }
    }
    if "`check'"!="" {
       tempname evecs evals
       mat symeigen `evecs' `evals' = `anything'
       local mineigen = `evals'[1,`dim']
    }
}
if "`check'"=="psd" {
    if `mineigen'<0 {
        di as error "`anything' is not positive semi-definite"
        exit 506
    }
}
else if "`check'"=="pd" {
    if `mineigen'<=0 {
        di as error "`anything' is not positive definite"
        exit 506
    }
}
end
