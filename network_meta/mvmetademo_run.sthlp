{smcl}
{* *! version 3.0.1  27may2015}{...}
{viewerjumpto "Berkey data" "mvmetademo##Berkey"}{...}
{viewerjumpto "p53 data" "mvmetademo##p53"}{...}
{viewerjumpto "FSC data 1" "mvmetademo##FSCfpama"}{...}
{viewerjumpto "FSC data 2" "mvmetademo##FSCshape"}{...}
{viewerjumpto "References" "mvmetademo##refs"}{...}
{title:Title}

{phang}{hi:mvmeta} {hline 2} A demonstration


{title:Berkey data}{marker Berkey}

{pstd}Data from
{help mvmetademo##Berkeyetal98:Berkey et al. (1998)}: treatment effects on
two outcomes (probing depth, {cmd:y1}; attachment level, {cmd:y2}) in
periodontal disease.  The within-trial variances and covariances were reported
by the authors.

{phang2}. {bf:{stata use berkey, clear}}

{phang2}. {bf:{stata list, noobs separator(0)}}

{pstd}Now, we will draw a bubble plot of the data.  This requires converting
the variances to standard errors and computing the correlation:

{phang2}. {bf:{stata generate s1=sqrt(V11)}}

{phang2}. {bf:{stata generate s2=sqrt(V22)}}

{phang2}. {bf:{stata generate r12=V12/sqrt(V11*V22)}}

{pstd}We fit a bivariate meta-analysis and draw the bubble plot by adding the
{cmd:bubble} option to {cmd:mvmeta}:

{phang2}. {bf:{stata mvmeta y V, bubble}}

{pstd}The {cmd:y1} results are very similar to those from univariate
meta-analysis:

{phang2}. {bf:{stata mvmeta y V, var(y1)}}

{pstd}We compare the univariate {cmd:mvmeta} results with those from
{cmd:metan}.

{phang2}. {bf:{stata metan y1 s1}}

{pstd}These differ because by default
1) {cmd:mvmeta} fits the random-effects model,
whereas {cmd:metan} fits the fixed-effects model;
2) {cmd:mvmeta} uses REML, 
whereas {cmd:metan} uses the method of moments; and
3) {cmd:mvmeta}'s standard error allows for uncertainty in estimating tau.
To get exact agreement, we type 

{phang2}. {bf:{stata metan y1 s1, random}}

{phang2}. {bf:{stata mvmeta y V, var(y1) mm nouncertainv print(bscov)}}

{pstd}Let's return to the bivariate setting and 
explore a meta-regression on year of publication.

{phang2}. {bf:{stata mvmeta y V pubyear}}

{pstd}There is no evidence that either outcome is associated with year of
publication.


{title:p53 data}{marker p53}

