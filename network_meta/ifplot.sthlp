{smcl}

{p}{helpb network_graphs: Return to main help page for the network graphs package}

{hline}
help for {hi:ifplot} command
{hline}

{title:Title}

{p 4 4 2}
Evaluation of statistical inconsistency in networks of interventions


{title:Description}

{p 4 4 1}
Consistency is a key assumption for network meta-analysis, which implies that in a closed loop formed by three or more treatments direct and indirect estimates do not differ substantially.
The presence of important inconsistency in one or more loops of a network of interventions threatens the validity of network meta-analysis results {help network_graphs##Caldwell2005:(Caldwell, 2005)},
{help network_graphs##Salanti2012:(Salanti, 2012)}.

{p 4 4 1}
The 'loop-specific approach' evaluates inconsistency separately in every closed loop of a network of interventions {help network_graphs##Bucher1997:(Bucher, 1997)}.
More specifically, in a network with {it:L} total number of loops the inconsistency factor (IF) within each loop {it:l} ({it:l=1,...,L}) is estimated as the difference between the direct and indirect estimate
for one of the comparisons in the this particular loop.
Loops in which the lower CI limit of the inconsistency factor does not reach the zero line are considered to present statistically significant inconsistency.
However, the absence of statistically significant inconsistency is not evidence against the presence of inconsistency due the multiple and correlated tests that are undertaken and the low power of the method
{help network_graphs##Veroniki2014:(Veroniki, 2014)}.

{p 4 4 1}
The {cmd:ifplot} command identifies all triangular and quadratic loops in a network of interventions and estimates the respective inconsistency factors and their uncertainty.
Then, it produces the inconsistency plot that presents for each loop the estimated inconsistency factor and its confidence interval (truncated to zero).
The command allows for different assumptions for the between-studies variance (i.e. loop-specific, comparison-specific or network-specific) and different estimators (e.g. method of moments, restricted maximum likelihood, etc.).


{title:Syntax}

{p 8 17 2}
{cmd:ifplot} 
{it:varlist}
[{cmd:if} {it:exp}]
[{cmd:in} {it:range}]
[{cmd:,} 
{cmdab:tau:2(}{it:comparison|loop|#}{cmd:)}
{cmd:mm}
{cmd:reml}
{cmd:eb}
{cmd:random}
{cmd:fixed}
{cmdab:cil:evel(}{it:integer}{cmd:)}
{cmdab:sum:mary}
{cmdab:det:ails}
{cmdab:lab:els(}{it:string}{cmd:)}
{cmdab:notab:le}
{cmdab:plotopt:ions(}{it:string}{cmd:)}
{cmdab:xlab:el(}{it:#,#,...,#}{cmd:)}
{cmdab:nopl:ot}
{cmdab:sep:arate}
{cmd:eform}
{cmd:keep}]

{p 4 4 2}

{p 4 4 1}
The ifplot command requires in {it:varlist} to specify the following variables:

{pstd}{it:ES} the effect sizes for every treatment comparison defined in the dataset (for ratio measures such as odds ratio, risk ratio, hazard ratio, etc. the effect sizes in {it:ES} should be in logarithmic scale; e.g. log-odds ratio, log-risk ratio){p_end} 

{phang}{it:se} the standard errors of the effect sizes in {it:ES}{p_end} 
{phang}{it:t1} and  {it:t2} (numeric or string) the codes of the two treatments compared in each observation{p_end}

{phang}{it:id} the variable specifying the ID numbers of the studies, with repetitions for multi-arm studies. Each k-arm trial contributes (k x(k-1))/2 rows to the dataset.{p_end} 

{phang}{ul:Important note:} The ifplot command only reads datasets that have been prepared with {helpb network setup} or {helpb network import} in the pairs format{p_end}

{title:Options}

{dlgtab:Estimation of Heterogeneity}

{phang}
{cmdab:tau:2(}{it:comparison|loop|#}{cmd:)} specifies the assumption for the heterogeneity variance: 
	{it:'loop'} a common heterogeneity for all comparisons within each loop but different heterogeneities across loops {bf:(the default)},
	{it:'comparison'} different comparison-specific heterogeneities for each loop,
	{it:{it:'#'}} a real non-negative number for the network-specific heterogeneity variance common for all loops and comparisons

{phang}
{cmd:mm} specifies the method of moments (the default) (see {helpb metareg}) for the estimation of the loop-specific heterogeneity (when {it:tau2(loop)} has been specified).
This is the only possible method for estimating heterogeneity when {it:tau2(comparison)} has been specified.

{phang}
{cmd:reml} specifies that the restricted maximum likelihood method (see {helpb metareg}) for the estimation of the loop-specific heterogeneity (when {it:tau2(loop)} has been specified).

{phang}
{cmd:eb} specifies that the "Empirical Bayes" method (see {helpb metareg}) is used for the estimation of the loop-specific heterogeneity (when {it:tau2(loop)} has been specified)..
	
{phang}
{cmd:random} specifies that the random effects model is used for all comparisons (the default) (when {it:tau2(comparison)} has been specified).
This is the only possible model when {it:tau2(loop)} or {it:tau2(#)} has been specified.
	
{phang}
{cmd:fixed} specifies that the fixed effect model is used for all comparisons (when {it:tau2(comparison)} has been specified); that is equal to {it:tau2(0)}.
	
{dlgtab:Output Results and Inconsistency Plot}

{phang}
{cmdab:cil:evel(}{it:integer}{cmd:)} specifies the level of statistical significance for the inconsistency factors' confidence intervals.

{phang}
{cmdab:sum:mary} specifies the display of all direct and indirect summary estimates for every loop. 

{phang}
{cmdab:det:ails} specifies the display of all comparisons that are dropped when there are multi-arm studies in a loop. 

{phang}
{cmdab:lab:els(}{it:string}{cmd:)} specifies names for competing treatments in the network, which are displayed in the inconsistency plot.
The treatments should be given in numerical or alphabetical order separated by space. 
	
{phang}	
{cmdab:notab:le} skips the display of the output results.	

{phang}
{cmdab:plotopt:ions(}{it:string}{cmd:)} specifies standard options of {helpb metan} handling the appearence of the inconsistency plot.
	
{phang}	
{cmdab:xlab:el(}{it:#,#,...,#}{cmd:)} specifies the values that are displayed on the horizontal axis. The input values need to be comma delimited.

{phang}
{cmdab:nopl:ot} skips the display of the inconsistency plot.

{phang}
{cmdab:sep:arate} specifies that inconsistency factors are displayed separately for loops with and without evidence of statistical inconsistency in the inconsistency plot and the output results.

{phang}
{cmd:eform} specifies that the results are displayed on the exponential scale.

{phang}
{cmd:keep} specifies that the results are stored as additional variables in end of the dataset.


{title:Examples}

{phang}{cmd:. ifplot logor selogor treat1 treat2 study, tau2(comparison) random}

{phang}{cmd:. ifplot logrr selogrr treat1 treat2 study, tau2(loop) reml lab(Placebo Aspirin Dipyridamole)}

{phang}{cmd:. ifplot logor selogor treat1 treat2 study, tau2(0.2) summary details}

{phang}{cmd:. ifplot logor selogor treat1 treat2 study, notable plotopt(nobox classic texts(150))}

{phang}{cmd:. ifplot SMD seSMD treat1 treat2 study, keep separate xlab(1,2,3)}


{title:Multi-arm trials}

{p 0 0 0}
The 'loop-specific approach' does not account for the correlation in the effect sizes induced by multi-arm trials.
This is expected to emphasize the consistency in the loops as ifplot treats as independent the comparisons from the same trial which are by definition consistent.
The ifplot command slightly mitigates this by dropping one of the direct comparison from the multi-arm trials when it appears in a particular loop.
Among the (k x(k-1))/2 comparisons belonging to the same trial that can be excluded from a loop, the ifplot chooses the comparisons with the largest number of studies within the loop.
Inconsistency is not identifiable in loops formed only by multi-arm trials and hence such loops are excluded. 

{phang} 

{p}{helpb network_graphs: Return to main help page for the network graphs package}

{phang}  