{pstd}Six observational studies in patients with squamous cell carcinoma of
the oropharynx.  Possible prognostic factor: the presence of mutant p53 tumor
suppressor gene
{help mvmetademo##Jackson++11:(Jackson, Riley, and White 2011)}.

{pstd}Data are estimated log hazard-ratios (lnHR) for mutant versus normal p53
gene for two outcomes, and overall survival (OS) and disease-free survival
(DFS), together with their variances.

{phang2}. {bf:{stata use p53, clear}}

{phang2}. {bf:{stata list, noobs separator(0) abbreviate(12)}}

{pstd}Note that the OS results in studies without DFS results are much larger
than those in studies with DFS results.  This suggests that the multivariate
result for DFS may be substantially larger than the univariate result but
also suggests that we should be cautious of both results.

{pstd}Let's fit the univariate meta-analysis for DFS:

{phang2}. {bf:{stata mvmeta lnHR VlnHR, var(lnHRdfs)}}

{pstd}Let's compare this with the multivariate meta-analysis.  The data do not
include the within-study correlations, so we assume they are all 0.7.

{phang2}. {bf:{stata mvmeta lnHR VlnHR, wscorr(0.7)}}

{pstd}Yes, the multivariate result for DFS is larger (lnHRdfs is less
negative) than the univariate result. It also has a larger between-studies
variance and hence a larger standard error.

{pstd}Various postestimation options can be specified with {cmd:mvmeta}
results without refitting the model.  The {cmd:i2} option estimates a
multivariate I-squared, together with its confidence interval.  It also gives
a confidence interval for the between-studies correlation:

{phang2}. {bf:{stata mvmeta, i2}}

{pstd}The {cmd:eform} option shows the exponentiated coefficients (here, hazard
ratios):

{phang2}. {bf:{stata mvmeta, eform}}

{pstd}We can also see the full parameterization of the model, including the
Cholesky decomposition of the variance terms that are usually hidden:

{phang2}. {bf:{stata mvmeta, showall}}

{pstd}Other postestimation options include {opt t(#)} to specify
a t distribution for inference.

{pstd}Above we assumed the unknown within-study correlations were all 0.7.
We can avoid this assumption by using Riley's alternative model
{help mvmetademo##Riley++08:(Riley, Thompson, and Abrams 2008)}.  Usually,
this converges quickly, but on this occasion, it needs more than 400
iterations:

{phang2}. {bf:{stata mvmeta lnHR VlnHR, wscorr(riley)}}


{title:Fibrinogen Studies Collaboration 1:}{marker FSCfpama}
{title:Fully and partly adjusted associations}

{pstd}The original data are from 31 studies relating plasma levels of
fibrinogen, a blood-clotting factor, to time to a coronary-heart-disease (CHD)
event {help mvmetademo##FSC2005:(Fibrinogen Studies Collaboration 2005)}.  In
this example, we assume a linear association between fibrinogen and CHD, and
we wish to adjust for confounding. Some confounders are recorded in all
studies, while others are recorded in only 14 studies.  We therefore estimate
a partly adjusted coefficient (log hazard-ratio) in all 31 studies and a
fully adjusted coefficient in the 14 studies.  We also estimate their
(within-studies) correlation: in the article, we considered three methods, but
here we will use the bootstrap method
{help mvmetademo##FSC2009:(Fibrinogen Studies Collaboration 2009)}.

{phang2}. {bf:{stata use FSCfpama, clear}}

{phang2}. {bf:{stata list, noobs}}

{pstd}To run {cmd:mvmeta}, we need to construct the variance-covariance
matrices:

{phang2}. {bf:{stata generate varfafa = sefa^2}}

{phang2}. {bf:{stata generate varpapa = sepa^2}}

{phang2}. {bf:{stata generate varfapa = corrb*sefa*sepa}}

{pstd}The "standard" approach would be to analyze only the fully adjusted
estimates:

{phang2}. {bf:{stata mvmeta beta var, var(betafa)}}

{pstd}Our new approach analyzes the fully adjusted estimates jointly with the
partly adjusted estimates to gain precision:

{phang2}. {bf:{stata mvmeta beta var}}

{pstd}The standard error for {cmd:betafa} has decreased from 0.0389 to 0.0266
or 32%.  This represents a 53% decrease in variance.  Note the between-studies
correlation is estimated as 1, so that the model can infer fully
adjusted estimates quite precisely from partly adjusted estimates.

{pstd}The {cmd:wt} option estimates the borrowing of strength -- the degree
to which results for one outcome gain precision by the inclusion of the other
outcome(s) in the analysis.

{phang2}. {bf:{stata mvmeta, wt}}

{pstd}This shows a 53% borrowing of strength.  The results also show the
relative contributions of the studies to the fully adjusted result: study 12
makes the largest contribution, but, for example, study 28 (only partly
adjusted) contributes more than study 1 (fully adjusted).  This is because
study 28 is much more precise:

{phang2}. {bf:{stata list if inlist(cohort,1,14,28)}}


{title:Fibrinogen Studies Collaboration 2:}{marker FSCshape}
{title:Shape of exposure-outcome relationship}

{pstd}We now use the same original data to explore the shape of association
between fibrinogen and CHD, adjusting for complete confounders.  Each study
has been analyzed using a Cox model including fibrinogen categorized into five 
groups and adjusting for confounders.  The "outcomes" of interest are
therefore the 4 contrasts (log hazard-ratios) of groups 2-5 with group 1.
Some studies (for examples, study 15) have no participants or no events in
group 1: these have been handled by introducing ("augmenting") a very small
amount of data in group 1.  {cmd:mvmeta_make} has been used to automate the
augmentation, fitting of the Cox models, and extraction of the point estimates,
variances, and covariances {help mvmetademo##White09:(White 2009)}.

{phang2}. {bf:{stata use FSCstage1, clear}}

{phang2}. {bf:{stata browse}}

{phang2}. {bf:{stata mvmeta b V}}

{phang2}. {bf:{stata estimates store FSC2full}}

{pstd}That was a little slow.  We will demonstrate some faster alternatives.
First, and probably best, we will use the method of moments. The original
version is by
{help mvmetademo##Jackson++10:Jackson, White, and Thompson (2010)}:

{phang2}. {bf:{stata mvmeta b V, mm}}

{pstd}Second, we will use a matrix-based method of moments by
{help mvmetademo##Jackson++13:Jackson, White, and Riley (2013)}:

{phang2}. {bf:{stata mvmeta b V, mm2}}

{pstd}Third, we will use the fixed-effects method (not recommended because it
ignores heterogeneity):

{phang2}. {bf:{stata mvmeta b V, fixed}}

{pstd}We could also assume that the between-studies variation is captured by a
random slope:

{phang2}. {bf:{stata matrix B = (1,2,3,4)'*(1,2,3,4)}}

{phang2}. {bf:{stata mvmeta b V, bscov(prop B)}}

{phang2}. {bf:{stata lrtest FSC2full}}

{pstd}Not significantly worse, but I would prefer to use the full model:

{phang2}. {bf:{stata estimates replay FSC2full}}


{title:References}{marker refs}

{phang}{marker Berkeyetal98}
Berkey, C. S., D. C. Hoaglin, A. Antczak-Bouckoms, F. Mosteller, and
G. A. Colditz. 1998. 
Meta-analysis of multiple outcomes by regression with random effects. 
{it:Statistics in Medicine} 17: 2537-2550.

{phang}{marker FSC2005}
Fibrinogen Studies Collaboration. 2005.
Plasma fibrinogen level and the risk of major cardiovascular diseases and
nonvascular mortality: An individual participant meta-analysis.
{it:Journal of the American Medical Association} 294: 1799-1809.

{phang}{marker FSC2009}
Fibrinogen Studies Collaboration. 2009. 
Systematically missing confounders in individual participant data
meta-analysis of observational cohort studies. 
{it:Statistics in Medicine} 28: 1218-1237. 

{phang}{marker Jackson++10}
Jackson, D., I. R. White, and S. G. Thompson. 2010. 
Extending DerSimonian and Laird's methodology to perform multivariate random
effects meta-analyses. 
{it:Statistics in Medicine} 29: 1282-1297.

{phang}{marker Jackson++11}
Jackson, D., R. Riley, and I. R. White. 2011. 
Multivariate meta-analysis: Potential and promise.
{it:Statistics in Medicine} 30: 2481-2498.

{phang}{marker Jackson++13}
Jackson, D., I. R. White, and R. D. Riley. 2013. 
A matrix-based method of moments for fitting the multivariate random effects
model for meta-analysis and meta-regression. 
{it:Biometrical Journal} 55: 231-245.

{phang}{marker Riley++08}
Riley, R. D., J. R. Thompson, and K. R. Abrams. 2008.
An alternative model for bivariate random-effects meta-analysis when the
within-study correlations are unknown. {it:Biostatistics} 9: 172-186.

{phang}{marker White09}
White, I. R. 2009. 
{browse "http://www.stata-journal.com/article.html?article=st0156":Multivariate random-effects meta-analysis}.
{it:Stata Journal} 9: 40-56.
{p_end}
